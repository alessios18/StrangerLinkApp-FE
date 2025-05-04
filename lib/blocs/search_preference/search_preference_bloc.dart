import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stranger_link_app/models/search_preference.dart';
import 'package:stranger_link_app/repositories/search_preference_repository.dart';

part 'search_preference_event.dart';
part 'search_preference_state.dart';

class SearchPreferenceBloc extends Bloc<SearchPreferenceEvent, SearchPreferenceState> {
  final SearchPreferenceRepository _searchPreferenceRepository;

  SearchPreferenceBloc({required SearchPreferenceRepository searchPreferenceRepository})
      : _searchPreferenceRepository = searchPreferenceRepository,
        super(SearchPreferenceInitial()) {
    on<LoadSearchPreferences>(_onLoadSearchPreferences);
    on<UpdateSearchPreferences>(_onUpdateSearchPreferences);
    on<SetMinAge>(_onSetMinAge);
    on<SetMaxAge>(_onSetMaxAge);
    on<SetPreferredGender>(_onSetPreferredGender);
    on<SetPreferredCountry>(_onSetPreferredCountry);
    on<SetAllCountries>(_onSetAllCountries);
    on<SaveSearchPreferences>(_onSaveSearchPreferences);
  }

  Future<void> _onLoadSearchPreferences(
      LoadSearchPreferences event,
      Emitter<SearchPreferenceState> emit,
      ) async {
    emit(SearchPreferenceLoading());
    try {
      final preferences = await _searchPreferenceRepository.getSearchPreferences();
      emit(SearchPreferencesLoaded(preferences: preferences));
    } catch (e) {
      emit(SearchPreferenceError(e.toString()));
    }
  }

  Future<void> _onUpdateSearchPreferences(
      UpdateSearchPreferences event,
      Emitter<SearchPreferenceState> emit,
      ) async {
    final currentState = state;
    if (currentState is SearchPreferencesLoaded) {
      emit(SearchPreferenceUpdating());
      try {
        final updatedPreferences = await _searchPreferenceRepository.updateSearchPreferences(event.preferences);
        emit(SearchPreferenceUpdated(updatedPreferences));
        emit(SearchPreferencesLoaded(preferences: updatedPreferences));
      } catch (e) {
        emit(SearchPreferenceError(e.toString()));
        emit(currentState); // Rollback to the previous state
      }
    }
  }

  void _onSetMinAge(
      SetMinAge event,
      Emitter<SearchPreferenceState> emit,
      ) {
    final currentState = state;
    if (currentState is SearchPreferencesLoaded) {
      final updatedPreferences = currentState.preferences.copyWith(
        minAge: event.minAge,
      );
      emit(currentState.copyWith(preferences: updatedPreferences));
    }
  }

  void _onSetMaxAge(
      SetMaxAge event,
      Emitter<SearchPreferenceState> emit,
      ) {
    final currentState = state;
    if (currentState is SearchPreferencesLoaded) {
      final updatedPreferences = currentState.preferences.copyWith(
        maxAge: event.maxAge,
      );
      emit(currentState.copyWith(preferences: updatedPreferences));
    }
  }

  void _onSetPreferredGender(
      SetPreferredGender event,
      Emitter<SearchPreferenceState> emit,
      ) {
    final currentState = state;
    if (currentState is SearchPreferencesLoaded) {
      final updatedPreferences = currentState.preferences.copyWith(
        preferredGender: event.preferredGender,
      );
      emit(currentState.copyWith(preferences: updatedPreferences));
    }
  }

  void _onSetPreferredCountry(
      SetPreferredCountry event,
      Emitter<SearchPreferenceState> emit,
      ) {
    final currentState = state;
    if (currentState is SearchPreferencesLoaded) {
      final updatedPreferences = currentState.preferences.copyWith(
        preferredCountryId: event.preferredCountryId,
        allCountries: event.preferredCountryId == null,
      );
      emit(currentState.copyWith(preferences: updatedPreferences));
    }
  }

  void _onSetAllCountries(
      SetAllCountries event,
      Emitter<SearchPreferenceState> emit,
      ) {
    final currentState = state;
    if (currentState is SearchPreferencesLoaded) {
      final updatedPreferences = currentState.preferences.copyWith(
        allCountries: event.allCountries,
        // Se allCountries è true, azzeriamo il preferredCountryId
        preferredCountryId: event.allCountries ? null : currentState.preferences.preferredCountryId,
      );
      emit(currentState.copyWith(preferences: updatedPreferences));
    }
  }

  Future<void> _onSaveSearchPreferences(
      SaveSearchPreferences event,
      Emitter<SearchPreferenceState> emit,
      ) async {
    final currentState = state;
    if (currentState is SearchPreferencesLoaded) {
      emit(SearchPreferenceUpdating());
      try {
        final updatedPreferences = await _searchPreferenceRepository.updateSearchPreferences(currentState.preferences);
        emit(SearchPreferenceUpdated(updatedPreferences));
        emit(SearchPreferencesLoaded(preferences: updatedPreferences));
      } catch (e) {
        emit(SearchPreferenceError(e.toString()));
        emit(currentState); // Rollback to the previous state
      }
    }
  }
}