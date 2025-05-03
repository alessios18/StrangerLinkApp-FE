import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stranger_link_app/models/profile.dart';
import 'package:stranger_link_app/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(ProfileInitial()) {
    on<FetchProfile>(_onFetchProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateProfileImage>(_onUpdateProfileImage);
    on<AddInterest>(_onAddInterest);
    on<RemoveInterest>(_onRemoveInterest);
  }

  Future<void> _onFetchProfile(FetchProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final profile = await _profileRepository.getCurrentUserProfile();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final updatedProfile = await _profileRepository.updateProfile(event.profile);
      emit(ProfileUpdated(updatedProfile));
      emit(ProfileLoaded(updatedProfile));
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
      // Reload current profile
      add(FetchProfile());
    }
  }

  Future<void> _onUpdateProfileImage(UpdateProfileImage event, Emitter<ProfileState> emit) async {
    // Get current state to keep the current profile
    final currentState = state;

    try {
      emit(ProfileLoading());

      final imageUrl = await _profileRepository.uploadProfileImage(event.imageFile);
      emit(ProfileImageUpdated(imageUrl));

      // Update the profile with the new image URL
      if (currentState is ProfileLoaded) {
        final updatedProfile = currentState.profile.copyWith(
          profileImageUrl: imageUrl,
        );
        emit(ProfileLoaded(updatedProfile));
      } else {
        // Reload the profile
        add(FetchProfile());
      }
    } catch (e) {
      emit(ProfileError('Failed to upload image: ${e.toString()}'));
      // Reload profile
      if (currentState is ProfileLoaded) {
        emit(currentState);
      } else {
        add(FetchProfile());
      }
    }
  }

  Future<void> _onAddInterest(AddInterest event, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final currentInterests = List<String>.from(currentState.profile.interests ?? []);
      if (!currentInterests.contains(event.interest)) {
        currentInterests.add(event.interest);

        final updatedProfile = currentState.profile.copyWith(
          interests: currentInterests,
        );

        add(UpdateProfile(profile: updatedProfile));
      }
    }
  }

  Future<void> _onRemoveInterest(RemoveInterest event, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      final currentInterests = List<String>.from(currentState.profile.interests ?? []);
      if (currentInterests.contains(event.interest)) {
        currentInterests.remove(event.interest);

        final updatedProfile = currentState.profile.copyWith(
          interests: currentInterests,
        );

        add(UpdateProfile(profile: updatedProfile));
      }
    }
  }
}
