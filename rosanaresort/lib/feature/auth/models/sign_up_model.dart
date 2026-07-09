import 'dart:convert';

class SignUpModel {
  final String? status;
  final String? message;
  final User? user;

  SignUpModel({
    this.status,
    this.message,
    this.user,
  });

  SignUpModel copyWith({
    String? status,
    String? message,
    User? user,
  }) =>
      SignUpModel(
        status: status ?? this.status,
        message: message ?? this.message,
        user: user ?? this.user,
      );

  factory SignUpModel.fromRawJson(String str) => SignUpModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SignUpModel.fromJson(Map<String, dynamic> json) => SignUpModel(
    status: json["status"],
    message: json["message"],
    user: json["user"] == null ? null : User.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "user": user?.toJson(),
  };
}

class User {
  final int? id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? username;

  User({
    this.id,
    this.email,
    this.fullName,
    this.phone,
    this.username,
  });

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phone,
    String? username,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        username: username ?? this.username,
      );

  factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    email: json["email"],
    fullName: json["full_name"],
    phone: json["phone"],
    username: json["username"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "full_name": fullName,
    "phone": phone,
    "username": username,
  };
}
