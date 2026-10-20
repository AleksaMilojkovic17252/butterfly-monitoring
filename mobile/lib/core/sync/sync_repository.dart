import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_columns.dart';
import 'package:mobile/core/db/sync_queue.dart';
import 'package:uuid/uuid.dart';

/// What a queue item asks the server to do. [wireName] is the server's name
/// for it (D-050) and what `sync_queue.operation` stores.
enum SyncOperation {
  create,
  update,
  delete,
  createBatch;

  String get wireName => this == createBatch ? 'create_batch' : name;
}

/// The only place that changes a synced row. The row and its queue item are
/// written in one transaction, so both exist or neither does.
///
/// `entityType` is both the server's entity type and the local table name
/// (e.g. `survey_visit`). That table has the [SyncColumns] and an `id` column.
class SyncRepository {
  SyncRepository(this._db);
  final AppDatabase _db;

  /// Most rows in one `create_batch` item.
  static const maxBatchRows = 500;

  /// Writes one change to a synced row and queues it, atomically.
  ///
  /// [writeRow] upserts the row (create and update only); this method then sets
  /// `sync_status = pending`. A delete is a soft delete, except when it cancels
  /// a create the server never saw: then the row is removed.
  ///
  /// [payload] has server field names and UTC ISO dates. [baseVersion] is the
  /// row's `serverVersion`, null for a create.
  Future<void> write({
    required String projectId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
    int? baseVersion,
    Future<void> Function()? writeRow,
  }) {
    if (operation == SyncOperation.createBatch) {
      throw ArgumentError('Use writeBatch for create_batch');
    }
    if (operation != SyncOperation.delete && writeRow == null) {
      throw ArgumentError('writeRow is required for ${operation.name}');
    }
    return _db.transaction(() async {
      // Queue item first: a throw below rolls it back with the row.
      final cancelledCreate = await _enqueue(
        projectId: projectId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        baseVersion: baseVersion,
      );

      // No `updates:` here, so table streams do not refresh (T034, see D-051).
      if (operation == SyncOperation.delete) {
        if (cancelledCreate) {
          await _db.customUpdate(
            'DELETE FROM "$entityType" WHERE id = ?',
            variables: [Variable.withString(entityId)],
          );
        } else {
          await _db.customUpdate(
            'UPDATE "$entityType" SET deleted_at = ?, sync_status = ? WHERE id = ?',
            variables: [
              Variable.withString(DateTime.now().toUtc().toIso8601String()),
              Variable.withString(SyncStatus.pending.name),
              Variable.withString(entityId),
            ],
          );
        }
      } else {
        await writeRow!();
        await _db.customUpdate(
          'UPDATE "$entityType" SET sync_status = ? WHERE id = ?',
          variables: [
            Variable.withString(SyncStatus.pending.name),
            Variable.withString(entityId),
          ],
        );
      }
    });
  }

