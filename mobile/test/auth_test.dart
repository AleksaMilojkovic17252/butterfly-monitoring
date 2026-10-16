import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';
import 'package:mobile/core/http/auth_interceptor.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/data/token_storage.dart';
import 'package:mobile/features/auth/ui/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers every request itself: 401 unless the bearer token is `new`.
class _FakeAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final ok = options.headers['Authorization'] == 'Bearer new';
    return ResponseBody.fromString(
      ok ? '{}' : '{"code":"not_authenticated"}',
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('login form validation', () {
    Future<void> pumpLogin(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
    }

    testWidgets('empty fields show errors and do not submit', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('malformed email is rejected', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
      await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows "Never synced" without a last sync time', (
      tester,
    ) async {
      await pumpLogin(tester);
      expect(find.text('Never synced'), findsOneWidget);
    });
  });

  test('concurrent 401s share exactly one refresh', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old',
      'refresh_token': 'r',
    });
    final storage = TokenStorage(const FlutterSecureStorage());
    final adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = adapter;

    var refreshes = 0;
    var expired = false;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        storage: storage,
        refresh: () async {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await storage.saveTokens(access: 'new');
          return 'new';
        },
        onSessionExpired: () => expired = true,
      ),
    );

    final responses = await Future.wait([
      dio.get<dynamic>('/a'),
      dio.get<dynamic>('/b'),
      dio.get<dynamic>('/c'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(refreshes, 1);
    expect(expired, isFalse);
  });

  test('failed refresh signals session expiry and keeps the 401', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old',
      'refresh_token': 'r',
    });
    final storage = TokenStorage(const FlutterSecureStorage());
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = _FakeAdapter();
    var expired = false;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        storage: storage,
        refresh: () async => throw const AuthException('rejected'),
        onSessionExpired: () => expired = true,
      ),
    );

    await expectLater(
      dio.get<dynamic>('/a'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(expired, isTrue);
  });

  test('network failure during refresh keeps the session', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old',
      'refresh_token': 'r',
    });
    final storage = TokenStorage(const FlutterSecureStorage());
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = _FakeAdapter();
    var expired = false;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        storage: storage,
        refresh: () async =>
            throw const AuthException('offline', network: true),
        onSessionExpired: () => expired = true,
      ),
    );

    await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
    expect(expired, isFalse);
    expect(await storage.readRefresh(), 'r');
  });
}
