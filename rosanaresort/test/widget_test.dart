// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosanaresort/core/api/dio_consumer.dart';
import 'package:rosanaresort/core/cache/cache_consumer_impl.dart';
import 'package:rosanaresort/main.dart';


void main() {
  testWidgets('Tires app builds and shows initial screen', (
      WidgetTester tester,
      ) async {

    final cache = await EncryptedCacheConsumerImpl.init();
    final api = DioConsumer(dio: Dio(), baseUrl: 'https://test.example', cache: cache);


    await tester.pumpWidget(Ehub(
      api: api,
      cache: cache,
    ));


    // First frame: MaterialApp should be in the tree
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}