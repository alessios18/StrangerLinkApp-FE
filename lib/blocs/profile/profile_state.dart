part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile;
  final bool isEditing;

  const ProfileLoaded(this.profile, {this.isEditing = false});

  @override
  List<Object?> get props => [profile, isEditing];

  // Metodo per creare una copia con nuovo stato isEditing
  ProfileLoaded copyWith({Profile? profile, bool? isEditing}) {
    return ProfileLoaded(
      profile ?? this.profile,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class ProfileUpdated extends ProfileState {
  final Profile profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileImageUpdated extends ProfileState {
  final String imageUrl;

  const ProfileImageUpdated(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}


