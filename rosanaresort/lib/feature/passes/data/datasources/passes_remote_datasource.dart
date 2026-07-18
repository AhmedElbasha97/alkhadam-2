import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/widgets/toast_widget.dart';
import '../models/pass_model.dart';
import '../models/finance_model.dart';

class PassesRemoteDataSource {
  final ApiConsumer _apiService;

  PassesRemoteDataSource(this._apiService);

  // ─── Get all passes ───────────────────────────────────────────────────────
  Future<List<PassModel>> getPasses(String unId) async {
    final response = await _apiService.postData(
      url:
    EndPoints.getPasses,
      data: {'un_id': unId},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['passes'] as List<dynamic>;
    return list.map((e) => PassModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── Today passes count ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTodayPassesCount(String unId) async {
    final response = await _apiService.postData(url:
    EndPoints.todayPassesCount,
      data: {'un_id': unId},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'today_passes_count': data['today_passes_count'] as int,
      'max_limit': data['max_limit'] as int,
    };
  }

  // ─── Check finance ────────────────────────────────────────────────────────
  Future<FinanceModel> checkFinance(String unId) async {
    final response = await _apiService.postData(
      url:
      EndPoints.checkFinance,
      data: {'un_id': unId},
    );
    return FinanceModel.fromJson(response.data as Map<String, dynamic>);
  }
  Future<bool?> secuiretyChecker(

      ) async {
    try {
      final response = await _apiService.postData(url: EndPoints.securityCheck, data: {

      });
      final status = response.data['status'];
      return status == "true";
    } catch(e){

      return null;
    }
  }

  // ─── Store pass ───────────────────────────────────────────────────────────
  Future<void> storePass({
    required String unId,
    required String name,
    String? notes,
    required double firstLat,
    required double firstLng,
    required double userLat,
    required double userLng,
    required File image,
  }) async {
    final formData = FormData.fromMap({
      'un_id': unId,
      'unp_name': name,
      if (notes != null && notes.isNotEmpty) 'unp_notes': notes,
      'first_lat': firstLat,
      'first_lng': firstLng,
      'user_lat': userLat,
      'user_lng': userLng,
      'unp_img': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
    });

    await _apiService.postData(url:EndPoints.storePass, data: formData);
  }
}
