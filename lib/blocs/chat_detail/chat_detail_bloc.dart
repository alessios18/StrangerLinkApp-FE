import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart' as chat;
import 'package:stranger_link_app/models/message.dart';
import 'package:stranger_link_app/repositories/chat_repository.dart';

part 'chat_detail_event.dart';
part 'chat_detail_state.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final chat.ChatBloc chatBloc;
  final ChatRepository chatRepository;
  late StreamSubscription chatBlocSubscription;
  Timer? _typingTimer;

  ChatDetailBloc({
    required this.chatBloc,
    required this.chatRepository,
  }) : super(ChatDetailInitial()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<LoadMoreChatMessages>(_onLoadMoreChatMessages);
    on<SendChatMessage>(_onSendChatMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
    on<MessageReceived>(_onMessageReceived);
    on<TypingIndicatorReceived>(_onTypingIndicatorReceived);
    on<UserStatusChanged>(_onUserStatusChanged);
    on<SelectImage>(_onSelectImage);
    on<ClearSelectedImage>(_onClearSelectedImage);

    // Listen to ChatBloc for relevant updates
    chatBlocSubscription = chatBloc.stream.listen((chatState) {
      if (chatState is chat.ChatMessagesLoaded && state is ChatDetailLoaded) {
        final currentState = state as ChatDetailLoaded;
        if (currentState.conversationId == chatState.conversationId) {
          // Update messages if they've changed
          add(MessageReceived(chatState.messages));

          // Update typing status
          if (currentState.isOtherUserTyping != chatState.isOtherUserTyping) {
            add(TypingIndicatorReceived(chatState.isOtherUserTyping));
          }

          // Update online status
          if (currentState.isOtherUserOnline != chatState.isOtherUserOnline) {
            add(UserStatusChanged(chatState.isOtherUserOnline));
          }
        }
      }
    });
  }

  Future<void> _onLoadChatMessages(
      LoadChatMessages event,
      Emitter<ChatDetailState> emit,
      ) async {
    emit(ChatDetailLoading());

    try {
      // Request messages through ChatBloc
      chatBloc.add(chat.LoadMessages(event.conversationId, event.otherUserId));

      // Mark messages as read
      if (event.conversationId > 0) {
        chatBloc.add(chat.MarkMessagesAsRead(event.conversationId));
      }

      // Wait for messages to load from ChatBloc
      final messages = await chatRepository.getMessages(event.conversationId);

      if (event.conversationId > 0) {
        chatRepository.sendDeliveryReceipt(event.conversationId);
      }

      emit(ChatDetailLoaded(
        conversationId: event.conversationId,
        otherUserId: event.otherUserId,
        messages: messages,
        hasMoreMessages: messages.length >= 20,
        isOtherUserTyping: false,
        isOtherUserOnline: false,
        selectedImage: null,
      ));
    } catch (e) {
      emit(ChatDetailError(e.toString()));
    }
  }

  Future<void> _onLoadMoreChatMessages(
      LoadMoreChatMessages event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;

      try {
        final page = (currentState.messages.length / 20).floor();
        final olderMessages = await chatRepository.getMessages(
          currentState.conversationId,
          page: page + 1,
        );

        if (olderMessages.isNotEmpty) {
          // Combine with existing messages and remove duplicates
          final allMessages = List<Message>.from(currentState.messages)
            ..addAll(olderMessages);

          final uniqueMessages = _removeDuplicateMessages(allMessages);

          emit(currentState.copyWith(
            messages: uniqueMessages,
            hasMoreMessages: olderMessages.length >= 20,
          ));
        } else {
          emit(currentState.copyWith(hasMoreMessages: false));
        }
      } catch (e) {
        // Show error but keep current messages
        emit(ChatDetailError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onSendChatMessage(
      SendChatMessage event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;
      final message = event.message;

      try {
        // Add optimistic message to UI immediately
        final updatedMessages = List<Message>.from(currentState.messages)
          ..insert(0, message);

        emit(currentState.copyWith(
          messages: updatedMessages,
          scrollToBottom: true,
        ));

        // Send message via repository
        final sentMessage = await chatRepository.sendMessage(message);

        // Update with server-assigned ID and status
        final finalMessages = updatedMessages.map((m) {
          if (m.timestamp == message.timestamp && m.senderId == message.senderId) {
            return sentMessage;
          }
          return m;
        }).toList();

        emit(currentState.copyWith(
          messages: finalMessages,
          conversationId: sentMessage.conversationId,
          scrollToBottom: false,
        ));
      } catch (e) {
        emit(ChatDetailError('Failed to send message: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onSendMediaMessage(
      SendMediaMessage event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;
      final message = event.message;

      try {
        // Add optimistic message to UI immediately
        final updatedMessages = List<Message>.from(currentState.messages)
          ..insert(0, message);

        emit(currentState.copyWith(
          messages: updatedMessages,
          scrollToBottom: true,
          selectedImage: null, // Clear selected image after sending
        ));

        // Send media message via repository
        final sentMessage = await chatRepository.sendMediaMessage(message, event.mediaFile);

        // Update with server info (media URL, etc.)
        final finalMessages = updatedMessages.map((m) {
          if (m.timestamp == message.timestamp && m.senderId == message.senderId) {
            return sentMessage;
          }
          return m;
        }).toList();

        emit(currentState.copyWith(
          messages: finalMessages,
          scrollToBottom: false,
        ));
      } catch (e) {
        emit(ChatDetailError('Failed to send media: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateTypingStatus(
      UpdateTypingStatus event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;

      try {
        // Send typing status to server
        await chatRepository.setTypingStatus(
          currentState.conversationId,
          currentState.otherUserId,
          event.isTyping,
        );

        // Reset typing timer if needed
        _typingTimer?.cancel();
        if (event.isTyping) {
          _typingTimer = Timer(const Duration(seconds: 3), () {
            add(const UpdateTypingStatus(false));
          });
        }
      } catch (e) {
        // Silently fail, non-critical functionality
        print('Failed to set typing status: $e');
      }
    }
  }

  Future<void> _onMessageReceived(
      MessageReceived event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;

      // Add message to existing list if not already there
      final messages = List<Message>.from(currentState.messages);
      bool messageExists = false;

      for (final message in event.messages) {
        messageExists = messages.any((m) =>
        (m.id != null && m.id == message.id) ||
            (m.id == null && m.senderId == message.senderId &&
                m.timestamp.isAtSameMomentAs(message.timestamp))
        );

        if (!messageExists) {
          messages.add(message);
        }
      }

      // Sort messages (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      emit(currentState.copyWith(
        messages: messages,
        scrollToBottom: !messageExists,
      ));

      // Mark as read if receiving new messages
      if (!messageExists && currentState.conversationId > 0) {
        chatBloc.add(chat.MarkMessagesAsRead(currentState.conversationId));
      }
    }
  }

  Future<void> _onTypingIndicatorReceived(
      TypingIndicatorReceived event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;

      emit(currentState.copyWith(
        isOtherUserTyping: event.isTyping,
      ));
    }
  }

  Future<void> _onUserStatusChanged(
      UserStatusChanged event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;

      emit(currentState.copyWith(
        isOtherUserOnline: event.isOnline,
      ));
    }
  }

  Future<void> _onSelectImage(
      SelectImage event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;

      emit(currentState.copyWith(
        selectedImage: event.imageFile,
      ));
    }
  }

  Future<void> _onClearSelectedImage(
      ClearSelectedImage event,
      Emitter<ChatDetailState> emit,
      ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;

      emit(currentState.copyWith(
        selectedImage: null,
      ));
    }
  }

  // Helper method to remove duplicate messages
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

  @override
  Future<void> close() {
    chatBlocSubscription.cancel();
    _typingTimer?.cancel();
    return super.close();
  }
}