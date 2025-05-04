// lib/models/search_preference.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_preference.g.dart';

@JsonSerializable()
class SearchPreference extends Equatable {
  final int? minAge;
  final int? maxAge;
  final String? preferredGender;
  final int? preferredCountryId;
  final bool allCountries;

  const SearchPreference({
    this.minAge,
    this.maxAge,
    this.preferredGender,
    this.preferredCountryId,
    this.allCountries = true,
  });

  factory SearchPreference.fromJson(Map<String, dynamic> json) => _$SearchPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$SearchPreferenceToJson(this);

  SearchPreference copyWith({
    int? minAge,
    int? maxAge,
    String? preferredGender,
    int? preferredCountryId,
    bool? allCountries,
  }) {
    return SearchPreference(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      preferredGender: preferredGender ?? this.preferredGender,
      preferredCountryId: preferredCountryId ?? this.preferredCountryId,
      allCountries: allCountries ?? this.allCountries,
    );
  }

  @override
  List<Object?> get props => [minAge, maxAge, preferredGender, preferredCountryId, allCountries];
}