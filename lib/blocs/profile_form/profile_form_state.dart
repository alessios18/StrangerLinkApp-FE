// part 'profile_form_state.dart'
part of 'profile_form_bloc.dart';

abstract class ProfileFormState extends Equatable {
  const ProfileFormState();

  @override
  List<Object?> get props => [];
}

class ProfileFormInitial extends ProfileFormState {}

class ProfileFormLoaded extends ProfileFormState {
  final bool isEditing;
  final bool isPreferencesSectionExpanded;
  final Profile profile;

  const ProfileFormLoaded({
    required this.isEditing,
    required this.isPreferencesSectionExpanded,
    required this.profile,
  });

  @override
  List<Object?> get props => [isEditing, isPreferencesSectionExpanded, profile];
}