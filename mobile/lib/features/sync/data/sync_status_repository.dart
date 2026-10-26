import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_queue.dart';

/// Read-only queries for the sync status screen. Writes stay in
/// `SyncRepository`.
class SyncStatusRepository {
  SyncStatusRepository(this._db);

  final AppDatabase _db;

  /// Queue items of the project per entity type, in any status. The sum equals
  /// `SyncRepository.watchUnsyncedCount` for the project.
  Stream<Map<String, int>> watchPendingByType(String projectId) {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.entityType, count])
      ..where(_db.syncQueue.projectId.equals(projectId))
      ..groupBy([_db.syncQueue.entityType]);

    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(_db.syncQueue.entityType)!: row.read(count)!,
      },
    );
  }

  /// The project's rejected queue items, in queue order.
  Stream<List<SyncQueueItem>> watchRejected(String projectId) {
    final query = _db.select(_db.syncQueue)
      ..where(
        (t) =>
            t.projectId.equals(projectId) &
            t.status.equalsValue(QueueStatus.rejected),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.seq)]);
    return query.watch();
  }

  /// The project's conflicts that are not deleted: open ones first, then
  /// newest first.
  Stream<List<SyncConflict>> watchConflicts(String projectId) {
    final query = _db.select(_db.syncConflicts)
      ..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.status.equals('open')),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);

    return query.watch();
  }
}

final syncStatusRepositoryProvider = Provider<SyncStatusRepository>((ref) {
  return SyncStatusRepository(ref.watch(appDatabaseProvider));
});
