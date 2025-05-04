import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stranger_link_app/models/country.dart';
import 'package:stranger_link_app/repositories/country_repository.dart';

part 'country_event.dart';
part 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final CountryRepository _countryRepository;

  CountryBloc({required CountryRepository countryRepository})
      : _countryRepository = countryRepository,
        super(CountryInitial()) {
    on<LoadCountries>(_onLoadCountries);
    on<SelectCountry>(_onSelectCountry);
  }

  Future<void> _onLoadCountries(
      LoadCountries event,
      Emitter<CountryState> emit,
      ) async {
    emit(CountryLoading());
    try {
      final countries = await _countryRepository.getAllCountries();
      emit(CountriesLoaded(countries: countries));
    } catch (e) {
      emit(CountryError(e.toString()));
    }
  }

  void _onSelectCountry(
      SelectCountry event,
      Emitter<CountryState> emit,
      ) {
    final currentState = state;
    if (currentState is CountriesLoaded) {
      emit(currentState.copyWith(selectedCountry: event.country));
    }
  }
}
