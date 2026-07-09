import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeepLinkSource { coldStart, background, foreground }

class DeepLinkResult {
  final Uri uri;
  final DeepLinkSource source;
  const DeepLinkResult({required this.uri, required this.source});
}

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final StreamController<DeepLinkResult> _controller =
  StreamController<DeepLinkResult>.broadcast();
  StreamSubscription<Uri>? _sub;

  Stream<DeepLinkResult> get linkStream => _controller.stream;
  DeepLinkResult? _pendingResult;
  DeepLinkResult? get pendingResult => _pendingResult;

  static const _handledKey = 'last_handled_deep_link';

  Future<void> init() async {
    final initialUri = await _appLinks.getInitialLink();

    if (initialUri != null) {
      final prefs = await SharedPreferences.getInstance();
      final lastHandled = prefs.getString(_handledKey);
      final uriStr = initialUri.toString();

      if (lastHandled == uriStr) {
        // ✅ Same URI already handled — Android kept the intent alive (rerun / restart)
        // DO NOT emit — blocks rerun-from-studio re-navigation forever until a new link comes
        debugPrint('🔗 [Service] Cold start URI already handled, skipping: $uriStr');
      } else {
        // 🆕 Genuine new cold start link
        debugPrint('🔗 [Service] Cold start — new link: $uriStr');
        _pendingResult = DeepLinkResult(uri: initialUri, source: DeepLinkSource.coldStart);
        _controller.add(_pendingResult!);
      }
    }

    // Handles background → foreground AND already-open cases
    _sub = _appLinks.uriLinkStream.listen(
          (uri) async {
        debugPrint('🔗 [Service] Live link: $uri');

        // If a NEW different link arrives, clear the old handled key
        // so it can be processed fresh
        final prefs = await SharedPreferences.getInstance();
        final lastHandled = prefs.getString(_handledKey);
        if (lastHandled != null && lastHandled != uri.toString()) {
          await prefs.remove(_handledKey);
        }

        final result = DeepLinkResult(uri: uri, source: DeepLinkSource.foreground);
        _pendingResult = result;
        _controller.add(result);
      },
      onError: (err) => debugPrint('🔗 [Service] Error: $err'),
    );
  }

  /// ✅ Call BEFORE navigating — saves URI so cold restarts skip it
  Future<void> markHandled(Uri uri) async {
    _pendingResult = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_handledKey, uri.toString());
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}