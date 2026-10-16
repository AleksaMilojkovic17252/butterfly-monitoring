import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

/// Time of the last successful sync, shown on the login screen. The sync
/// runner (T030) calls [markSynced] after a successful run.
class LastSyncNotifier extends Notifier<DateTime?> {
  static const _key = 'last_sync_at';

  @override
  DateTime? build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  Future<void> markSynced([DateTime? at]) async {
    final time = at ?? DateTime.now().toUtc();
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, time.toUtc().toIso8601String());
    state = time.toLocal();
  }

  Future<void> clear() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    state = null;
  }
}

final lastSyncProvider = NotifierProvider<LastSyncNotifier, DateTime?>(
  LastSyncNotifier.new,
);

/// Number of local changes not yet pushed. No synced tables exist yet, so this
/// is 0 until T030 counts rows whose syncStatus is pending.
final pendingChangesProvider = FutureProvider<int>((ref) async => 0);

/// Runs a sync now; returns true when everything was pushed. Replaced by the
/// real runner in T030.
final syncNowProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => false,
);
