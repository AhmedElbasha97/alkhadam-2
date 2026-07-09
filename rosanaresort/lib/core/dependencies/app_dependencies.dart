import 'package:flutter/material.dart';

import '../api/api_consumer.dart';
import '../cache/cache_consumer.dart';


/// Provides [ApiConsumer] and [CacheConsumer] to the widget tree without GetIt.
class AppDependencies extends InheritedWidget {
  const AppDependencies({
    super.key,
    required this.api,
    required this.cache,
    required super.child,
  });

  final ApiConsumer api;
  final CacheConsumer cache;

  static AppDependencies of(BuildContext context) {
    final deps = context.dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(deps != null, 'AppDependencies not found in context');
    return deps!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) =>
      api != oldWidget.api || cache != oldWidget.cache;
}
