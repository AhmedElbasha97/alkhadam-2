import 'dart:io';

import 'package:dio/dio.dart';

import 'exceptions.dart';

enum ApiErrorType { none, noInternet, serverError, other }

ApiErrorType apiErrorTypeOf(Object? error) {
  if (error == null) return ApiErrorType.none;

  if (error is NoInternetConnectionException) return ApiErrorType.noInternet;
  if (error is InternalServerErrorException) return ApiErrorType.serverError;
  if (error is FetchDataException) return ApiErrorType.noInternet;
  if (error is SocketException) return ApiErrorType.noInternet;

  if (error is DioException) {
    final status = error.response?.statusCode ?? 0;
    if (status >= 500 && status < 600) return ApiErrorType.serverError;
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return ApiErrorType.noInternet;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiErrorType.noInternet;
    }
  }

  final raw = error.toString();
  final text = raw.toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('no internet') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection timed out') ||
      text.contains('connection error') ||
      text.contains('error during communication') ||
      text.contains('timeout') ||
      raw.contains('لا يوجد اتصال') ||
      raw.contains('لا يوجد إنترنت') ||
      raw.contains('تحقق من اتصال') ||
      raw.contains('الشبكة') ||
      raw.contains('الإنترنت')) {
    return ApiErrorType.noInternet;
  }
  if (text.contains('internal server error') ||
      text.contains('bad gateway') ||
      text.contains('service unavailable') ||
      text.contains('gateway timeout') ||
      raw.contains('خطأ في الخادم') ||
      raw.contains('حدث خطأ ما') ||
      raw.contains('خطأ من جانبنا')) {
    return ApiErrorType.serverError;
  }
  return ApiErrorType.other;
}
