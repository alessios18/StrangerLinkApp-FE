import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stranger_link_app/blocs/auth/auth_bloc.dart';
import 'package:stranger_link_app/blocs/country/country_bloc.dart';
import 'package:stranger_link_app/blocs/profile/profile_bloc.dart';
import 'package:stranger_link_app/blocs/profile_form/profile_form_bloc.dart';
import 'package:stranger_link_app/blocs/search_preference/search_preference_bloc.dart';
import 'package:stranger_link_app/models/country.dart';
import 'package:stranger_link_app/models/profile.dart';

class ProfileScreen extends StatelessWidget {
  final String? errorMessage;
  final ImagePicker _picker = ImagePicker();

  ProfileScreen({Key? key, this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mostro error message se fornito
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!)),
        );
      });
    }

    // Verifica se è un nuovo utente e imposta automaticamente la modalità edit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        final isNewRegistration = DateTime.now().difference(user.createdAt).inMinutes < 5;

        // Controlliamo se già abbiamo lo stato del form caricato
        final formState = context.read<ProfileFormBloc>().state;
        if (formState is ProfileFormInitial) {
          // Carichiamo il profilo prima di inizializzare il form
          if (isNewRegistration) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Benvenuto! Completa il tuo profilo per iniziare.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Profilo'),
      actions: [
        BlocBuilder<ProfileFormBloc, ProfileFormState>(
          builder: (context, state) {
            final isEditing = state is ProfileFormLoaded ? state.isEditing : false;

            return IconButton(
              icon: Icon(isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                if (isEditing) {
                  // Se si annulla la modifica, ricarica il profilo
                  context.read<ProfileBloc>().add(FetchProfile());
                  context.read<ProfileFormBloc>().add(const ToggleEditMode(false));
                } else {
                  // Attiva la modalità modifica
                  context.read<ProfileFormBloc>().add(const ToggleEditMode(true));
                }
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
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
          context.read<ProfileFormBloc>().add(const ToggleEditMode(false));
        } else if (state is ProfileImageUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Immagine profilo aggiornata')),
          );
        } else if (state is ProfileLoaded) {
          // Inizializza il form bloc con i dati del profilo
          final authState = context.read<AuthBloc>().state;
          bool isNewUser = false;

          if (authState is AuthAuthenticated) {
            isNewUser = DateTime.now().difference(authState.user.createdAt).inMinutes < 5;
          }

          context.read<ProfileFormBloc>().add(InitializeForm(state.profile, isNewUser: isNewUser));
        }
      },
      builder: (context, profileState) {
        if (profileState is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<ProfileFormBloc, ProfileFormState>(
          builder: (context, formState) {
            if (formState is ProfileFormInitial) {
              if (profileState is ProfileLoaded) {
                // Se abbiamo il profilo ma il form non è inizializzato
                context.read<ProfileFormBloc>().add(InitializeForm(profileState.profile));
              }
              return const Center(child: CircularProgressIndicator());
            }

            if (formState is ProfileFormLoaded) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Sezione profilo utente
                    formState.isEditing
                        ? _buildProfileForm(context, formState)
                        : _buildProfileView(context, formState.profile),

                    // Separatore
                    const Divider(height: 32, thickness: 1),

                    // Header della sezione preferenze espandibile
                    _buildPreferencesHeader(context),

                    // Sezione preferenze di ricerca (visibile solo se espansa)
                    if (formState.isPreferencesSectionExpanded)
                      _buildPreferencesSection(context, formState.isEditing),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  Widget _buildProfileForm(BuildContext context, ProfileFormLoaded state) {
    final formBloc = context.read<ProfileFormBloc>();
    final formKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: state.profile.profileImageUrl != null
                          ? NetworkImage(state.profile.profileImageUrl!)
                          : null,
                      child: state.profile.profileImageUrl == null
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

            // Nome Visualizzato
            TextFormField(
              controller: formBloc.displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nome visualizzato',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (_) => formBloc.add(UpdateDisplayName()),
              validator: (value) {
                if (value != null && value.length > 50) {
                  return 'Il nome non può superare i 50 caratteri';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Età
            TextFormField(
              controller: formBloc.ageController,
              decoration: const InputDecoration(
                labelText: 'Età',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => formBloc.add(UpdateAge()),
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

            // Paese
            const Text('Paese:'),
            const SizedBox(height: 8),
            BlocBuilder<CountryBloc, CountryState>(
              builder: (context, countryState) {
                if (countryState is CountriesLoaded) {
                  return DropdownButtonFormField<Country>(
                    value: formBloc.selectedCountry,
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
                      formBloc.add(UpdateCountry(country));
                    },
                  );
                }

                // Carica i paesi se non è stato ancora fatto
                context.read<CountryBloc>().add(LoadCountries());
                return const Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(height: 16),

            // Genere
            DropdownButtonFormField<String>(
              value: formBloc.selectedGender,
              decoration: const InputDecoration(
                labelText: 'Genere',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Uomo')),
                DropdownMenuItem(value: 'Female', child: Text('Donna')),
                DropdownMenuItem(value: 'Non-binary', child: Text('Non binario')),
                DropdownMenuItem(value: 'Prefer not to say', child: Text('Preferisco non specificare')),
              ],
              onChanged: (gender) {
                formBloc.add(UpdateGender(gender));
              },
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: formBloc.bioController,
              decoration: const InputDecoration(
                labelText: 'Biografia',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
              onChanged: (_) => formBloc.add(UpdateBio()),
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'La biografia non può superare i 500 caratteri';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Interessi
            const Text('Interessi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: formBloc.interestController,
                    decoration: const InputDecoration(
                      labelText: 'Aggiungi interesse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.interests),
                    ),
                    onFieldSubmitted: (_) => {
                      // formBloc.add(
                      // AddInterest(formBloc.interestController.text.trim()),)
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => {
                    // formBloc.add(AddInterest(interest: "interest")             ),

                  },
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
              children: formBloc.interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => {
                    // formBloc.add(RemoveInterest(interest)),
                  })
                ;
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, Profile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immagine profilo
          Center(
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
          const SizedBox(height: 24),

          // Dettagli profilo
          _buildInfoTile(
            title: 'Nome visualizzato',
            value: profile.displayName ?? 'Non impostato',
            icon: Icons.person,
          ),
          _buildInfoTile(
            title: 'Età',
            value: profile.age?.toString() ?? 'Non impostato',
            icon: Icons.cake,
          ),
          _buildCountryTile(context, profile),
          _buildInfoTile(
            title: 'Genere',
            value: profile.gender ?? 'Non impostato',
            icon: Icons.people,
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty)
            _buildBioTile(context, profile.bio!),
          if (profile.interests != null && profile.interests!.isNotEmpty)
            _buildInterestsTile(context, profile.interests!),
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

  Widget _buildCountryTile(BuildContext context, Profile profile) {
    return BlocBuilder<CountryBloc, CountryState>(
      builder: (context, countryState) {
        String countryName = profile.country?.id != null
            ? 'ID paese: ${profile.country?.id}'
            : 'Non impostato';

        if (profile.country?.id != null && countryState is CountriesLoaded) {
          try {
            final country = countryState.countries.firstWhere(
                  (country) => country.id == profile.country?.id,
            );
            countryName = country.name;
          } catch (e) {
            // Se il paese non viene trovato
          }
        }

        return _buildInfoTile(
          title: 'Paese',
          value: countryName,
          icon: Icons.location_on,
        );
      },
    );
  }

  Widget _buildBioTile(BuildContext context, String bio) {
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

  Widget _buildInterestsTile(BuildContext context, List<String> interests) {
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

  Widget _buildPreferencesHeader(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<ProfileFormBloc>().add(TogglePreferencesSection());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: BlocBuilder<ProfileFormBloc, ProfileFormState>(
          buildWhen: (previous, current) {
            if (previous is ProfileFormLoaded && current is ProfileFormLoaded) {
              return previous.isPreferencesSectionExpanded != current.isPreferencesSectionExpanded;
            }
            return false;
          },
          builder: (context, state) {
            final isExpanded = state is ProfileFormLoaded ? state.isPreferencesSectionExpanded : false;

            return Row(
              children: [
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                const SizedBox(width: 8),
                const Text(
                  'Preferenze di Ricerca',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, bool isEditing) {
    return BlocBuilder<SearchPreferenceBloc, SearchPreferenceState>(
      builder: (context, state) {
        if (state is SearchPreferenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SearchPreferencesLoaded) {
          return _buildSearchPreferencesContent(context, state, isEditing);
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
    );
  }

  Widget _buildSearchPreferencesContent(
      BuildContext context,
      SearchPreferencesLoaded state,
      bool isEditing
      ) {
    if (isEditing) {
      return _buildEditablePreferences(context, state);
    } else {
      return _buildPreferencesView(context, state);
    }
  }

  Widget _buildEditablePreferences(BuildContext context, SearchPreferencesLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    try {
                      selectedCountry = countryState.countries.firstWhere(
                            (country) => country.id == state.preferences.preferredCountryId,
                      );
                    } catch (e) {
                      // Paese non trovato
                    }
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
        ],
      ),
    );
  }

  Widget _buildPreferencesView(BuildContext context, SearchPreferencesLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                try {
                  final country = countryState.countries.firstWhere(
                        (c) => c.id == state.preferences.preferredCountryId,
                  );
                  countryName = country.name;
                } catch (e) {
                  countryName = 'ID paese: ${state.preferences.preferredCountryId}';
                }
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
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<ProfileFormBloc, ProfileFormState>(
      buildWhen: (previous, current) {
        if (previous is ProfileFormLoaded && current is ProfileFormLoaded) {
          return previous.isEditing != current.isEditing;
        }
        return false;
      },
      builder: (context, state) {
        final isEditing = state is ProfileFormLoaded ? state.isEditing : false;

        return isEditing ? FloatingActionButton(
          onPressed: () {
            final formBloc = context.read<ProfileFormBloc>();
            final profile = formBloc.currentProfile;

            // Salva il profilo
            context.read<ProfileBloc>().add(UpdateProfile(profile: profile));

            // Salva anche le preferenze di ricerca
            context.read<SearchPreferenceBloc>().add(SaveSearchPreferences());
          },
          child: const Icon(Icons.save),
        ) : const SizedBox.shrink();
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageFile = File(image.path);

      // Aggiorna l'immagine profilo nel bloc del form
      context.read<ProfileFormBloc>().add(SetProfileImage(image.path));

      // Upload immagine profilo attraverso il ProfileBloc
      context.read<ProfileBloc>().add(UpdateProfileImage(imageFile: imageFile));
    }
  }
}