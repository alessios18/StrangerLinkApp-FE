part of 'search_preference_bloc.dart';

abstract class SearchPreferenceEvent extends Equatable {
  const SearchPreferenceEvent();

  @override
  List<Object?> get props => [];
}

class LoadSearchPreferences extends SearchPreferenceEvent {}

class UpdateSearchPreferences extends SearchPreferenceEvent {
  final SearchPreference preferences;

  const UpdateSearchPreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class SetMinAge extends SearchPreferenceEvent {
  final int minAge;

  const SetMinAge(this.minAge);

  @override
  List<Object?> get props => [minAge];
}

class SetMaxAge extends SearchPreferenceEvent {
  final int maxAge;

  const SetMaxAge(this.maxAge);

  @override
  List<Object?> get props => [maxAge];
}

class SetPreferredGender extends SearchPreferenceEvent {
  final String preferredGender;

  const SetPreferredGender(this.preferredGender);

  @override
  List<Object?> get props => [preferredGender];
}

class SetPreferredCountry extends SearchPreferenceEvent {
  final int? preferredCountryId;

  const SetPreferredCountry(this.preferredCountryId);

  @override
  List<Object?> get props => [preferredCountryId];
}

class SetAllCountries extends SearchPreferenceEvent {
  final bool allCountries;

  const SetAllCountries(this.allCountries);

  @override
  List<Object?> get props => [allCountries];
}

class SaveSearchPreferences extends SearchPreferenceEvent {}