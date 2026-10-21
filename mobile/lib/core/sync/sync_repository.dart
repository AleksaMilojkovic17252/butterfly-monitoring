import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_columns.dart';
import 'package:mobile/core/db/sync_queue.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/sync/sync_api.dart';
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

  /// Live version of [unsyncedCount]: emits again whenever the queue changes.
  /// With [projectId] it counts only that project's items.
  Stream<int> watchUnsyncedCount({String? projectId}) {
    return _db.syncQueue
        .count(
          where: projectId == null
              ? null
              : (t) => t.projectId.equals(projectId),
        )
        .watchSingle();
  }

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

  /// Puts items left `inFlight` by an interrupted run back to `queued`, with
  /// `retryCount` raised so they no longer count as unsent (see [_isUnsent]).
  /// They keep their `mutationId`: if the server did apply them, the resend
  /// comes back as `duplicate`. Call it at the start of every run.
  Future<void> recoverInFlight() {
    return _db.transaction(() async {
      await (_db.update(
        _db.syncQueue,
      )..where((t) => t.status.equalsValue(QueueStatus.inFlight))).write(
        SyncQueueCompanion.custom(
          status: Constant(QueueStatus.queued.name),
          retryCount: _db.syncQueue.retryCount + const Constant(1),
          nextAttemptAt: const Constant<DateTime>(null),
        ),
      );
    });
  }

  /// The next items to push: `queued` ones in `seq` order, at most [max]. Items
  /// of an entity with a `conflict` item are held back (skipped). The batch
  /// stops, rather than skips, at the first item that is not due yet (unless
  /// [ignoreBackoff]) and before an `update` or `delete` of an entity that is
  /// already in the batch, so later items never overtake earlier ones.
  Future<List<SyncQueueItem>> nextBatch({
    required bool ignoreBackoff,
    int max = 100,
  }) {
    return _db.transaction(() async {
      final queued =
          await (_db.select(_db.syncQueue)
                ..where((t) => t.status.equalsValue(QueueStatus.queued))
                ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
              .get();
      final conflicts = await (_db.select(
        _db.syncQueue,
      )..where((t) => t.status.equalsValue(QueueStatus.conflict))).get();

      final held = {for (final item in conflicts) _entityKey(item)};
      final batchKeys = <String>{};
      final batch = <SyncQueueItem>[];
      final now = DateTime.now();

      for (final item in queued) {
        final key = _entityKey(item);
        if (held.contains(key)) continue;

        final due = item.nextAttemptAt;
        if (!ignoreBackoff && due != null && due.isAfter(now)) break;

        final changesExisting =
            item.operation == SyncOperation.update.wireName ||
            item.operation == SyncOperation.delete.wireName;
        if (changesExisting && batchKeys.contains(key)) break;

        batch.add(item);
        batchKeys.add(key);
        if (batch.length == max) break;
      }
      return batch;
    });
  }

  /// Identifies the entity a queue item belongs to.
  String _entityKey(SyncQueueItem item) =>
      '${item.entityType}/${item.entityId}';

  /// Marks [items] as being sent (`inFlight`) and returns them as they are in
  /// the queue now. Only `status` changes, so an edit merged into an item's
  /// payload in the meantime is never overwritten. An edit can still have been
  /// merged between [nextBatch] and this call, so send the returned items, not
  /// [items]. An item that was cancelled in that gap is not returned.
  Future<List<SyncQueueItem>> markSending(List<SyncQueueItem> items) {
    return _db.transaction(() async {
      final seqs = items.map((element) => element.seq).toList();
      await (_db.update(_db.syncQueue)..where((t) => t.seq.isIn(seqs))).write(
        SyncQueueCompanion(status: Value(QueueStatus.inFlight)),
      );
      return (_db.select(_db.syncQueue)
            ..where((t) => t.seq.isIn(seqs))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .get();
    });
  }

  /// Puts [items] back to `queued` after a failed push: `retryCount` goes up,
  /// `nextAttemptAt` is set by [backoffDelay], and [error] is kept in
  /// `lastError`. The payload and `mutationId` stay as they are, so the resend
  /// is recognised by the server if the first attempt got through.
  Future<void> markNetworkFailure(List<SyncQueueItem> items, Object error) {
    return _db.transaction(() async {
      for (final item in items) {
        final retries = item.retryCount + 1;
        await (_db.update(
          _db.syncQueue,
        )..where((t) => t.seq.equals(item.seq))).write(
          SyncQueueCompanion(
            status: Value(QueueStatus.queued),
            retryCount: Value(retries),
            nextAttemptAt: Value(
              DateTime.now().toUtc().add(backoffDelay(retries)),
            ),
            lastError: Value(error.toString()),
          ),
        );
      }
    });
  }

  /// Applies the server's answers to a pushed batch, matching them to [items]
  /// by `mutationId`. Accepted items leave the queue; `conflict` and `rejected`
  /// ones stay in it with that status (and so does their row). An item with no
  /// answer is treated as a network failure. All of it is one transaction.
  Future<void> applyPushResults(
    List<SyncQueueItem> items,
    List<PushResult> results,
  ) {
    return _db.transaction(() async {
      final byId = {for (final result in results) result.mutationId: result};
      final unanswered = <SyncQueueItem>[];

      for (final item in items) {
        final result = byId[item.mutationId];
        if (result == null) {
          unanswered.add(item);
          continue;
        }
        switch (result.status) {
          case PushResultStatus.applied:
          case PushResultStatus.merged:
          case PushResultStatus.duplicate:
            await _applyAccepted(item, result.serverVersion);
          case PushResultStatus.conflict:
            await _holdItem(item, QueueStatus.conflict, SyncStatus.conflict);
          case PushResultStatus.rejected:
            await _holdItem(
              item,
              QueueStatus.rejected,
              SyncStatus.rejected,
              error: result.errors,
            );
        }
      }

      await markNetworkFailure(unanswered, 'no result from the server');
    });
  }

  /// The server has this change: drop the item, record the row's new version,
  /// and rebase the entity's later items onto it. The row is `synced` only when
  /// nothing else is queued for it. A `create_batch` has no version and its
  /// `entityId` is the parent, so it marks the child rows listed in its payload.
  Future<void> _applyAccepted(SyncQueueItem item, int? serverVersion) async {
    await (_db.delete(
      _db.syncQueue,
    )..where((t) => t.seq.equals(item.seq))).go();

    if (item.operation == SyncOperation.createBatch.wireName) {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      final ids = [
        for (final row in payload['rows'] as List)
          (row as Map<String, dynamic>)['id'] as String,
      ];
      if (ids.isEmpty) return;
      final marks = List.filled(ids.length, '?').join(', ');
      await _db.customUpdate(
        'UPDATE "${item.entityType}" SET sync_status = ? WHERE id IN ($marks)',
        variables: [
          Variable.withString(SyncStatus.synced.name),
          for (final id in ids) Variable.withString(id),
        ],
      );
      return;
    }

    if (serverVersion != null) {
      await _db.customUpdate(
        'UPDATE "${item.entityType}" SET server_version = ? WHERE id = ?',
        variables: [
          Variable.withInt(serverVersion),
          Variable.withString(item.entityId),
        ],
      );
      // A later update or delete was queued before the version was known.
      await (_db.update(_db.syncQueue)..where(
            (t) =>
                t.entityType.equals(item.entityType) &
                t.entityId.equals(item.entityId) &
                t.operation.isIn([
                  SyncOperation.update.wireName,
                  SyncOperation.delete.wireName,
                ]),
          ))
          .write(SyncQueueCompanion(baseVersion: Value(serverVersion)));
    }

    final left =
        await (_db.select(_db.syncQueue)..where(
              (t) =>
                  t.entityType.equals(item.entityType) &
                  t.entityId.equals(item.entityId),
            ))
            .get();
    if (left.isEmpty) {
      await _setRowStatus(item, SyncStatus.synced);
    }
  }

  /// Keeps [item] in the queue with [queueStatus] (`conflict` or `rejected`),
  /// stores [error] as its `lastError` when given, and gives its row
  /// [rowStatus]. For a `create_batch` the row update matches nothing.
  Future<void> _holdItem(
    SyncQueueItem item,
    QueueStatus queueStatus,
    SyncStatus rowStatus, {
    String? error,
  }) async {
    await (_db.update(
      _db.syncQueue,
    )..where((t) => t.seq.equals(item.seq))).write(
      SyncQueueCompanion(
        status: Value(queueStatus),
        lastError: Value.absentIfNull(error),
      ),
    );
    await _setRowStatus(item, rowStatus);
  }

  /// Sets `sync_status` on the item's entity row.
  Future<void> _setRowStatus(SyncQueueItem item, SyncStatus status) {
    return _db.customUpdate(
      'UPDATE "${item.entityType}" SET sync_status = ? WHERE id = ?',
      variables: [
        Variable.withString(status.name),
        Variable.withString(item.entityId),
      ],
    );
  }

  /// True while an item has not been sent. T030 must raise `retryCount` or set
  /// `inFlight` before sending, or this goes wrong.
  bool _isUnsent(SyncQueueItem item) =>
      item.status == QueueStatus.queued && item.retryCount == 0;
}

/// How long to wait before the next attempt: `min(2^retryCount s, 900 s)`
/// times a random factor between 0.8 and 1.2, so clients do not retry in step.
/// The exponent is capped first so a large [retryCount] cannot overflow. Pass
/// [random] to get a repeatable result.
Duration backoffDelay(int retryCount, [Random? random]) {
  final n = min(retryCount, 10);
  final base = min(1 << n, 900);
  final jitter = 0.8 + 0.4 * (random ?? Random()).nextDouble();
  return Duration(milliseconds: (base * jitter * 1000).round());
}

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(ref.watch(appDatabaseProvider)),
);
