// part 'profile_form_event.dart'
part of 'profile_form_bloc.dart';

abstract class ProfileFormEvent extends Equatable {
  const ProfileFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeForm extends ProfileFormEvent {
  final Profile profile;
  final bool isNewUser;

  const InitializeForm(this.profile, {this.isNewUser = false});

  @override
  List<Object?> get props => [profile, isNewUser];
}

class ToggleEditMode extends ProfileFormEvent {
  final bool isEditing;

  const ToggleEditMode(this.isEditing);

  @override
  List<Object?> get props => [isEditing];
}

class TogglePreferencesSection extends ProfileFormEvent {}

class UpdateDisplayName extends ProfileFormEvent {}

class UpdateAge extends ProfileFormEvent {}

class UpdateCountry extends ProfileFormEvent {
  final Country? country;

  const UpdateCountry(this.country);

  @override
  List<Object?> get props => [country];
}

class UpdateGender extends ProfileFormEvent {
  final String? gender;

  const UpdateGender(this.gender);

  @override
  List<Object?> get props => [gender];
}

class UpdateBio extends ProfileFormEvent {}

class AddInterest extends ProfileFormEvent {
  final String interest;

  const AddInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}

class RemoveInterest extends ProfileFormEvent {
  final String interest;

  const RemoveInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}

class SetProfileImage extends ProfileFormEvent {
  final String? imagePath;

  const SetProfileImage(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}