import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/core/config/server_preset.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings screen shows the saved server URL and fills presets', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://example.test:9000',
    });
    // A stored session opens the app offline, straight to the project list.
    FlutterSecureStorage.setMockInitialValues({
      'refresh_token': 'r',
      'access_token': 'a',
      'profile': jsonEncode({
        'id': '1',
        'email': 'a@b.co',
        'name': 'Ana',
        'organization': '',
        'groups': <String>[],
        'project_ids': <String>[],
      }),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Projects'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('http://example.test:9000'), findsOneWidget);

    await tester.tap(find.text(ServerPreset.usb.label));
    await tester.pump();

    expect(find.text(ServerPreset.usb.url), findsOneWidget);

    // Drift closes its stream queries on a zero-length timer; let it run.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
