part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final Profile profile;

  const UpdateProfile({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class UpdateProfileImage extends ProfileEvent {
  final File imageFile;

  const UpdateProfileImage({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

class AddInterest extends ProfileEvent {
  final String interest;

  const AddInterest({required this.interest});

  @override
  List<Object?> get props => [interest];
}

class RemoveInterest extends ProfileEvent {
  final String interest;

  const RemoveInterest({required this.interest});

  @override
  List<Object?> get props => [interest];
}

class SetEditMode extends ProfileEvent {
  final bool isEditing;

  const SetEditMode({required this.isEditing});

  @override
  List<Object?> get props => [isEditing];
}
