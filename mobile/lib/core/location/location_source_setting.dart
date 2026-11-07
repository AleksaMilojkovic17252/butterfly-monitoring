import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

/// Where the tracker gets its fixes (T072): the phone's GPS or a replay of the
/// bundled GPX file.
enum LocationSourceKind { device, replay }

/// The choice in Settings: the source and the replay speed.
class LocationSourceChoice {
  const LocationSourceChoice({required this.kind, required this.speed});
  final LocationSourceKind kind;

  /// Replay speed: 1, 5 or 20 times the GPX clock.
  final int speed;
}

/// This phone's location source setting (T072), stored in SharedPreferences.
/// Only debug builds show it and act on it. The tracker reads it when
/// tracking starts, so a change applies from the next start.
class LocationSourceNotifier extends Notifier<LocationSourceChoice> {
  static const _kindKey = 'location_source';
  static const _speedKey = 'replay_speed';

  /// The replay speeds offered in Settings.
  static const speeds = [1, 5, 20];

  @override
  LocationSourceChoice build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final speed = prefs.getInt(_speedKey);
    return LocationSourceChoice(
      kind: prefs.getString(_kindKey) == LocationSourceKind.replay.name
          ? LocationSourceKind.replay
          : LocationSourceKind.device,
      speed: speeds.contains(speed) ? speed! : speeds.first,
    );
  }

  /// Saves the source and the replay speed.
  Future<void> save(LocationSourceKind kind, int speed) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kindKey, kind.name);
    await prefs.setInt(_speedKey, speed);
    state = LocationSourceChoice(kind: kind, speed: speed);
  }
}

final locationSourceSettingProvider =
    NotifierProvider<LocationSourceNotifier, LocationSourceChoice>(
      LocationSourceNotifier.new,
    );
