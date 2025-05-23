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

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    // Set up all event handlers
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
    on<TypingIndicatorReceived>(_onTypingIndicatorReceived);
    on<ForceRefreshMessages>(_onForceRefreshMessages);

    // Register callbacks with the repository
    _registerRepositoryCallbacks();
  }

  void _registerRepositoryCallbacks() {
    // Add all callback functions to the repository
    chatRepository.addMessageReceivedListener(_handleMessageReceived);
    chatRepository.addMessageStatusListener(_handleMessageStatusUpdate);
    chatRepository.addUserStatusListener(_handleUserStatusUpdate);
    chatRepository.addConnectionListener(_handleConnectionChanged);
    chatRepository.addNewConversationListener(_handleNewConversation);
    chatRepository.addTypingListener(_handleTypingIndicator);
  }

  // Callback handler functions
  void _handleMessageReceived(Message message) {
    add(MessageReceived(message));
  }

  void _handleMessageStatusUpdate(Message message) {
    add(MessageStatusChanged(message));
  }

  void _handleUserStatusUpdate(int userId, bool isOnline) {
    add(UserStatusChanged(userId, isOnline));
  }

  void _handleConnectionChanged() {
    add(ConnectionStatusChanged());
  }

  void _handleNewConversation() {
    add(LoadConversations());
  }

  void _handleTypingIndicator(int conversationId, int userId, bool isTyping) {
    add(TypingIndicatorReceived(conversationId, userId, isTyping));
  }

  void _onForceRefreshMessages(
      ForceRefreshMessages event,
      Emitter<ChatState> emit,
      ) async {
    print('🔄 Forzando aggiornamento dei messaggi per conversazione ${event.conversationId}');

    // Ricarica i messaggi dal server
    try {
      final messages = await chatRepository.getMessages(event.conversationId);

      final currentState = state;
      if (currentState is ChatMessagesLoaded &&
          currentState.conversationId == event.conversationId) {

        print('🔄 Aggiornando UI con ${messages.length} messaggi');

        // Aggiorna direttamente lo stato con i nuovi messaggi
        emit(ChatMessagesLoaded(
          conversationId: event.conversationId,
          otherUserId: currentState.otherUserId,
          messages: messages,
          hasMoreMessages: messages.length >= 20,
          isOtherUserTyping: currentState.isOtherUserTyping,
          isOtherUserOnline: currentState.isOtherUserOnline,
          scrollToBottom: true,
        ));
      }
    } catch (e) {
      print("🔴 Errore nel forzare l'aggiornamento: $e");
    }
  }

  Future<void> close() {
    // Remove all callbacks when the bloc is closed
    chatRepository.removeMessageReceivedListener(_handleMessageReceived);
    chatRepository.removeMessageStatusListener(_handleMessageStatusUpdate);
    chatRepository.removeUserStatusListener(_handleUserStatusUpdate);
    chatRepository.removeConnectionListener(_handleConnectionChanged);
    chatRepository.removeNewConversationListener(_handleNewConversation);
    chatRepository.removeTypingListener(_handleTypingIndicator);

    return super.close();
  }

  List<Message> _sortAndGroupMessages(List<Message> messages) {
    // First sort by timestamp (newest first for chat display)
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // The messages are now correctly sorted chronologically
    return messages;
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

        // If this is the first message in a new conversation (id = 0),
        // add the conversation to the conversations list
        if (event.message.conversationId == 0 && sentMessage.conversationId != 0) {
          // We need to reload the conversations to get the new one
          add(LoadConversations());
        }

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
          conversationId: sentMessage.conversationId, // Update conversation ID
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
    print('🔍 DEBUG: Gestore _onMessageReceived chiamato: ${event.message.content}');

    // Get current state
    final currentState = state;
    print('🔍 DEBUG: Stato corrente: ${currentState.runtimeType}');

    // Force refresh of conversations list
    // add(LoadConversations());

    // If we're in the relevant conversation
    if (currentState is ChatMessagesLoaded &&
        currentState.conversationId == event.message.conversationId) {
      print('🔍 DEBUG: Aggiornamento messaggi per conversazione corrente');

      // Create a new list that includes all existing messages + the new one
      final updatedMessages = List<Message>.from(currentState.messages);

      // Add the new message if it's not already there
      bool messageExists = updatedMessages.any((m) =>
      m.id == event.message.id ||
          (m.timestamp.isAtSameMomentAs(event.message.timestamp) &&
              m.senderId == event.message.senderId &&
              m.content == event.message.content));

      if (!messageExists) {
        updatedMessages.add(event.message);

        // Apply proper sorting
        final sortedMessages = _sortAndGroupMessages(updatedMessages);

        // Debug info
        print('Message ordering debug:');
        for (var msg in sortedMessages) {
          print('${msg.timestamp}: ${msg.content.substring(0, msg.content.length > 10 ? 10 : msg.content.length)}...');
        }
        // Emit new state with updated messages
        try {
          print('🔍 DEBUG: Emissione nuovo stato con messaggio aggiunto');
          emit(ChatMessagesLoaded(
            conversationId: currentState.conversationId,
            otherUserId: currentState.otherUserId,
            messages: sortedMessages,
            hasMoreMessages: currentState.hasMoreMessages,
            isOtherUserTyping: currentState.isOtherUserTyping,
            isOtherUserOnline: currentState.isOtherUserOnline,
            scrollToBottom: true,
          ));
          print('🔍 DEBUG: Nuovo stato emesso con successo');
        } catch (e) {
          print('🔴 ERRORE nell\'emissione del nuovo stato: $e');
        }
      } else {
        print('🔍 DEBUG: Il messaggio esiste già nella lista, nessun aggiornamento necessario');
      }
    } else {
      print('🔍 DEBUG: Messaggio ricevuto per una conversazione diversa');
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

  Future<void> _onTypingIndicatorReceived(
      TypingIndicatorReceived event,
      Emitter<ChatState> emit,
      ) async {
    // Update typing status map
    _typingUsers[event.userId] = event.isTyping;

    final currentState = state;

    // Update UI if we're viewing a conversation with this user
    if (currentState is ChatMessagesLoaded &&
        currentState.conversationId == event.conversationId) {

      emit(currentState.copyWith(
        isOtherUserTyping: event.isTyping,
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