// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  createdAt: User._dateTimeFromJson(json['created_at']),
  lastActive: User._dateTimeFromJson(json['last_active']),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'created_at': User._dateTimeToJson(instance.createdAt),
  'last_active': User._dateTimeToJson(instance.lastActive),
};
