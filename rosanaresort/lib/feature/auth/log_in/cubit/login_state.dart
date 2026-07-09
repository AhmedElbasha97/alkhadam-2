part of 'login_cubit.dart';

enum AuthStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final AuthStatus status;
  final bool obscurePassword;
  final String? errorMessage;

  const LoginState({
    this.status = AuthStatus.initial,
    this.obscurePassword = true,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isSuccess => status == AuthStatus.success;
  bool get isFailure => status == AuthStatus.failure;

  LoginState copyWith({
    AuthStatus? status,
    bool? obscurePassword,
    String? errorMessage,
  }) =>
      LoginState(
        status: status ?? this.status,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, obscurePassword, errorMessage];
}
