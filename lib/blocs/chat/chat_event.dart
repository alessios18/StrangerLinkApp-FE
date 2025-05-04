// lib/blocs/chat/chat_event.dart
part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final int conversationId;
  final int otherUserId;

  const LoadMessages(this.conversationId, [this.otherUserId = 0]);

  @override
  List<Object?> get props => [conversationId, otherUserId];
}

class LoadMoreMessages extends ChatEvent {
  final int conversationId;

  const LoadMoreMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendTextMessage extends ChatEvent {
  final Message message;

  const SendTextMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class SendMediaMessage extends ChatEvent {
  final Message message;
  final File mediaFile;

  const SendMediaMessage(this.message, this.mediaFile);

  @override
  List<Object?> get props => [message, mediaFile];
}

class MarkMessagesAsRead extends ChatEvent {
  final int conversationId;

  const MarkMessagesAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SetTypingStatus extends ChatEvent {
  final int conversationId;
  final int receiverId;
  final bool isTyping;

  const SetTypingStatus(this.conversationId, this.receiverId, this.isTyping);

  @override
  List<Object?> get props => [conversationId, receiverId, isTyping];
}

// Events triggered by WebSocket

class MessageReceived extends ChatEvent {
  final Message message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageStatusChanged extends ChatEvent {
  final Message message;

  const MessageStatusChanged(this.message);

  @override
  List<Object?> get props => [message];
}

class UserStatusChanged extends ChatEvent {
  final int userId;
  final bool isOnline;

  const UserStatusChanged(this.userId, this.isOnline);

  @override
  List<Object?> get props => [userId, isOnline];
}

class ConnectionStatusChanged extends ChatEvent {}