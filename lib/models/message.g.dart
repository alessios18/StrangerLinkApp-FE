// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: (json['id'] as num?)?.toInt(),
  senderId: (json['senderId'] as num).toInt(),
  conversationId: (json['conversationId'] as num).toInt(),
  content: json['content'] as String,
  timestamp: Message._dateTimeFromJson(json['timestamp']),
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
  status: $enumDecode(_$MessageStatusEnumMap, json['status']),
  mediaUrl: json['mediaUrl'] as String?,
  mediaType: json['mediaType'] as String?,
  receiverId: (json['receiverId'] as num?)?.toInt(),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'senderId': instance.senderId,
  'conversationId': instance.conversationId,
  'content': instance.content,
  'timestamp': Message._dateTimeToJson(instance.timestamp),
  'type': _$MessageTypeEnumMap[instance.type]!,
  'status': _$MessageStatusEnumMap[instance.status]!,
  'mediaUrl': instance.mediaUrl,
  'mediaType': instance.mediaType,
  'receiverId': instance.receiverId,
};

const _$MessageTypeEnumMap = {
  MessageType.TEXT: 'TEXT',
  MessageType.IMAGE: 'IMAGE',
  MessageType.VIDEO: 'VIDEO',
  MessageType.DOCUMENT: 'DOCUMENT',
};

const _$MessageStatusEnumMap = {
  MessageStatus.SENT: 'SENT',
  MessageStatus.DELIVERED: 'DELIVERED',
  MessageStatus.READ: 'READ',
};
