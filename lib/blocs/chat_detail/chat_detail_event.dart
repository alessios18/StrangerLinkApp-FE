part of 'chat_detail_bloc.dart';

abstract class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatMessages extends ChatDetailEvent {
  final int conversationId;
  final int otherUserId;

  const LoadChatMessages({
    required this.conversationId,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [conversationId, otherUserId];
}

class LoadMoreChatMessages extends ChatDetailEvent {
  const LoadMoreChatMessages();
}

class SendChatMessage extends ChatDetailEvent {
  final Message message;

  const SendChatMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class SendMediaMessage extends ChatDetailEvent {
  final Message message;
  final File mediaFile;

  const SendMediaMessage({
    required this.message,
    required this.mediaFile,
  });

  @override
  List<Object?> get props => [message, mediaFile];
}

class UpdateTypingStatus extends ChatDetailEvent {
  final bool isTyping;

  const UpdateTypingStatus(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

class MessageReceived extends ChatDetailEvent {
  final List<Message> messages;

  const MessageReceived(this.messages);

  @override
  List<Object?> get props => [messages];
}

class TypingIndicatorReceived extends ChatDetailEvent {
  final bool isTyping;

  const TypingIndicatorReceived(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

class UserStatusChanged extends ChatDetailEvent {
  final bool isOnline;

  const UserStatusChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

class SelectImage extends ChatDetailEvent {
  final File imageFile;

  const SelectImage(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class MessageStatusChanged extends ChatDetailEvent {
  final Message message;

  const MessageStatusChanged(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearSelectedImage extends ChatDetailEvent {
  const ClearSelectedImage();
}