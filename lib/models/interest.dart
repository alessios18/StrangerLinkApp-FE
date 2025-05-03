import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'interest.g.dart';

@JsonSerializable()
class Interest extends Equatable {
  final int id;
  final String name;

  const Interest({
    required this.id,
    required this.name,
  });

  factory Interest.fromJson(Map<String, dynamic> json) => _$InterestFromJson(json);

  Map<String, dynamic> toJson() => _$InterestToJson(this);

  @override
  List<Object?> get props => [id, name];
}