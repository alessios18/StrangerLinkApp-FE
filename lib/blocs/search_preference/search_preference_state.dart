part of 'search_preference_bloc.dart';

abstract class SearchPreferenceState extends Equatable {
  const SearchPreferenceState();

  @override
  List<Object?> get props => [];
}

class SearchPreferenceInitial extends SearchPreferenceState {}

class SearchPreferenceLoading extends SearchPreferenceState {}

class SearchPreferencesLoaded extends SearchPreferenceState {
  final SearchPreference preferences;
  final bool isEditMode;

  const SearchPreferencesLoaded({
    required this.preferences,
    this.isEditMode = false,
  });

  SearchPreferencesLoaded copyWith({
    SearchPreference? preferences,
    bool? isEditMode,
  }) {
    return SearchPreferencesLoaded(
      preferences: preferences ?? this.preferences,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }

  @override
  List<Object?> get props => [preferences, isEditMode];
}

class SearchPreferenceUpdating extends SearchPreferenceState {}

class SearchPreferenceUpdated extends SearchPreferenceState {
  final SearchPreference preferences;

  const SearchPreferenceUpdated(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class SearchPreferenceError extends SearchPreferenceState {
  final String message;

  const SearchPreferenceError(this.message);

  @override
  List<Object?> get props => [message];
}