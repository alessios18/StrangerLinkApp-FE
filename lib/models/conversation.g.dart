// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: (json['id'] as num).toInt(),
  otherUser: User.fromJson(json['otherUser'] as Map<String, dynamic>),
  lastMessage: json['lastMessage'] as String?,
  lastMessageTimestamp: DateTimeUtils.fromJsonNullable(
    json['lastMessageTimestamp'],
  ),
  unreadCount: (json['unreadCount'] as num).toInt(),
  isOnline: json['isOnline'] as bool?,
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'otherUser': instance.otherUser,
      'lastMessage': instance.lastMessage,
      'lastMessageTimestamp': DateTimeUtils.toJsonNullable(
        instance.lastMessageTimestamp,
      ),
      'unreadCount': instance.unreadCount,
      'isOnline': instance.isOnline,
    };
