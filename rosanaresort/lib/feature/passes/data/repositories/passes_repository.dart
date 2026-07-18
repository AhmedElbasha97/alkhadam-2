import 'dart:io';
import 'package:flutter/material.dart';

import '../datasources/passes_remote_datasource.dart';
import '../models/pass_model.dart';
import '../models/finance_model.dart';

class PassesRepository {
  final PassesRemoteDataSource dataSource;


  PassesRepository({required this.dataSource});

  Future<List<PassModel>> getPasses(String unId) =>
      dataSource.getPasses(unId);
  Future<bool?> getSecurityChecker() =>
      dataSource.secuiretyChecker();

  Future<Map<String, dynamic>> getTodayPassesCount(String unId) =>
      dataSource.getTodayPassesCount(unId);

  Future<FinanceModel> checkFinance(String unId) =>
      dataSource.checkFinance(unId);

  Future<void> storePass({
    required String unId,
    required String name,
    String? notes,
    required double firstLat,
    required double firstLng,
    required double userLat,
    required double userLng,
    required File image,
  }) =>
      dataSource.storePass(
        unId: unId,
        name: name,
        notes: notes,
        firstLat: firstLat,
        firstLng: firstLng,
        userLat: userLat,
        userLng: userLng,
        image: image,
      );
}
