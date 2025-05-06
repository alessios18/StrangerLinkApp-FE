// lib/screens/search/user_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stranger_link_app/blocs/auth/auth_bloc.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart';
import 'package:stranger_link_app/blocs/country/country_bloc.dart';
import 'package:stranger_link_app/blocs/search_preference/search_preference_bloc.dart';
import 'package:stranger_link_app/models/conversation.dart';
import 'package:stranger_link_app/models/user.dart';
import 'package:stranger_link_app/repositories/user_repository.dart';
import 'package:stranger_link_app/screens/chat/chat_detail_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> with SingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository();
  bool _isMatchingInProgress = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Load search preferences when the screen initializes
    context.read<SearchPreferenceBloc>().add(LoadSearchPreferences());

    // Also make sure countries are loaded for displaying country name
    context.read<CountryBloc>().add(LoadCountries());

    // Setup animation for the search button
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startRandomMatch() async {
    setState(() {
      _isMatchingInProgress = true;
    });

    _animationController.repeat(reverse: true);

    try {
      final User? matchedUser = await _userRepository.getRandomMatch();

      setState(() {
        _isMatchingInProgress = false;
      });

      _animationController.stop();
      _animationController.reset();

      if (matchedUser != null) {
        // Create a conversation with the matched user
        final conversation = Conversation(
          id: 0, // The server will create a real ID
          otherUser: matchedUser,
          unreadCount: 0,
          isOnline: true,
        );

        // Navigate directly to the chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(conversation: conversation),
          ),
        );
      } else {
        // Show "No match found" message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matching users found. Try adjusting your preferences.'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isMatchingInProgress = false;
      });

      _animationController.stop();
      _animationController.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding match: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find People'),
        elevation: 0,
      ),
      body: BlocBuilder<SearchPreferenceBloc, SearchPreferenceState>(
        builder: (context, prefState) {
          if (prefState is SearchPreferenceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prefState is SearchPreferenceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading preferences',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(prefState.message),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<SearchPreferenceBloc>().add(LoadSearchPreferences());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (prefState is SearchPreferencesLoaded) {
            // We also need country data to display country name
            return BlocBuilder<CountryBloc, CountryState>(
                builder: (context, countryState) {
                  // Find country name if needed
                  String countryText = "Any country";

                  if (!prefState.preferences.allCountries &&
                      prefState.preferences.preferredCountryId != null) {
                    if (countryState is CountriesLoaded) {
                      final country = countryState.countries.firstWhere(
                            (c) => c.id == prefState.preferences.preferredCountryId,
                      );

                      if (country != null) {
                        countryText = country.name;
                      } else {
                        countryText = "Unknown country";
                      }
                    } else {
                      countryText = "Loading country...";
                      if (countryState is! CountryLoading) {
                        // If countries aren't being loaded, trigger the load
                        context.read<CountryBloc>().add(LoadCountries());
                      }
                    }
                  }

                  return Stack(
                    children: [
                      // Main content with improved design
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.primaryContainer.withOpacity(0.3),
                              colorScheme.surfaceVariant.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Search Preferences',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Age range
                              PreferenceCard(
                                icon: Icons.calendar_today,
                                title: 'Age Range',
                                value: prefState.preferences.minAge != null &&
                                    prefState.preferences.maxAge != null
                                    ? '${prefState.preferences.minAge} - ${prefState.preferences.maxAge} years'
                                    : 'Any age',
                                colorScheme: colorScheme,
                              ),

                              // Preferred gender
                              PreferenceCard(
                                icon: Icons.people,
                                title: 'Preferred Gender',
                                value: prefState.preferences.preferredGender == 'male'
                                    ? 'Male'
                                    : prefState.preferences.preferredGender == 'female'
                                    ? 'Female'
                                    : 'Any gender',
                                colorScheme: colorScheme,
                              ),

                              // Country preference
                              PreferenceCard(
                                icon: Icons.public,
                                title: 'Country',
                                value: countryText,
                                colorScheme: colorScheme,
                              ),

                              const Spacer(),

                              // Edit preferences button
                              Center(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/profile');
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Preferences'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Start matching button with animation
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: AnimatedBuilder(
                                      animation: _animation,
                                      builder: (context, child) {
                                        return ElevatedButton.icon(
                                          onPressed: _isMatchingInProgress ? null : _startRandomMatch,
                                          icon: _isMatchingInProgress
                                              ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: colorScheme.onPrimary,
                                            ),
                                          )
                                              : const Icon(Icons.search),
                                          label: Text(
                                            _isMatchingInProgress
                                                ? 'Finding Match...'
                                                : 'Start Random Match',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isMatchingInProgress
                                                ? colorScheme.primary.withOpacity(0.7 + (_animation.value * 0.3))
                                                : colorScheme.primary,
                                            foregroundColor: colorScheme.onPrimary,
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(28),
                                            ),
                                          ),
                                        );
                                      }
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Fullscreen overlay for matching progress
                      if (_isMatchingInProgress)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Finding Your Perfect Match',
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Please wait a moment...',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
            );
          }

          return const Center(child: Text('No preferences found'));
        },
      ),
    );
  }
}

// Custom widget for preference cards
class PreferenceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ColorScheme colorScheme;

  const PreferenceCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}