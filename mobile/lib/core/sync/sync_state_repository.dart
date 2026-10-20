import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

/// The `sync_state` store: device id, pull cursor per project, last sync info.
class SyncStateRepository {
  SyncStateRepository(this._db);
  final AppDatabase _db;

  static const _deviceIdKey = 'deviceId';
  static const _lastSuccessfulSyncAtKey = 'lastSuccessfulSyncAt';
  static const _lastSyncBytesKey = 'lastSyncBytes';

  static String _cursorKey(String projectId) => 'cursor:$projectId';

  /// This install's id, sent with every push. Created on first read (in
  /// practice the first launch that syncs). One transaction, so no two ids.
  Future<String> deviceId() => _db.transaction(() async {
    final existing = await _get(_deviceIdKey);
    if (existing != null) return existing;
    final created = const Uuid().v4();
    await _set(_deviceIdKey, created);
    return created;
  });

  /// Pull cursor of a project; null means never pulled (cursor 0).
  Future<int?> lastPullCursor(String projectId) async {
    final raw = await _get(_cursorKey(projectId));
    return raw == null ? null : int.parse(raw);
  }

  Future<void> setLastPullCursor(String projectId, int cursor) =>
      _set(_cursorKey(projectId), cursor.toString());

  /// End of the last error-free sync run, in UTC; null if never.
  Future<DateTime?> lastSuccessfulSyncAt() async {
    final raw = await _get(_lastSuccessfulSyncAtKey);
    return raw == null ? null : DateTime.parse(raw).toUtc();
  }

  Future<void> setLastSuccessfulSyncAt(DateTime at) =>
      _set(_lastSuccessfulSyncAtKey, at.toUtc().toIso8601String());

  /// Bytes transferred by the last sync run; null if none.
  Future<int?> lastSyncBytes() async {
    final raw = await _get(_lastSyncBytesKey);
    return raw == null ? null : int.parse(raw);
  }

  Future<void> setLastSyncBytes(int bytes) =>
      _set(_lastSyncBytesKey, bytes.toString());

  Future<String?> _get(String key) async {
    final row = await (_db.select(
      _db.syncStateEntries,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _set(String key, String value) => _db
      .into(_db.syncStateEntries)
      .insertOnConflictUpdate(
        SyncStateEntriesCompanion.insert(key: key, value: value),
      );
}

final syncStateRepositoryProvider = Provider<SyncStateRepository>(
  (ref) => SyncStateRepository(ref.watch(appDatabaseProvider)),
);
