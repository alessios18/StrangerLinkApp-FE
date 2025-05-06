import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart';
import 'package:stranger_link_app/blocs/country/country_bloc.dart';
import 'package:stranger_link_app/blocs/profile/profile_bloc.dart';
import 'package:stranger_link_app/blocs/profile_form/profile_form_bloc.dart';
import 'package:stranger_link_app/blocs/registration/register_bloc.dart';
import 'package:stranger_link_app/blocs/search_preference/search_preference_bloc.dart';
import 'package:stranger_link_app/repositories/chat_repository.dart';
import 'package:stranger_link_app/repositories/country_repository.dart';
import 'package:stranger_link_app/repositories/profile_repository.dart';
import 'package:stranger_link_app/repositories/search_preference_repository.dart';
import 'package:stranger_link_app/repositories/user_repository.dart';
import 'package:stranger_link_app/screens/login/login_screen.dart';
import 'package:stranger_link_app/screens/main/main_screen.dart';
import 'package:stranger_link_app/screens/registration/registration_screen.dart';
import 'blocs/auth/auth_bloc.dart';
import 'repositories/auth_repository.dart';
import 'screens/profile/profile_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(),
        ),
        RepositoryProvider<CountryRepository>(
          create: (context) => CountryRepository(),
        ),
        RepositoryProvider<SearchPreferenceRepository>(
          create: (context) => SearchPreferenceRepository(),
        ),
        RepositoryProvider<ChatRepository>(
          create: (context) => ChatRepository(),
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => UserRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(AppStarted()),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider<RegisterBloc>(
            create: (context) => RegisterBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<CountryBloc>(
            create: (context) => CountryBloc(
              countryRepository: context.read<CountryRepository>(),
            )..add(LoadCountries()),
          ),
          BlocProvider<SearchPreferenceBloc>(
            create: (context) => SearchPreferenceBloc(
              searchPreferenceRepository: context.read<SearchPreferenceRepository>(),
            ),
          ),
          BlocProvider<ChatBloc>(
            create: (context) => ChatBloc(
              chatRepository: context.read<ChatRepository>(),
            ),
          ),
          BlocProvider<ProfileFormBloc>(
            create: (context) => ProfileFormBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'Stranger Link App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/profile': (context) => ProfileScreen(),
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state) {
          case AuthLoading():
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );

          case AuthAuthenticated():
            final user = state.user;
            // Check if user is new registration
            final isNewRegistration = DateTime.now().difference(user.createdAt).inMinutes < 5;

            // Always connect to WebSocket when authenticated
            final chatRepository = context.read<ChatRepository>();
            if (!chatRepository.isConnected) {
              chatRepository.connect(state.user.id);
            }

            // If new user, load profile with edit mode
            if (isNewRegistration) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ProfileBloc>().add(FetchProfile());
                context.read<ProfileBloc>().add(const SetEditMode(isEditing: true));
              });
              return ProfileScreen();
            } else {
              // Load profile data in background
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ProfileBloc>().add(FetchProfile());
              });
              // Return main screen with navigation
              return const MainScreen();
            }

          case AuthUnauthenticated():
            context.read<ChatRepository>().disconnect();
            return const LoginScreen();

          case AuthFailure():
            return LoginScreen(errorMessage: state.error);

          default:
            context.read<ChatRepository>().disconnect();
            return const LoginScreen();
        }
      },
    );
  }
}