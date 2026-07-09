import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String title;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.title,
  });

  @override
  List<Object?> get props => [id, fullName, email, phone, title];
}

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterParams extends Equatable {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;

  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props =>
      [fullName, email, phone, password, confirmPassword];
}
