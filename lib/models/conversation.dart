// lib/models/conversation.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:stranger_link_app/models/user.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation extends Equatable {
  final int id;
  final User otherUser;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final bool isOnline;

  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.unreadCount,
    required this.isOnline,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return _$ConversationFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  Conversation copyWith({
    int? id,
    User? otherUser,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    int? unreadCount,
    bool? isOnline,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
    id,
    otherUser,
    lastMessage,
    lastMessageTimestamp,
    unreadCount,
    isOnline,
  ];
}