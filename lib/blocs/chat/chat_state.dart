// lib/blocs/chat/chat_state.dart
part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  // Use explicit types
  final List<Conversation> conversations;
  final List<Message> messages;

  const ChatLoading({
    this.conversations = const [], // Dart will infer the correct type
    this.messages = const [], // Dart will infer the correct type
  });

  @override
  List<Object?> get props => [conversations, messages];
}

class ChatConversationsLoaded extends ChatState {
  final List<Conversation> conversations;

  const ChatConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class ChatMessagesLoaded extends ChatState {
  final int conversationId;
  final int otherUserId;
  final List<Message> messages;
  final bool hasMoreMessages;
  final bool isOtherUserTyping;
  final bool isOtherUserOnline;
  final bool scrollToBottom;

  const ChatMessagesLoaded({
    required this.conversationId,
    required this.otherUserId,
    required this.messages,
    this.hasMoreMessages = false,
    this.isOtherUserTyping = false,
    this.isOtherUserOnline = false,
    this.scrollToBottom = false,
  });

  ChatMessagesLoaded copyWith({
    int? conversationId,
    int? otherUserId,
    List<Message>? messages,
    bool? hasMoreMessages,
    bool? isOtherUserTyping,
    bool? isOtherUserOnline,
    bool? scrollToBottom,
  }) {
    return ChatMessagesLoaded(
      conversationId: conversationId ?? this.conversationId,
      otherUserId: otherUserId ?? this.otherUserId,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
      scrollToBottom: scrollToBottom ?? this.scrollToBottom,
    );
  }

  @override
  List<Object?> get props => [
    conversationId,
    otherUserId,
    messages,
    hasMoreMessages,
    isOtherUserTyping,
    isOtherUserOnline,
    scrollToBottom,
  ];
}

class ChatMessageSent extends ChatState {
  final Message message;

  const ChatMessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}