// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchPreference _$SearchPreferenceFromJson(Map<String, dynamic> json) =>
    SearchPreference(
      minAge: (json['minAge'] as num?)?.toInt(),
      maxAge: (json['maxAge'] as num?)?.toInt(),
      preferredGender: json['preferredGender'] as String?,
      preferredCountryId: (json['preferredCountryId'] as num?)?.toInt(),
      allCountries: json['allCountries'] as bool? ?? true,
    );

Map<String, dynamic> _$SearchPreferenceToJson(SearchPreference instance) =>
    <String, dynamic>{
      'minAge': instance.minAge,
      'maxAge': instance.maxAge,
      'preferredGender': instance.preferredGender,
      'preferredCountryId': instance.preferredCountryId,
      'allCountries': instance.allCountries,
    };
