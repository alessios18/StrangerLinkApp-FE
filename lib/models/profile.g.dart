// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
      displayName: json['display_name'] as String,
      age: (json['age'] as num?)?.toInt(),
      country: json['country'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'display_name': instance.displayName,
      'age': instance.age,
      'country': instance.country,
      'gender': instance.gender,
      'bio': instance.bio,
      'profile_image_url': instance.profileImageUrl,
      'interests': instance.interests,
    };
