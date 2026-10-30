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

  /// Ids of the project's visits an admin has locked (T042). A rejected change
  /// to one of them can't succeed until it is unlocked, so the screen offers
  /// no Retry for it.
  Stream<Set<String>> watchLockedVisitIds(String projectId) {
    final query = _db.selectOnly(_db.surveyVisits)
      ..addColumns([_db.surveyVisits.id])
      ..where(
        _db.surveyVisits.projectId.equals(projectId) &
            _db.surveyVisits.status.equals('locked') &
            _db.surveyVisits.deletedAt.isNull(),
      );
    return query.watch().map(
      (rows) => {for (final row in rows) row.read(_db.surveyVisits.id)!},
    );
  }

  /// Photos the server refused for good (T050): they wait for the user to
  /// retry or delete them. Newest first.
  Stream<List<Photo>> watchFailedPhotos() {
    final query = _db.select(_db.photos)
      ..where(
        (p) =>
            p.uploadStatus.equals('pending') &
            p.uploadError.isNotNull() &
            p.deletedAt.isNull(),
      )
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]);
    return query.watch();
  }

  /// Photos waiting for their file to be uploaded (T050): how many, and their
  /// total size in bytes. A deleted photo is not counted, and neither is one
  /// the server refused (see [watchFailedPhotos]). Photos are not
  /// tied to a project here, so this covers the whole phone.
  Stream<({int count, int bytes})> watchPendingPhotos() {
    final count = countAll();
    final bytes = _db.photos.fileSize.sum();
    final query = _db.selectOnly(_db.photos)
      ..addColumns([count, bytes])
      ..where(
        _db.photos.uploadStatus.equals('pending') &
            _db.photos.uploadError.isNull() &
            _db.photos.deletedAt.isNull(),
      );
    return query.watchSingle().map(
      (row) => (count: row.read(count)!, bytes: row.read(bytes) ?? 0),
    );
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
