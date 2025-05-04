part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final User user;
  final bool isNewRegistration;

  const RegisterSuccess({
    required this.user,
    this.isNewRegistration = true
  });

  @override
  List<Object?> get props => [user, isNewRegistration];
}

class RegisterFailure extends RegisterState {
  final String error;

  const RegisterFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Stati specifici per errori comuni
class UsernameAlreadyExists extends RegisterState {
  const UsernameAlreadyExists();
}

class EmailAlreadyExists extends RegisterState {
  const EmailAlreadyExists();
}

class TermsAndConditionsAccepted extends RegisterState {
  final bool accepted;

  const TermsAndConditionsAccepted({required this.accepted});

  @override
  List<Object?> get props => [accepted];
}