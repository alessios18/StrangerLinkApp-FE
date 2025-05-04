import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stranger_link_app/models/user.dart';
import 'package:stranger_link_app/repositories/auth_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<TermsAccepted>(_onTermsAccepted);
  }

  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event,
      Emitter<RegisterState> emit,
      ) async {
    emit(RegisterLoading());
    try {
      final user = await _authRepository.register(
        event.username,
        event.email,
        event.password,
      );

      if (user != null) {
        // Aggiorna lo stato con isNewRegistration = true
        emit(RegisterSuccess(user: user, isNewRegistration: true));
      } else {
        emit(const RegisterFailure('Registrazione fallita. Riprova.'));
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Gestisci gli errori specifici
      if (errorMessage.contains('Username already taken')) {
        emit(const UsernameAlreadyExists());
      } else if (errorMessage.contains('Email already in use')) {
        emit(const EmailAlreadyExists());
      } else {
        emit(RegisterFailure('Errore durante la registrazione: $errorMessage'));
      }
    }
  }

  void _onTermsAccepted(
      TermsAccepted event,
      Emitter<RegisterState> emit,
      ) {
    emit(TermsAndConditionsAccepted(accepted: event.accepted));
  }
}