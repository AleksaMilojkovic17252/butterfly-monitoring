import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

/// Whether the active visit screen keeps the phone's screen on (T039). A
/// per-device choice, off by default; the screen turns it on while it is open
/// (`wakelock_plus`).
class KeepScreenOnNotifier extends Notifier<bool> {
  static const _key = 'keep_screen_on';

  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_key) ?? false;
  }

  /// Saves [on] for the next visits too.
  Future<void> save(bool on) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, on);
    state = on;
  }
}

final keepScreenOnProvider = NotifierProvider<KeepScreenOnNotifier, bool>(
  KeepScreenOnNotifier.new,
);
