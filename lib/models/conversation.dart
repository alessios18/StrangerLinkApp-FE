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
  @JsonKey(name: 'lastMessageTimestamp',fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final bool? isOnline;

  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.unreadCount,
    this.isOnline,
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

  static DateTime? _dateTimeFromJson(dynamic value) {
    if(value == null){
      return null;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } else if (value is String) {
      // Gestione del caso in cui il valore sia una stringa (come in precedenza)
      return DateTime.parse(value);
    }
    // Fallback
    return DateTime.now();
  }

  static int? _dateTimeToJson(DateTime? dateTime) {
    if(dateTime == null){
      return null;
    }
    return dateTime.millisecondsSinceEpoch;
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