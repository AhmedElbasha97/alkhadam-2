
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api/api_consumer.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/dependencies/app_dependencies.dart';
import '../../../core/widgets/toast_widget.dart';
import '../models/sign_in_model.dart';
import '../otp/otp_model.dart';

class AuthServices {
  final ApiConsumer _api;

  AuthServices(this._api);

  Future<SignInModel?> signingIn(
      String nationalId,
      String phoneNumber,
      Position firstLocation,
      Position userLocation,
      BuildContext context
      ) async {
    try {
      final response = await _api.postData(url: EndPoints.signingIn, data: {
        "un_nath_id": nationalId,
        "un_phone": phoneNumber,
        "first_lat":firstLocation.latitude,
        "first_lng":firstLocation.longitude,
        "user_lat": userLocation.latitude,
        "user_lng": userLocation.longitude
      });
      return SignInModel.fromJson(response.data);
    } catch(e){
      AppToast.error(context, e.toString());
      return null;
    }
  }
  Future<bool?> secuiretyChecker(
      BuildContext context
      ) async {
    try {
      final response = await _api.postData(url: EndPoints.securityCheck, data: {

      });
      final status = response.data['status'];
      return status == "true";
    } catch(e){
      AppToast.error(context, e.toString());
      return null;
    }
  }

  Future<String?> resendSigningUpOtp(String email) async {

    try {
      final response = await _api.postData(url: EndPoints.resendSigningUpOTP, data: {
        "email": email,
      });
      return response.data["message"];
    } catch(e){
      debugPrint(e.toString());
      return null;
    }
  }
  Future<OtpModel?> verifyResetPassOTP(String email,String otp,      Position userLocation,
      ) async {
    try {
      final response = await _api.postData(url: EndPoints.verifyResetPassOTP, data: {
        "un_phone": email,
        "otp_code": otp,
        "user_lat": userLocation.latitude,
        "user_lng": userLocation.longitude
      });
      return OtpModel.fromJson(response.data);
    } catch(e){
      debugPrint(e.toString());
      return null;
    }
  }
  Future<List<String?>?> verifyResetPass(String email,String otp,String password) async {
    try {
      final response = await _api.postData(url: EndPoints.verifyResetPass, data: {
        "email": email,
        "otp":otp,
        "password":password
      });
      return [response.data["status"],response.data["message"]];
    } catch(e){
      debugPrint(e.toString());
      return null;
    }
  }
  
}