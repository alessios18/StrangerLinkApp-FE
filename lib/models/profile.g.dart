// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
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
      'id': instance.id,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'age': instance.age,
      'country': instance.country,
      'gender': instance.gender,
      'bio': instance.bio,
      'profile_image_url': instance.profileImageUrl,
      'interests': instance.interests,
    };
