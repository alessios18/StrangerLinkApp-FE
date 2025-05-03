import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';
import '../blocs/profile/profile_state.dart';
import '../models/profile_model.dart';
import '../widgets/interest_chip.dart';
import '../widgets/custom_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(FetchProfile());
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
      final profile = ProfileModel(
        displayName: _displayNameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        country: _countryController.text,
        gender: _selectedGender ?? '',
        bio: _bioController.text,
        interests: _interests,
      );

      context.read<ProfileBloc>().add(UpdateProfile(profile: profile));
    }
  }

  void _populateForm(ProfileModel profile) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Add logout functionality
              // context.read<AuthBloc>().add(LogoutRequested());
              // Navigator.of(context).pushReplacementNamed('/login');
            },
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
            if (_displayNameController.text.isEmpty) {
              _populateForm(state.profile);
            }

            return _buildProfileForm(context, state.profile);
          } else if (state is ProfileError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, ProfileModel profile) {
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
                child: CircleAvatar(
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
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _pickImage,
                child: const Text('Change Profile Picture'),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.length > 50) {
                  return 'Display name cannot exceed 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
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
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
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
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
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
            const Text('Interests', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      labelText: 'Add interest',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addInterest(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addInterest,
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
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeInterest(interest),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}