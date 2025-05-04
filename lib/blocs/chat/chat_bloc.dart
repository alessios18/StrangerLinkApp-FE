// lib/blocs/chat/chat_bloc.dart
import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stranger_link_app/models/conversation.dart';
import 'package:stranger_link_app/models/message.dart';
import 'package:stranger_link_app/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final Map<int, bool> _typingUsers = {};
  final Map<int, bool> _onlineUsers = {};

  // Subscription for WebSocket events
  StreamSubscription? _webSocketSubscription;


  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    // Connect to WebSocket and set up event handlers
    _setupWebSocketListeners();

    // Events handlers
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<SetTypingStatus>(_onSetTypingStatus);
    on<MessageReceived>(_onMessageReceived);
    on<MessageStatusChanged>(_onMessageStatusChanged);
    on<UserStatusChanged>(_onUserStatusChanged);
    on<ConnectionStatusChanged>(_onConnectionStatusChanged);
  }

  void _setupWebSocketListeners() {
    // Set up WebSocket callbacks for real-time events
    chatRepository.onMessageReceived = (message) {
      add(MessageReceived(message));
    };

    chatRepository.onMessageStatusChanged = (message) {
      add(MessageStatusChanged(message));
    };

    chatRepository.onUserStatusChanged = (userId, isOnline) {
      add(UserStatusChanged(userId, isOnline));
    };

    chatRepository.onConnectionChanged = () {
      add(ConnectionStatusChanged());
    };
  }

  @override
  Future<void> close() {
    _webSocketSubscription?.cancel();
    chatRepository.disconnect();
    return super.close();
  }

  Future<void> _onLoadConversations(
      LoadConversations event,
      Emitter<ChatState> emit,
      ) async {
    // If we already have conversations, show them while loading new ones
    final currentState = state;
    List<Conversation> existingConversations;

    if (currentState is ChatConversationsLoaded) {
      existingConversations = currentState.conversations;
    } else if (currentState is ChatLoading) {
      existingConversations = currentState.conversations;
    } else {
      existingConversations = [];
    }

    if (existingConversations.isNotEmpty) {
      emit(ChatLoading(conversations: List<Conversation>.from(existingConversations)));
    } else {
      emit(ChatLoading());
    }

    try {
      final conversations = await chatRepository.getConversations();
      emit(ChatConversationsLoaded(conversations));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onLoadMessages(
      LoadMessages event,
      Emitter<ChatState> emit,
      ) async {
    // If we already have messages, show them while loading new ones
    final currentState = state;
    final existingMessages = currentState is ChatMessagesLoaded &&
        currentState.conversationId == event.conversationId
        ? currentState.messages
        : [];

    if (existingMessages.isNotEmpty) {
      emit(ChatLoading(messages: List<Message>.from(existingMessages)));
    } else {
      emit(ChatLoading());
    }

    try {
      final messages = await chatRepository.getMessages(event.conversationId);

      // Get typing and online status
      final isTyping = _typingUsers[event.conversationId] ?? false;
      final isOnline = _onlineUsers[event.otherUserId] ?? false;

      emit(ChatMessagesLoaded(
        conversationId: event.conversationId,
        otherUserId: event.otherUserId,
        messages: messages,
        hasMoreMessages: messages.length >= 20, // Assuming page size is 20
        isOtherUserTyping: isTyping,
        isOtherUserOnline: isOnline,
        scrollToBottom: true,
      ));

      // Mark messages as read
      add(MarkMessagesAsRead(event.conversationId));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onLoadMoreMessages(
      LoadMoreMessages event,
      Emitter<ChatState> emit,
      ) async {
    final currentState = state;
    if (currentState is ChatMessagesLoaded) {
      try {
        final page = (currentState.messages.length / 20).floor(); // Assuming page size is 20
        final olderMessages = await chatRepository.getMessages(
          event.conversationId,
          page: page + 1, // Get next page
        );

        if (olderMessages.isNotEmpty) {
          // Combine with existing messages
          final allMessages = List<Message>.from(currentState.messages)
            ..addAll(olderMessages);

          // Remove duplicates and sort by timestamp (newest first)
          final uniqueMessages = _removeDuplicateMessages(allMessages);

          emit(ChatMessagesLoaded(
            conversationId: currentState.conversationId,
            otherUserId: currentState.otherUserId,
            messages: uniqueMessages,
            hasMoreMessages: olderMessages.length >= 20, // If we got a full page, there might be more
            isOtherUserTyping: currentState.isOtherUserTyping,
            isOtherUserOnline: currentState.isOtherUserOnline,
            scrollToBottom: false, // Don't scroll to bottom when loading older messages
          ));
        } else {
          // No more messages
          emit(currentState.copyWith(hasMoreMessages: false));
        }
      } catch (e) {
        // Just show error message but keep current messages
        emit(ChatError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onSendTextMessage(
      SendTextMessage event,
      Emitter<ChatState> emit,
      ) async {
    final currentState = state;
    if (currentState is ChatMessagesLoaded) {
      try {
        // Add message to UI immediately with temporary ID
        final optimisticMessage = event.message;
        final updatedMessages = List<Message>.from(currentState.messages)
          ..insert(0, optimisticMessage); // Add at beginning (newest first)

        emit(currentState.copyWith(
          messages: updatedMessages,
          scrollToBottom: true,
        ));

        // Send message to server
        final sentMessage = await chatRepository.sendMessage(optimisticMessage);

        // Update with server-assigned ID and status
        final finalMessages = updatedMessages.map((m) {
          if (m.timestamp == optimisticMessage.timestamp &&
              m.senderId == optimisticMessage.senderId &&
              m.content == optimisticMessage.content) {
            return sentMessage;
          }
          return m;
        }).toList();

        emit(currentState.copyWith(
          messages: finalMessages,
          scrollToBottom: false, // Already scrolled when adding optimistic message
        ));
      } catch (e) {
        // Show error but keep optimistic message with error status
        emit(ChatError('Failed to send message: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onSendMediaMessage(
      SendMediaMessage event,
      Emitter<ChatState> emit,
      ) async {
    final currentState = state;
    if (currentState is ChatMessagesLoaded) {
      try {
        // Add message to UI immediately with temporary ID
        final optimisticMessage = event.message;
        final updatedMessages = List<Message>.from(currentState.messages)
          ..insert(0, optimisticMessage); // Add at beginning (newest first)

        emit(currentState.copyWith(
          messages: updatedMessages,
          scrollToBottom: true,
        ));

        // Upload media and send message to server
        final sentMessage = await chatRepository.sendMediaMessage(
          optimisticMessage,
          event.mediaFile,
        );

        // Update with server-assigned ID, media URL, and status
        final finalMessages = updatedMessages.map((m) {
          if (m.timestamp == optimisticMessage.timestamp &&
              m.senderId == optimisticMessage.senderId) {
            return sentMessage;
          }
          return m;
        }).toList();

        emit(currentState.copyWith(
          messages: finalMessages,
          scrollToBottom: false, // Already scrolled when adding optimistic message
        ));
      } catch (e) {
        // Show error but keep optimistic message with error status
        emit(ChatError('Failed to send media: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onMarkMessagesAsRead(
      MarkMessagesAsRead event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.markMessagesAsRead(event.conversationId);

      // We don't need to update UI here as the status updates will come through WebSocket
    } catch (e) {
      // Silently fail - this is not critical functionality
      print('Failed to mark messages as read: $e');
    }
  }

  Future<void> _onSetTypingStatus(
      SetTypingStatus event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.setTypingStatus(
        event.conversationId,
        event.receiverId,
        event.isTyping,
      );
    } catch (e) {
      // Silently fail - this is not critical functionality
      print('Failed to set typing status: $e');
    }
  }

  Future<void> _onMessageReceived(
      MessageReceived event,
      Emitter<ChatState> emit,
      ) async {
    final currentState = state;

    // Update conversations list if that's the current view
    if (currentState is ChatConversationsLoaded) {
      // Refresh conversations to show new message preview
      add(LoadConversations());
    }

    // Update messages list if we're viewing the relevant conversation
    if (currentState is ChatMessagesLoaded &&
        currentState.conversationId == event.message.conversationId) {

      // Check if message already exists (to avoid duplicates)
      final hasMessage = currentState.messages.any((m) =>
      m.id == event.message.id ||
          (m.content == event.message.content &&
              m.timestamp.isAtSameMomentAs(event.message.timestamp) &&
              m.senderId == event.message.senderId));

      if (!hasMessage) {
        final updatedMessages = List<Message>.from(currentState.messages)
          ..insert(0, event.message) // Add at beginning (newest first)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Ensure correct order

        emit(currentState.copyWith(
          messages: updatedMessages,
          scrollToBottom: true,
        ));

        // Mark as read since we're viewing the conversation
        add(MarkMessagesAsRead(event.message.conversationId));
      }
    }
  }

  Future<void> _onMessageStatusChanged(
      MessageStatusChanged event,
      Emitter<ChatState> emit,
      ) async {
    final currentState = state;

    // Update message status in messages list
    if (currentState is ChatMessagesLoaded &&
        currentState.conversationId == event.message.conversationId) {

      final updatedMessages = currentState.messages.map((m) {
        if (m.id == event.message.id) {
          return event.message;
        }
        return m;
      }).toList();

      emit(currentState.copyWith(
        messages: updatedMessages,
        scrollToBottom: false,
      ));
    }
  }

  Future<void> _onUserStatusChanged(
      UserStatusChanged event,
      Emitter<ChatState> emit,
      ) async {
    // Update online status map
    _onlineUsers[event.userId] = event.isOnline;

    final currentState = state;

    // Update UI if we're viewing a conversation with this user
    if (currentState is ChatMessagesLoaded &&
        currentState.otherUserId == event.userId) {

      emit(currentState.copyWith(
        isOtherUserOnline: event.isOnline,
      ));
    }

    // Also refresh conversations list to show updated online status
    if (currentState is ChatConversationsLoaded) {
      add(LoadConversations());
    }
  }

  Future<void> _onConnectionStatusChanged(
      ConnectionStatusChanged event,
      Emitter<ChatState> emit,
      ) async {
    // If connection was lost and restored, refresh data
    final currentState = state;

    if (currentState is ChatConversationsLoaded) {
      add(LoadConversations());
    } else if (currentState is ChatMessagesLoaded) {
      add(LoadMessages(
        currentState.conversationId,
        currentState.otherUserId,
      ));
    }
  }

  // Helper function to remove duplicate messages
  List<Message> _removeDuplicateMessages(List<Message> messages) {
    final uniqueMessages = <Message>[];
    final seenIds = <int>{};
    final seenSignatures = <String>{};

    for (final message in messages) {
      // If message has ID, check by ID
      if (message.id != null) {
        if (!seenIds.contains(message.id)) {
          seenIds.add(message.id!);
          uniqueMessages.add(message);
        }
      } else {
        // For messages without ID (e.g., optimistic), check by signature
        final signature = '${message.senderId}-${message.timestamp.millisecondsSinceEpoch}-${message.content}';
        if (!seenSignatures.contains(signature)) {
          seenSignatures.add(signature);
          uniqueMessages.add(message);
        }
      }
    }

    // Sort by timestamp (newest first)
    uniqueMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return uniqueMessages;
  }
}