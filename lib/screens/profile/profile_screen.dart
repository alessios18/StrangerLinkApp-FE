import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stranger_link_app/blocs/country/country_bloc.dart';
import 'package:stranger_link_app/blocs/search_preference/search_preference_bloc.dart';
import 'package:stranger_link_app/models/country.dart';
import 'package:stranger_link_app/models/profile.dart';
import 'dart:io';

import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';

class ProfileScreen extends StatefulWidget {
  final String? errorMessage;

  const ProfileScreen({Key? key, this.errorMessage}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestController = TextEditingController();
  final _countryController = TextEditingController();
  Country? _selectedCountry;
  String? _selectedGender;
  File? _profileImage;
  final List<String> _interests = [];
  bool _isPreferencesSectionExpanded = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final List<String> _countrySuggestions = [
    'Italy', 'United States', 'United Kingdom', 'Canada', 'Australia',
    'Germany', 'France', 'Spain', 'Brazil', 'Japan', 'China', 'India'
  ];

  @override
  void initState() {
    super.initState();
    // Carica il profilo
    context.read<ProfileBloc>().add(FetchProfile());

    // Carica le preferenze di ricerca
    context.read<SearchPreferenceBloc>().add(LoadSearchPreferences());

    // Carica i paesi per l'utilizzo nelle selezioni
    context.read<CountryBloc>().add(LoadCountries());

    // Mostra error message se fornito
    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.errorMessage!)),
        );
      });
    }

    // Verifica se è un nuovo utente e imposta automaticamente la modalità edit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        final isNewRegistration = DateTime.now().difference(user.createdAt).inMinutes < 5;

        if (isNewRegistration) {
          context.read<ProfileBloc>().add(const SetEditMode(isEditing: true));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Benvenuto! Completa il tuo profilo per iniziare.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _interestController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      // Upload immagine profilo
      context.read<ProfileBloc>().add(
        UpdateProfileImage(imageFile: _profileImage!),
      );
    }
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      final profile = Profile(
        displayName: _displayNameController.text,
        age: int.tryParse(_ageController.text),
        country: _selectedCountry, // Usa l'oggetto Country completo
        gender: _selectedGender,
        bio: _bioController.text,
        interests: _interests,
      );

      context.read<ProfileBloc>().add(UpdateProfile(profile: profile));
    }
  }

  void _logout() {
    context.read<AuthBloc>().add(LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            buildWhen: (previous, current) {
              if (previous is ProfileLoaded && current is ProfileLoaded) {
                return previous.isEditing != current.isEditing;
              }
              return false;
            },
            builder: (context, state) {
              final isEditing = state is ProfileLoaded ? state.isEditing : false;

              return IconButton(
                icon: Icon(isEditing ? Icons.close : Icons.edit),
                onPressed: () {
                  if (isEditing) {
                    // Se si annulla la modifica, ricarica il profilo
                    context.read<ProfileBloc>().add(FetchProfile());
                  }
                  // Inverte lo stato di modifica
                  context.read<ProfileBloc>().add(SetEditMode(isEditing: !isEditing));
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sezione profilo utente esistente
            BlocConsumer<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is ProfileError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is ProfileUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profilo aggiornato con successo')),
                  );
                  // Dopo l'aggiornamento, disattiva la modalità modifica
                  context.read<ProfileBloc>().add(const SetEditMode(isEditing: false));
                } else if (state is ProfileImageUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Immagine profilo aggiornata')),
                  );
                }
              },
              builder: (context, state) {
                if (state is ProfileLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProfileLoaded) {
                  // Usa un metodo separato per aggiornare i controller senza setState
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _populateFormControllers(state.profile);
                  });

                  return state.isEditing
                      ? _buildProfileForm(context, state.profile)
                      : _buildProfileView(context, state.profile);
                } else if (state is ProfileError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Errore: ${state.message}'),
                        ElevatedButton(
                          onPressed: () => context.read<ProfileBloc>().add(FetchProfile()),
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),

            // Separatore
            const Divider(height: 32, thickness: 1),

            // Header della sezione preferenze espandibile
            InkWell(
              onTap: () {
                setState(() {
                  _isPreferencesSectionExpanded = !_isPreferencesSectionExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                        _isPreferencesSectionExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Preferenze di Ricerca',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sezione preferenze di ricerca (visibile solo se espansa)
            if (_isPreferencesSectionExpanded)
              BlocBuilder<SearchPreferenceBloc, SearchPreferenceState>(
                builder: (context, state) {
                  if (state is SearchPreferenceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SearchPreferencesLoaded) {
                    return _buildSearchPreferencesSection(context, state);
                  }

                  if (state is SearchPreferenceError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Errore: ${state.message}'),
                          ElevatedButton(
                            onPressed: () {
                              context.read<SearchPreferenceBloc>().add(LoadSearchPreferences());
                            },
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Se non è ancora stato caricato
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (previous, current) {
          if (previous is ProfileLoaded && current is ProfileLoaded) {
            return previous.isEditing != current.isEditing;
          }
          return false;
        },
        builder: (context, state) {
          final isEditing = state is ProfileLoaded ? state.isEditing : false;

          return isEditing ? FloatingActionButton(
            onPressed: () {
              // Salva il profilo
              _updateProfile();

              // Salva anche le preferenze di ricerca
              context.read<SearchPreferenceBloc>().add(SaveSearchPreferences());
            },
            child: const Icon(Icons.save),
          ) : const SizedBox.shrink();
        },
      ),
    );
  }

  // Metodo sicuro per aggiornare i controller senza causare setState durante il build
  void _populateFormControllers(Profile profile) {
    if (_displayNameController.text != profile.displayName) {
      _displayNameController.text = profile.displayName ?? '';
    }

    if (_ageController.text != profile.age?.toString()) {
      _ageController.text = profile.age?.toString() ?? '';
    }

    if (_countryController.text != profile.country) {
      _countryController.text = profile.country?.name ?? '';
      _selectedCountry = profile.country;
    }

    if (_selectedGender != profile.gender) {
      _selectedGender = profile.gender;
    }

    if (_bioController.text != profile.bio) {
      _bioController.text = profile.bio ?? '';
    }

    // Aggiorna gli interessi solo se necessario per evitare cicli infiniti
    if (!_areInterestsEqual(_interests, profile.interests)) {
      _interests.clear();
      if (profile.interests != null) {
        _interests.addAll(profile.interests!);
      }
    }
  }

  // Confronta due liste di interessi
  bool _areInterestsEqual(List<String> list1, List<String>? list2) {
    if (list2 == null) return list1.isEmpty;
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }

    return true;
  }

  Widget _buildProfileView(BuildContext context, Profile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: null, // Disabilitato in modalità visualizzazione
              child: CircleAvatar(
                radius: 60,
                backgroundImage: profile.profileImageUrl != null
                    ? NetworkImage(profile.profileImageUrl!)
                    : null,
                child: profile.profileImageUrl == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Display name
          _buildInfoTile(
            title: 'Nome visualizzato',
            value: profile.displayName ?? 'Non impostato',
            icon: Icons.person,
          ),

          // Age
          _buildInfoTile(
            title: 'Età',
            value: profile.age?.toString() ?? 'Non impostato',
            icon: Icons.cake,
          ),

          // Country
          BlocBuilder<CountryBloc, CountryState>(
            builder: (context, countryState) {
              String countryName = profile.country?.id != null
                  ? 'ID paese: ${profile.country?.id}'
                  : 'Non impostato';

              if (profile.country?.id != null && countryState is CountriesLoaded) {
                final country = countryState.countries.firstWhere(
                      (country) => country.id == profile.country?.id,
                );

                if (country != null) {
                  countryName = country.name;
                }
              }

              return _buildInfoTile(
                title: 'Paese',
                value: countryName,
                icon: Icons.location_on,
              );
            },
          ),

          // Gender
          _buildInfoTile(
            title: 'Genere',
            value: profile.gender ?? 'Non impostato',
            icon: Icons.people,
          ),

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty)
            _buildBioTile(profile.bio!),

          // Interests
          if (profile.interests != null && profile.interests!.isNotEmpty)
            _buildInterestsTile(profile.interests!),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile({required String title, required String value, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildBioTile(String bio) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description),
                SizedBox(width: 8),
                Text(
                  'Biografia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(bio),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsTile(List<String> interests) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.interests),
                SizedBox(width: 8),
                Text(
                  'Interessi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildProfileForm(BuildContext context, Profile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (profile.profileImageUrl != null
                          ? NetworkImage(profile.profileImageUrl!)
                          : null) as ImageProvider<Object>?,
                      child: (_profileImage == null && profile.profileImageUrl == null)
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Display Name
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nome visualizzato',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value != null && value.length > 50) {
                  return 'Il nome non può superare i 50 caratteri';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Età',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }
                final age = int.tryParse(value);
                if (age == null) {
                  return 'Inserisci un numero valido';
                }
                if (age < 18) {
                  return 'L\'età deve essere almeno 18';
                }
                if (age > 120) {
                  return 'L\'età deve essere inferiore a 120';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country
            const Text('Paese:'),
            const SizedBox(height: 8),
            BlocBuilder<CountryBloc, CountryState>(
              builder: (context, countryState) {
                if (countryState is CountriesLoaded) {
                  // Trova il paese corrispondente all'ID nel profilo
                  Country? selectedCountry;
                  if (profile.country != null) {
                    selectedCountry = countryState.countries.firstWhere(
                          (country) => country.id == profile.country?.id,
                    );
                  }

                  return DropdownButtonFormField<Country>(
                    value: selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Seleziona paese',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: countryState.countries.map((country) {
                      return DropdownMenuItem<Country>(
                        value: country,
                        child: Text(country.name),
                      );
                    }).toList(),
                    onChanged: (country) {
                      // Salva l'ID del paese selezionato
                      setState(() {
                        _selectedCountry = country;
                      });
                    },
                  );
                }

                // Carica i paesi se non è stato ancora fatto
                context.read<CountryBloc>().add(LoadCountries());
                return const Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Genere',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              items: _genderOptions.map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Biografia',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'La biografia non può superare i 500 caratteri';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Interests
            const Text('Interessi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      labelText: 'Aggiungi interesse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.interests),
                    ),
                    onFieldSubmitted: (_) => _addInterest(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addInterest,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeInterest(interest),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchPreferencesSection(BuildContext context, SearchPreferencesLoaded state) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final isEditing = profileState is ProfileLoaded ? profileState.isEditing : false;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing) ...[
                // Range di età
                const Text('Range di età:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: state.preferences.minAge?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Età minima',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            context.read<SearchPreferenceBloc>().add(
                              SetMinAge(int.parse(value)),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: state.preferences.maxAge?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Età massima',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            context.read<SearchPreferenceBloc>().add(
                              SetMaxAge(int.parse(value)),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Genere preferito
                const Text('Genere preferito:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: state.preferences.preferredGender ?? 'all',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Uomo')),
                    DropdownMenuItem(value: 'female', child: Text('Donna')),
                    DropdownMenuItem(value: 'all', child: Text('Tutti')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SearchPreferenceBloc>().add(
                        SetPreferredGender(value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Selezione paese
                const Text('Paese:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: state.preferences.allCountries,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<SearchPreferenceBloc>().add(
                            SetAllCountries(value),
                          );
                        }
                      },
                    ),
                    const Text('Tutti i paesi'),
                  ],
                ),
                if (!state.preferences.allCountries) ...[
                  const SizedBox(height: 8),
                  BlocBuilder<CountryBloc, CountryState>(
                    builder: (context, countryState) {
                      if (countryState is CountriesLoaded) {
                        // Trova il paese corrispondente all'ID preferito
                        Country? selectedCountry;
                        if (state.preferences.preferredCountryId != null) {
                          selectedCountry = countryState.countries.firstWhere(
                                (country) => country.id == state.preferences.preferredCountryId,
                            );
                        }

                        return DropdownButtonFormField<Country>(
                          value: selectedCountry,
                          decoration: const InputDecoration(
                            labelText: 'Seleziona paese',
                            border: OutlineInputBorder(),
                          ),
                          items: countryState.countries.map((country) {
                            return DropdownMenuItem<Country>(
                              value: country,
                              child: Text(country.name),
                            );
                          }).toList(),
                          onChanged: (country) {
                            if (country != null) {
                              context.read<SearchPreferenceBloc>().add(
                                SetPreferredCountry(country.id),
                              );
                            }
                          },
                        );
                      }

                      // Carica i paesi se non è stato ancora fatto
                      if (countryState is CountryInitial) {
                        context.read<CountryBloc>().add(LoadCountries());
                      }

                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ],
              ] else ...[
                // Modalità visualizzazione (non-editing)
                _buildInfoTile(
                  title: 'Range di età',
                  value: state.preferences.minAge != null && state.preferences.maxAge != null
                      ? '${state.preferences.minAge} - ${state.preferences.maxAge} anni'
                      : 'Non impostato',
                  icon: Icons.person_outline,
                ),

                _buildInfoTile(
                  title: 'Genere preferito',
                  value: state.preferences.preferredGender == 'male'
                      ? 'Uomo'
                      : state.preferences.preferredGender == 'female'
                      ? 'Donna'
                      : 'Tutti',
                  icon: Icons.people_outline,
                ),

                BlocBuilder<CountryBloc, CountryState>(
                  builder: (context, countryState) {
                    String countryName;

                    if (state.preferences.allCountries) {
                      countryName = 'Tutti i paesi';
                    } else if (state.preferences.preferredCountryId != null &&
                        countryState is CountriesLoaded) {
                      // Cerca il paese per ID
                      final country = countryState.countries.firstWhere(
                            (c) => c.id == state.preferences.preferredCountryId,
                      );

                      countryName = country != null
                          ? country.name
                          : 'ID paese: ${state.preferences.preferredCountryId}';
                    } else {
                      countryName = 'Non impostato';
                    }

                    return _buildInfoTile(
                      title: 'Paese preferito',
                      value: countryName,
                      icon: Icons.location_on_outlined,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}