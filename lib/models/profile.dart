import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:stranger_link_app/models/country.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile extends Equatable {

  final String displayName;

  final int? age;
  final Country? country;
  final String? gender;
  final String? bio;

  final String? profileImageUrl;

  final List<String>? interests;

  const Profile({
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

  Profile copyWith({
    String? displayName,
    int? age,
    Country? country,
    String? gender,
    String? bio,
    String? profileImageUrl,
    List<String>? interests,
  }) {
    return Profile(
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      interests: interests ?? this.interests,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    age,
    country,
    gender,
    bio,
    profileImageUrl,
    interests
  ];
}