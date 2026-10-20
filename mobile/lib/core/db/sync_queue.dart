import 'package:drift/drift.dart';

/// Where a queue item is in its life (outline §12.3).
enum QueueStatus { queued, inFlight, conflict, rejected }

/// Local changes waiting to be pushed, oldest `seq` first. Local only.
@DataClassName('SyncQueueItem')
@TableIndex(name: 'sync_queue_entity', columns: {#entityType, #entityId, #seq})
class SyncQueue extends Table {
  IntColumn get seq => integer().autoIncrement()();

  /// UUID v4; lets the server recognise a resend.
  TextColumn get mutationId => text().unique()();
  TextColumn get projectId => text()();

  /// Server entity type, which is also the local table name.
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// `create`, `update`, `delete` or `create_batch`.
  TextColumn get operation => text()();
  IntColumn get baseVersion => integer().nullable()();

  /// JSON, with the server's field names.
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => textEnum<QueueStatus>()();

  @override
  String get tableName => 'sync_queue';
}
