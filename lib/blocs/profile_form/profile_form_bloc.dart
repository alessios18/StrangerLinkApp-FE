// lib/blocs/profile_form/profile_form_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stranger_link_app/models/country.dart';
import 'package:stranger_link_app/models/profile.dart';

part 'profile_form_event.dart';
part 'profile_form_state.dart';

class ProfileFormBloc extends Bloc<ProfileFormEvent, ProfileFormState> {
  // Controllers per i campi del form
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController interestController = TextEditingController();

  // Valori selezionati che non usano controller di testo
  Country? selectedCountry;
  String? selectedGender;
  List<String> interests = [];

  // Flag di editing e altri stati UI
  bool isEditing = false;
  bool isPreferencesSectionExpanded = false;

  // Profilo attuale
  Profile? _currentProfile;

  ProfileFormBloc() : super(ProfileFormInitial()) {
    on<InitializeForm>(_onInitializeForm);
    on<ToggleEditMode>(_onToggleEditMode);
    on<TogglePreferencesSection>(_onTogglePreferencesSection);
    on<UpdateDisplayName>(_onUpdateDisplayName);
    on<UpdateAge>(_onUpdateAge);
    on<UpdateCountry>(_onUpdateCountry);
    on<UpdateGender>(_onUpdateGender);
    on<UpdateBio>(_onUpdateBio);
    on<AddInterest>(_onAddInterest);
    on<RemoveInterest>(_onRemoveInterest);
    on<SetProfileImage>(_onSetProfileImage);
  }

  void _onInitializeForm(InitializeForm event, Emitter<ProfileFormState> emit) {
    _currentProfile = event.profile;

    // Aggiorna i controller con i valori del profilo
    displayNameController.text = _currentProfile?.displayName ?? '';
    ageController.text = _currentProfile?.age?.toString() ?? '';
    bioController.text = _currentProfile?.bio ?? '';

    // Aggiorna i valori selezionati
    selectedCountry = _currentProfile?.country;
    selectedGender = _currentProfile?.gender;
    interests = _currentProfile?.interests?.toList() ?? [];

    // Se è un nuovo utente, abilita automaticamente la modalità editing
    if (event.isNewUser) {
      isEditing = true;
    }

    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onToggleEditMode(ToggleEditMode event, Emitter<ProfileFormState> emit) {
    isEditing = event.isEditing;

    if (!isEditing) {
      // Se stiamo uscendo dalla modalità modifica, ricaricare i dati dal profilo originale
      displayNameController.text = _currentProfile?.displayName ?? '';
      ageController.text = _currentProfile?.age?.toString() ?? '';
      bioController.text = _currentProfile?.bio ?? '';
      selectedCountry = _currentProfile?.country;
      selectedGender = _currentProfile?.gender;
      interests = _currentProfile?.interests?.toList() ?? [];
    }

    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onTogglePreferencesSection(TogglePreferencesSection event, Emitter<ProfileFormState> emit) {
    isPreferencesSectionExpanded = !isPreferencesSectionExpanded;

    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onUpdateDisplayName(UpdateDisplayName event, Emitter<ProfileFormState> emit) {
    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onUpdateAge(UpdateAge event, Emitter<ProfileFormState> emit) {
    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onUpdateCountry(UpdateCountry event, Emitter<ProfileFormState> emit) {
    selectedCountry = event.country;

    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onUpdateGender(UpdateGender event, Emitter<ProfileFormState> emit) {
    selectedGender = event.gender;

    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onUpdateBio(UpdateBio event, Emitter<ProfileFormState> emit) {
    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onAddInterest(AddInterest event, Emitter<ProfileFormState> emit) {
    if (!interests.contains(event.interest) && event.interest.isNotEmpty) {
      interests.add(event.interest);
      interestController.clear();

      emit(ProfileFormLoaded(
        isEditing: isEditing,
        isPreferencesSectionExpanded: isPreferencesSectionExpanded,
        profile: _buildCurrentProfile(),
      ));
    }
  }

  void _onRemoveInterest(RemoveInterest event, Emitter<ProfileFormState> emit) {
    interests.remove(event.interest);

    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  void _onSetProfileImage(SetProfileImage event, Emitter<ProfileFormState> emit) {
    // Qui gestiremmo solo lo stato locale dell'immagine, non il caricamento effettivo
    // che sarebbe gestito dal ProfileBloc

    emit(ProfileFormLoaded(
      isEditing: isEditing,
      isPreferencesSectionExpanded: isPreferencesSectionExpanded,
      profile: _buildCurrentProfile(),
    ));
  }

  // Costruisce un profilo dai valori correnti nei controller
  Profile _buildCurrentProfile() {
    return Profile(
      displayName: displayNameController.text,
      age: int.tryParse(ageController.text),
      country: selectedCountry,
      gender: selectedGender,
      bio: bioController.text.isNotEmpty ? bioController.text : null,
      interests: interests.isNotEmpty ? interests : null,
      profileImageUrl: _currentProfile?.profileImageUrl,
    );
  }

  // Getter per ottenere il profilo corrente
  Profile get currentProfile => _buildCurrentProfile();

  @override
  Future<void> close() {
    // Importante: rilasciare i controller quando il bloc viene chiuso
    displayNameController.dispose();
    ageController.dispose();
    bioController.dispose();
    interestController.dispose();
    return super.close();
  }
}