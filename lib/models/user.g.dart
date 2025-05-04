// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  createdAt: User._dateTimeFromJson(json['createdAt']),
  lastActive: User._dateTimeFromJson(json['lastActive']),
  profileImageUrl: json['profileImageUrl'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'profileImageUrl': instance.profileImageUrl,
  'createdAt': User._dateTimeToJson(instance.createdAt),
  'lastActive': User._dateTimeToJson(instance.lastActive),
};