  /// Queues child rows (track points) as `create_batch` items of at most
  /// [maxBatchRows]. [entityType] is the child table (`track_point`); [parentId]
  /// (the visit, D-050) is the queue's `entityId`. [rows] have server field
  /// names and their own `id`; [writeRows] inserts them locally. An unsent batch
  /// of the same parent is filled up first.
  Future<void> writeBatch({
    required String projectId,
    required String entityType,
    required String parentId,
    required List<Map<String, Object?>> rows,
    required Future<void> Function() writeRows,
  }) {
    return _db.transaction(() async {
      if (rows.isEmpty) return;
      var rest = rows;

      final latest = await _latestItem(entityType, parentId);
      if (latest != null &&
          latest.operation == SyncOperation.createBatch.wireName &&
          _isUnsent(latest)) {
        final stored = jsonDecode(latest.payload) as Map<String, dynamic>;
        final storedRows = List<Object?>.from(stored['rows'] as List);
        final room = maxBatchRows - storedRows.length;
        if (room > 0) {
          final take = rest.length < room ? rest.length : room;
          storedRows.addAll(rest.take(take));
          rest = rest.sublist(take);
          await (_db.update(
            _db.syncQueue,
          )..where((t) => t.seq.equals(latest.seq))).write(
            SyncQueueCompanion(
              payload: Value(jsonEncode({'rows': storedRows})),
            ),
          );
        }
      }

      for (var start = 0; start < rest.length; start += maxBatchRows) {
        final end = start + maxBatchRows < rest.length
            ? start + maxBatchRows
            : rest.length;
        await _insertItem(
          projectId: projectId,
          entityType: entityType,
          entityId: parentId,
          operation: SyncOperation.createBatch,
          payload: {'rows': rest.sublist(start, end)},
        );
      }

      await writeRows();

      final ids = [for (final row in rows) row['id'] as String];
      for (var start = 0; start < ids.length; start += maxBatchRows) {
        final chunk = ids.sublist(
          start,
          start + maxBatchRows < ids.length ? start + maxBatchRows : ids.length,
        );
        final marks = List.filled(chunk.length, '?').join(', ');
        await _db.customUpdate(
          'UPDATE "$entityType" SET sync_status = ? WHERE id IN ($marks)',
          variables: [
            Variable.withString(SyncStatus.pending.name),
            for (final id in chunk) Variable.withString(id),
          ],
        );
      }
    });
  }

  /// Changes not yet synced: every item in the queue, in any status. Items
  /// leave the queue only when the server accepted them.
  Future<int> unsyncedCount() => _db.syncQueue.count().getSingle();

  /// Queues the change, merging into the entity's last item when allowed.
  /// Returns true when a delete cancelled a queued create.
  Future<bool> _enqueue({
    required String projectId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
    required int? baseVersion,
  }) async {
    final latest = await _latestItem(entityType, entityId);

    // Merge only into an unsent item. A sent one may already be applied under
    // its mutationId, and the server would answer `duplicate` to merged changes.
    if (latest != null && _isUnsent(latest)) {
      final latestIsCreate = latest.operation == SyncOperation.create.wireName;
      final latestIsUpdate = latest.operation == SyncOperation.update.wireName;

      if ((latestIsCreate || latestIsUpdate) &&
          operation == SyncOperation.update) {
        // Keeps seq, mutationId and baseVersion; the seq keeps queue order.
        final old = jsonDecode(latest.payload) as Map<String, dynamic>;
        await (_db.update(
          _db.syncQueue,
        )..where((t) => t.seq.equals(latest.seq))).write(
          SyncQueueCompanion(payload: Value(jsonEncode({...old, ...payload}))),
        );
        return false;
      }

      if (latestIsCreate && operation == SyncOperation.delete) {
        await (_db.delete(
          _db.syncQueue,
        )..where((t) => t.seq.equals(latest.seq))).go();
        return true;
      }
    }

    await _insertItem(
      projectId: projectId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      baseVersion: baseVersion,
    );
    return false;
  }

  Future<void> _insertItem({
    required String projectId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
    int? baseVersion,
  }) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            mutationId: const Uuid().v4(),
            projectId: projectId,
            entityType: entityType,
            entityId: entityId,
            operation: operation.wireName,
            baseVersion: Value(baseVersion),
            payload: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
            status: QueueStatus.queued,
          ),
        );
  }

  /// The newest queue item (highest seq) of an entity, or null.
  Future<SyncQueueItem?> _latestItem(String entityType, String entityId) {
    return (_db.select(_db.syncQueue)
          ..where(
            (t) =>
                t.entityType.equals(entityType) & t.entityId.equals(entityId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.seq)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// True while an item has not been sent. T030 must raise `retryCount` or set
  /// `inFlight` before sending, or this goes wrong.
  bool _isUnsent(SyncQueueItem item) =>
      item.status == QueueStatus.queued && item.retryCount == 0;
}

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(ref.watch(appDatabaseProvider)),
);
