import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rosanaresort/config/routes/routes_manager.dart';

// Ensure these paths align with your directory architecture
import '../cache/cache_consumer.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../theme/colors/app_color.dart';

import 'api_consumer.dart';
import 'app_interceptor.dart';
import 'status_code.dart';

class DioConsumer implements ApiConsumer {
  final Dio dio;
  late CancelToken cancelToken;
  final CacheConsumer _cache;

  DioConsumer({
    required this.dio,
    required String baseUrl,
    required CacheConsumer cache,
  }) : _cache = cache {
    dio.options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    );

    dio.interceptors.add(AppInterceptors(cache: cache));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
      assert(() {
        dio.interceptors.add(
          PrettyDioLogger(
            requestBody: true,
            requestHeader: true,
            responseBody: true,
            responseHeader: false,
          ),
        );
        return true;
      }());
    }
  }

  // ─── BULLETPROOF ROUTE-BASED ALERT DIALOG ────────────────────────────────
  void _showGlobalErrorAlert(String message) {
    final navState = RoutesManager.navigatorKey.currentState;
    if (navState == null) {
      debugPrint("Global Alert Error: Navigator state is uninitialized.");
      return;
    }

    // Pushing a translucent PageRoute avoids all 'No Overlay found' issues entirely
    navState.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.55), // Dim the background screen
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message);

          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              backgroundColor: AppColor.darkBlueColor,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColor.errorColor.withOpacity(0.4), width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColor.errorColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.gpp_bad_rounded, color: AppColor.errorColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isArabic ? "تنبيه" : "Alert",
                    style: const TextStyle(
                      color: AppColor.whiteTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                message,
                style: TextStyle(
                  color: AppColor.whiteTextColor.withOpacity(0.85),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.errorColor,
                      foregroundColor: AppColor.whiteTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isArabic ? "موافق" : "OK",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── ERROR EXTRACTION ──────────────────────────────────────────────────────
  String _extractMessage(DioException error, [String fallback = 'Server error']) {
    final data = error.response?.data;
    if (data is String) return data;

    if (data is Map) {
      // Direct catch for your specific backend response structure: data['message']
      final msg = data['message'] ?? data['msg'] ?? data['error'];

      if (msg != null) {
        if (msg is Map) {
          final map = Map<String, dynamic>.from(msg);
          final ar = map['ar'] ?? map['AR'];
          final en = map['en'] ?? map['EN'];
          if (ar != null && '$ar'.trim().isNotEmpty) return '$ar';
          if (en != null && '$en'.trim().isNotEmpty) return '$en';
        }
        return msg.toString();
      }

      final details = data['details'];
      if (details is List && details.isNotEmpty) {
        final lines = <String>[];
        for (final e in details) {
          if (e is Map) {
            final f = e['field'] ?? e['path'];
            final m = e['message'] ?? e['msg'];
            if (f != null || m != null) lines.add('${f ?? ''}: ${m ?? ''}'.trim());
          }
        }
        if (lines.isNotEmpty) return lines.join('\n');
      }
      return data.toString();
    }
    return fallback;
  }

  Never _handelDioError(DioException error) {
    String errorMessage = _extractMessage(error, 'Unexpected error occurred');

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection Timeout. Please check your internet.';
    } else if (error.error is SocketException) {
      errorMessage = 'No Internet Connection.';
    } else if (error.type == DioExceptionType.cancel) {
      errorMessage = 'Request Canceled.';
    }

    // Fire the dialog immediately for explicit error codes or connection drops
    if (error.type != DioExceptionType.cancel) {
      _showGlobalErrorAlert(errorMessage);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const FetchDataException();

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status >= 500 && status < 600) {
          throw InternalServerErrorException(errorMessage);
        }
        switch (status) {
          case StatusCode.badRequest:
            throw BadRequestException(errorMessage);
          case StatusCode.unauthorized:
          case StatusCode.forbidden: // Catches your 403 response cleanly
            throw UnauthorizedException(errorMessage);
          case StatusCode.notFound:
            throw NotFoundException(errorMessage);
          case StatusCode.conflict:
            throw const ConflictException();
          default:
            throw ServerException(errorMessage);
        }

      case DioExceptionType.cancel:
        throw const ServerException('Canceled');

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          throw const NoInternetConnectionException();
        }
        throw ServerException(errorMessage);

      default:
        throw ServerException(error.message ?? 'Unknown Dio error');
    }
  }

  // ─── IMPLEMENTED CONTRACT INTERFACES ───────────────────────────────────────
  @override
  Future<Response> getData({required String url, Map<String, dynamic>? query, Map<String, dynamic>? headers}) async {
    try {
      cancelToken = CancelToken();
      _attachApiKey(query);
      return await dio.get(url, queryParameters: query, options: headers == null ? null : Options(headers: headers), cancelToken: cancelToken);
    } on DioException catch (e) { _handelDioError(e); } on Exception catch (e) { _showGlobalErrorAlert(e.toString()); throw ServerException(e.toString()); }
  }

  @override
  Future<Response> postData({required String url, Map<String, dynamic>? query, Map<String, dynamic>? headers, Duration? connectTimeout, Duration? sendTimeout, Duration? receiveTimeout, required dynamic data}) async {
    try {
      cancelToken = CancelToken();
      _attachApiKey(query);
      return await dio.post(url, queryParameters: query, data: data, options: Options(headers: headers, connectTimeout: connectTimeout, sendTimeout: sendTimeout, receiveTimeout: receiveTimeout), cancelToken: cancelToken);
    } on DioException catch (e) { _handelDioError(e); } on Exception catch (e) { _showGlobalErrorAlert(e.toString()); throw ServerException(e.toString()); }
  }

  @override
  Future<Response> putData({required String url, Map<String, dynamic>? query, Map<String, dynamic>? headers, required Map<String, dynamic> data}) async {
    try {
      cancelToken = CancelToken();
      _attachApiKey(query);
      return await dio.put(url, queryParameters: query, data: data, options: headers == null ? null : Options(headers: headers), cancelToken: cancelToken);
    } on DioException catch (e) { _handelDioError(e); } on Exception catch (e) { _showGlobalErrorAlert(e.toString()); throw ServerException(e.toString()); }
  }

  @override
  Future<Response> patchData({required String url, Map<String, dynamic>? headers, required Map<String, dynamic> data}) async {
    try {
      cancelToken = CancelToken();
      Map<String, dynamic>? query;
      _attachApiKey(query);
      return await dio.patch(url, data: data, queryParameters: query, options: headers == null ? null : Options(headers: headers), cancelToken: cancelToken);
    } on DioException catch (e) { _handelDioError(e); } on Exception catch (e) { _showGlobalErrorAlert(e.toString()); throw ServerException(e.toString()); }
  }

  @override
  Future<Response> deleteData({required String url, Map<String, dynamic>? headers, Map<String, dynamic>? data}) async {
    try {
      cancelToken = CancelToken();
      return await dio.delete(url, data: data, options: headers == null ? null : Options(headers: headers), cancelToken: cancelToken);
    } on DioException catch (e) { _handelDioError(e); } on Exception catch (e) { _showGlobalErrorAlert(e.toString()); throw ServerException(e.toString()); }
  }

  void _attachApiKey(Map<String, dynamic>? query) {
    final apiKey = dotenv.env[StringsManager.apiKeyEnvKey];
    if (apiKey != null && apiKey.isNotEmpty) {
      if (query != null) { query.addAll({'api_key': apiKey}); } else { query = {'api_key': apiKey}; }
    }
  }

  @override
  void cancelRequest() { if (!cancelToken.isCancelled) cancelToken.cancel(); }
}