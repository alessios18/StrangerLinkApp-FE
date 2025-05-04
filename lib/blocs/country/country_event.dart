part of 'country_bloc.dart';

abstract class CountryEvent extends Equatable {
  const CountryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCountries extends CountryEvent {}

class SelectCountry extends CountryEvent {
  final Country? country;

  const SelectCountry(this.country);

  @override
  List<Object?> get props => [country];
}