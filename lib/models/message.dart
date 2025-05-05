// lib/models/message.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../util/date_time_utils.dart';

part 'message.g.dart';

@JsonSerializable()
class Message extends Equatable {
  final int? id;
  final int senderId;
  final int conversationId;
  final String content;

  @JsonKey(name: 'timestamp', fromJson: DateTimeUtils.fromJson, toJson: DateTimeUtils.toJson)
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final String? mediaUrl;
  final String? mediaType;
  final int? receiverId; // Used only for sending

  const Message({
    this.id,
    required this.senderId,
    required this.conversationId,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.status,
    this.mediaUrl,
    this.mediaType,
    this.receiverId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return _$MessageFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    int? id,
    int? senderId,
    int? conversationId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    String? mediaUrl,
    String? mediaType,
    int? receiverId,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      receiverId: receiverId ?? this.receiverId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    conversationId,
    content,
    timestamp,
    type,
    status,
    mediaUrl,
    mediaType,
    receiverId
  ];
}

enum MessageType { TEXT, IMAGE, VIDEO, DOCUMENT }

enum MessageStatus { SENT, DELIVERED, READ }