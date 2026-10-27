import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

/// This phone's GPS interval in seconds, chosen in Settings (T037), or null
/// to use the project protocol's `gpsIntervalS`. The tracker reads it when
/// tracking starts, so a change applies from the next start.
class GpsIntervalOverrideNotifier extends Notifier<int?> {
  static const _key = 'gps_interval_override_s';

  /// The choices offered in Settings, in seconds.
  static const choices = [1, 2, 5, 10, 15, 30];

  @override
  int? build() {
    return ref.read(sharedPreferencesProvider).getInt(_key);
  }

  /// Saves [seconds]; null goes back to the project protocol.
  Future<void> save(int? seconds) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (seconds == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setInt(_key, seconds);
    }
    state = seconds;
  }
}

final gpsIntervalOverrideProvider =
    NotifierProvider<GpsIntervalOverrideNotifier, int?>(
      GpsIntervalOverrideNotifier.new,
    );
