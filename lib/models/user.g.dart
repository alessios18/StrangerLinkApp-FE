// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  createdAt: DateTimeUtils.fromJson(json['createdAt']),
  lastActive: DateTimeUtils.fromJson(json['lastActive']),
  profileImageUrl: json['profileImageUrl'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'profileImageUrl': instance.profileImageUrl,
  'createdAt': DateTimeUtils.toJson(instance.createdAt),
  'lastActive': DateTimeUtils.toJson(instance.lastActive),
};
