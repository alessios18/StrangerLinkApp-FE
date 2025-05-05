import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../util/date_time_utils.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final String? profileImageUrl;

  @JsonKey(name: 'createdAt', fromJson: DateTimeUtils.fromJson, toJson: DateTimeUtils.toJson)
  final DateTime createdAt;

  @JsonKey(name: 'lastActive', fromJson: DateTimeUtils.fromJson, toJson: DateTimeUtils.toJson)
  final DateTime lastActive;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.lastActive,
    this.profileImageUrl
  });


  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [id, username, email, createdAt, lastActive];
}