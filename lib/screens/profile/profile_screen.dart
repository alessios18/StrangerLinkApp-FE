import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

  String? _selectedGender;
  File? _profileImage;
  final List<String> _interests = [];

  final ImagePicker _picker = ImagePicker();

  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final List<String> _countrySuggestions = [
    'Italy', 'United States', 'United Kingdom', 'Canada', 'Australia',
    'Germany', 'France', 'Spain', 'Brazil', 'Japan', 'China', 'India'
  ];

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(FetchProfile());

    // Show error message if provided
    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.errorMessage!)),
        );
      });
    }
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
      // Upload the image
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
        country: _countryController.text,
        gender: _selectedGender,
        bio: _bioController.text,
        interests: _interests,
      );

      context.read<ProfileBloc>().add(UpdateProfile(profile: profile));

      setState(() {
        _isEditing = false;
      });
    }
  }

  void _populateForm(Profile profile) {
    _displayNameController.text = profile.displayName ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _countryController.text = profile.country ?? '';
    _selectedGender = profile.gender;
    _bioController.text = profile.bio ?? '';

    setState(() {
      _interests.clear();
      if (profile.interests != null) {
        _interests.addAll(profile.interests!);
      }
    });
  }

  void _logout() {
    context.read<AuthBloc>().add(LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Reset form if canceling edit
                  context.read<ProfileBloc>().add(FetchProfile());
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            // Populate form when profile is loaded
            if (_displayNameController.text.isEmpty || !_isEditing) {
              _populateForm(state.profile);
            }

            return _isEditing
                ? _buildProfileForm(context, state.profile)
                : _buildProfileView(context, state.profile);
          } else if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(FetchProfile()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: _isEditing ? FloatingActionButton(
        onPressed: _updateProfile,
        child: const Icon(Icons.save),
      ) : null,
    );
  }

  Widget _buildProfileView(BuildContext context, Profile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: profile.profileImageUrl != null
                        ? NetworkImage(profile.profileImageUrl!)
                        : null,
                    child: profile.profileImageUrl == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  if (_isEditing)
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
          const SizedBox(height: 24),

          // Display name
          _buildInfoTile(
            title: 'Display Name',
            value: profile.displayName ?? 'Not set',
            icon: Icons.person,
          ),

          // Age
          _buildInfoTile(
            title: 'Age',
            value: profile.age?.toString() ?? 'Not set',
            icon: Icons.cake,
          ),

          // Country
          _buildInfoTile(
            title: 'Country',
            value: profile.country ?? 'Not set',
            icon: Icons.location_on,
          ),

          // Gender
          _buildInfoTile(
            title: 'Gender',
            value: profile.gender ?? 'Not set',
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
                  'Bio',
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
                  'Interests',
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
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value != null && value.length > 50) {
                  return 'Display name cannot exceed 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
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
                  return 'Please enter a valid number';
                }
                if (age < 18) {
                  return 'Age must be at least 18';
                }
                if (age > 120) {
                  return 'Age must be less than 120';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const [];
                }
                return _countrySuggestions.where((country) =>
                    country.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _countryController.text = selection;
              },
              fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController controller,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                  ) {
                // Sync the autocomplete controller with our stored controller
                if (controller.text != _countryController.text) {
                  controller.text = _countryController.text;
                }

                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (value) => _countryController.text = value,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
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
                labelText: 'Bio',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Bio cannot exceed 500 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Interests
            const Text('Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      labelText: 'Add interest',
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

            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}