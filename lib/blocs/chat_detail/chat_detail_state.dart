part of 'chat_detail_bloc.dart';

abstract class ChatDetailState extends Equatable {
  const ChatDetailState();

  @override
  List<Object?> get props => [];
}

class ChatDetailInitial extends ChatDetailState {}

class ChatDetailLoading extends ChatDetailState {}

class ChatDetailLoaded extends ChatDetailState {
  final int conversationId;
  final int otherUserId;
  final List<Message> messages;
  final bool hasMoreMessages;
  final bool isOtherUserTyping;
  final bool isOtherUserOnline;
  final File? selectedImage;
  final bool scrollToBottom;

  const ChatDetailLoaded({
    required this.conversationId,
    required this.otherUserId,
    required this.messages,
    this.hasMoreMessages = false,
    this.isOtherUserTyping = false,
    this.isOtherUserOnline = false,
    this.selectedImage,
    this.scrollToBottom = false,
  });

  ChatDetailLoaded copyWith({
    int? conversationId,
    int? otherUserId,
    List<Message>? messages,
    bool? hasMoreMessages,
    bool? isOtherUserTyping,
    bool? isOtherUserOnline,
    File? selectedImage,
    bool? scrollToBottom,
    bool clearSelectedImage = false,
  }) {
    return ChatDetailLoaded(
      conversationId: conversationId ?? this.conversationId,
      otherUserId: otherUserId ?? this.otherUserId,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
      selectedImage: clearSelectedImage ? null : selectedImage ?? this.selectedImage,
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
    selectedImage,
    scrollToBottom,
  ];
}

class ChatDetailError extends ChatDetailState {
  final String message;

  const ChatDetailError(this.message);

  @override
  List<Object?> get props => [message];
}