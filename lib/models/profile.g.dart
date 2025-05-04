// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  displayName: json['displayName'] as String,
  age: (json['age'] as num?)?.toInt(),
  country:
      json['country'] == null
          ? null
          : Country.fromJson(json['country'] as Map<String, dynamic>),
  gender: json['gender'] as String?,
  bio: json['bio'] as String?,
  profileImageUrl: json['profileImageUrl'] as String?,
  interests:
      (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'displayName': instance.displayName,
  'age': instance.age,
  'country': instance.country,
  'gender': instance.gender,
  'bio': instance.bio,
  'profileImageUrl': instance.profileImageUrl,
  'interests': instance.interests,
};
