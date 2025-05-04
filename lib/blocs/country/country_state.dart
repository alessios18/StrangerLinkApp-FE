part of 'country_bloc.dart';

abstract class CountryState extends Equatable {
  const CountryState();

  @override
  List<Object?> get props => [];
}

class CountryInitial extends CountryState {}

class CountryLoading extends CountryState {}

class CountriesLoaded extends CountryState {
  final List<Country> countries;
  final Country? selectedCountry;

  const CountriesLoaded({
    required this.countries,
    this.selectedCountry,
  });

  CountriesLoaded copyWith({
    List<Country>? countries,
    Country? selectedCountry,
    bool clearSelectedCountry = false,
  }) {
    return CountriesLoaded(
      countries: countries ?? this.countries,
      selectedCountry: clearSelectedCountry ? null : selectedCountry ?? this.selectedCountry,
    );
  }

  @override
  List<Object?> get props => [countries, selectedCountry];
}

class CountryError extends CountryState {
  final String message;

  const CountryError(this.message);

  @override
  List<Object?> get props => [message];
}