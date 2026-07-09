import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../config/routes/routes.dart';
import '../../config/routes/routes_manager.dart';

import '../cache/cache_keys.dart';
import '../dependencies/app_dependencies.dart';
import '../theme/transelation/localization_key.dart';
import 'deep_link_services.dart';
import 'endpoints.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class DeepLinkState {
  final DeepLinkResult? pendingResult;
  const DeepLinkState({this.pendingResult});
  DeepLinkState copyWith({DeepLinkResult? pendingResult}) =>
      DeepLinkState(pendingResult: pendingResult);
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class DeepLinkCubit extends Cubit<DeepLinkState> {
  final DeepLinkService _service;
  StreamSubscription<DeepLinkResult>? _sub;

  DeepLinkCubit(this._service) : super(const DeepLinkState());

  Future<void> init() async {
    await _service.init();

    // Restore cold-start pending link into cubit state
    if (_service.pendingResult != null) {
      emit(state.copyWith(pendingResult: _service.pendingResult));
    }

    // Listen for live links (foreground / background)
    _sub = _service.linkStream.listen((result) {
      debugPrint('🔗 [Cubit] Live link received (${result.source.name}): ${result.uri}');
      emit(state.copyWith(pendingResult: result));
    });
  }

  // ── Called by BlocListener in MyApp ────────────────────────────────────────
  Future<void> handleIfExists(BuildContext context) async {
    final result = state.pendingResult;
    if (result == null) return;

    debugPrint('🔗 [Cubit] Handling (${result.source.name}): ${result.uri}');

    _consume(); // clear state first — prevents any double trigger
   await _navigate(context, result);
  }

  void _consume() => emit(const DeepLinkState());

  // ── Navigation ──────────────────────────────────────────────────────────────
  Future<void> _navigate(BuildContext context, DeepLinkResult result) async {
    final segments = result.uri.pathSegments;
    debugPrint('🔗 [Cubit] Segments: $segments | Source: ${result.source.name}');

    // ── /details/{id}/{slug} ──────────────────────────────────────────────────
    if (segments.length >= 3 && segments[0] == 'details') {
      final id   = segments[1];
      final slug = segments[2];
      final deps = AppDependencies.of(context);
      final cache = deps.cache;
      final sessionId = await cache.getData(key: CacheKeys.sessionId);
      final isGuest = await cache.getData(key: CacheKeys.isGuest) == true;
      final hasGuestSession =
          isGuest && sessionId is String && sessionId
              .trim()
              .isNotEmpty;


      await _service.markHandled(result.uri);


      return;
    }

    // ── Add more routes here ──────────────────────────────────────────────────
    // if (segments.isNotEmpty && segments[0] == 'order') { ... }

    debugPrint('🔗 [Cubit] Unhandled deep link: $segments');
  }
  String? _extractSessionId(dynamic data, dynamic headers) {
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      return map['sessionId']?.toString() ??
          map['sessionid']?.toString() ??
          map['sessionID']?.toString() ??
          (map['data'] is Map
              ? (map['data'] as Map)['sessionId']?.toString()
              : null);
    }

    if (data is String) {
      return data;
    }
    return null;
  }
  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}