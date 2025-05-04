import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final int id;
  final String username;
  final String email;

  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  @JsonKey(name: 'last_active', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime lastActive;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.lastActive,
  });

  // Funzioni statiche per la conversione che gestiscono diversi tipi di input
  static DateTime _dateTimeFromJson(dynamic value) {
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

  static int _dateTimeToJson(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [id, username, email, createdAt, lastActive];
}