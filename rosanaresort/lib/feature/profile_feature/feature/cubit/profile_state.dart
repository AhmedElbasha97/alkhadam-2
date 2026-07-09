
import '../../model/user_model.dart';

abstract class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UnitDetailsModel unitDetails;

  final bool isDeletingAccount;

  final bool isLoggingOut;

  ProfileLoaded(
      this.unitDetails, {
        this.isDeletingAccount = false,
        this.isLoggingOut = false,
      });

  ProfileLoaded copyWith({
    bool? isDeletingAccount,
    bool? isLoggingOut,
  }) {
    return ProfileLoaded(
      unitDetails,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    );
  }
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}


class ProfileSessionEnded extends ProfileState {
  final bool wasAccountDeleted;
  ProfileSessionEnded({required this.wasAccountDeleted});
}

class ProfileActionFailed extends ProfileState {
  final UnitDetailsModel unitDetails;
  final String message;
  ProfileActionFailed(this.unitDetails, this.message);
}