import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

/// The id of the visit that is recorded in battery-saver mode (T038), or null
/// when the mode is off. It is kept in `SharedPreferences`, so the mode
/// survives a restart of the app: when tracking starts for a visit with this
/// id, it starts in battery-saver mode. An id left over from an old visit
/// matches no new visit, so it does no harm.
class BatterySaverVisitNotifier extends Notifier<String?> {
  static const _key = 'battery_saver_visit_id';

  @override
  String? build() {
    return ref.read(sharedPreferencesProvider).getString(_key);
  }

  /// Saves [visitId] as the visit in battery-saver mode; null turns it off.
  Future<void> save(String? visitId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (visitId == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, visitId);
    }
    state = visitId;
  }
}

final batterySaverVisitProvider =
    NotifierProvider<BatterySaverVisitNotifier, String?>(
      BatterySaverVisitNotifier.new,
    );

/// The phone's battery, for the automatic battery saver below 20 %.
final batteryProvider = Provider<Battery>((ref) => Battery());
