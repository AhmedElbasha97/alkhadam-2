// To parse this JSON data, do
//
//     final otpModel = otpModelFromJson(jsonString);

import 'dart:convert';

OtpModel otpModelFromJson(String str) => OtpModel.fromJson(json.decode(str));

String otpModelToJson(OtpModel data) => json.encode(data.toJson());

class OtpModel {
  String? status;
  String? message;
  Unit? unit;

  OtpModel({
    this.status,
    this.message,
    this.unit,
  });

  factory OtpModel.fromJson(Map<String, dynamic> json) => OtpModel(
    status: json["status"],
    message: json["message"],
    unit: json["unit"] == null ? null : Unit.fromJson(json["unit"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "unit": unit?.toJson(),
  };
}

class Unit {
  String? unId;
  String? unTitle;
  String? unOwner;
  String? unPhone;

  Unit({
    this.unId,
    this.unTitle,
    this.unOwner,
    this.unPhone,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    unId: json["un_id"],
    unTitle: json["un_title"],
    unOwner: json["un_owner"],
    unPhone: json["un_phone"],
  );

  Map<String, dynamic> toJson() => {
    "un_id": unId,
    "un_title": unTitle,
    "un_owner": unOwner,
    "un_phone": unPhone,
  };
}
