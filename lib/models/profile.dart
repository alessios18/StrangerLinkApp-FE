import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile extends Equatable {
  final int id;

  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(name: 'display_name')
  final String displayName;

  final int? age;
  final String? country;
  final String? gender;
  final String? bio;

  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  final List<String>? interests;

  const Profile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.age,
    this.country,
    this.gender,
    this.bio,
    this.profileImageUrl,
    this.interests,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    displayName,
    age,
    country,
    gender,
    bio,
    profileImageUrl,
    interests
  ];
}