import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../cache/cache_consumer.dart';
import '../cache/cache_keys.dart';

class AppInterceptors extends Interceptor {
  final CacheConsumer _cache;
  AppInterceptors({required CacheConsumer cache}) : _cache = cache;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,

  ) async {


    final savedRefreshToken = _cache.getData( key:CacheKeys.refreshToken,);
    final sessionId = _cache.getData( key:CacheKeys.sessionId);



    if (sessionId != null) {
    }

    options.headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
    });

    super.onRequest(options, handler);
  }

  // ── JWT decoder ────────────────────────────────────────────────────────────

  String? _extractRoleFromToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    try {
      final parts = token.trim().split('.');
      if (parts.length != 3) return null;

      String payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Decode(payload));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      // Try common role claim names
      final role =
          claims['role'] ??
          claims['userRole'] ??
          claims['user_role'] ??
          claims['type'] ??
          claims['accountType'];

      // Always lowercase for consistent comparison
      return role?.toString().toLowerCase().trim();
    } catch (e) {
      return null;
    }
  }

  // ── Header builder ─────────────────────────────────────────────────────────

  String? _buildAuthHeader({String? token, String? role}) {
    if (token == null || token.trim().isEmpty) return null;

    final t = token.trim();

    // If token already has a known prefix (e.g. "User eyJ..."), return as-is
    final knownPrefixes = [
      'user',
      'agent',
      'mc',
      'admin',
      'sadmin',
      'support',
      'moderator',
      'marketing',
      'bearer',
    ];
    final firstWord = t.split(' ').first.toLowerCase();
    if (knownPrefixes.contains(firstWord)) return t;

    // Build prefix from role → hardcoded map (no .env lookup needed)
    // This avoids .env key mismatches entirely
    final prefix = _prefixForRole(role);

    return '$prefix $t';
  }

  /// Maps role string directly to the bearer prefix value.
  /// Bypasses .env lookup to avoid null issues when keys are missing.
  /// Falls back to the .env value if available, otherwise uses hardcoded default.
  String _prefixForRole(String? role) {
    // Hardcoded defaults matching your .env values
    const Map<String, String> roleToPrefix = {
      'user': 'User',
      'agent': 'Agent',
      'mc': 'MC',
      'admin': 'Admin',
      'sadmin': 'SAdmin',
      'support': 'Support',
      'moderator': 'Moderator',
      'marketing': 'Marketing',
    };

    final normalizedRole = role?.toLowerCase().trim() ?? 'user';

    // Try .env first (allows override), fall back to hardcoded map, then 'User'
    final envKey = _envKeyForRole(normalizedRole);
    final envValue = dotenv.env[envKey]?.trim();

    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    final hardcoded = roleToPrefix[normalizedRole] ?? 'User';
    return hardcoded;
  }

  String _envKeyForRole(String role) {
    switch (role) {
      case 'agent':
        return 'AGENT_BEARER';
      case 'mc':
        return 'MC_BEARER';
      case 'admin':
        return 'ADMIN_BEARER';
      case 'sadmin':
        return 'SADMIN_BEARER';
      case 'support':
        return 'SUPPORT_BEARER';
      case 'moderator':
        return 'MODERATOR_BEARER';
      case 'marketing':
        return 'MARKETING_BEARER';
      case 'user':
      default:
        return 'USER_BEARER';
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {

    super.onError(err, handler);
  }
}
