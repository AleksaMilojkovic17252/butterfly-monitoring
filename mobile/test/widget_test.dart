import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/core/config/server_preset.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings screen shows the saved server URL and fills presets', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://example.test:9000',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('http://example.test:9000'), findsOneWidget);

    await tester.tap(find.text(ServerPreset.usb.label));
    await tester.pump();

    expect(find.text(ServerPreset.usb.url), findsOneWidget);
  });
}
