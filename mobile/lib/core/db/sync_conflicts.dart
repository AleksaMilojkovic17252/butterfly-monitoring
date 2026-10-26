import 'package:drift/drift.dart';
import 'package:mobile/core/db/sync_status.dart';

/// Local mirror of the server's `sync_conflict` table: the caller's own
/// conflicts, pulled so the app can list them and release held queue items.
/// Unlike the other pulled tables it has a `syncStatus` column. `status` is the
/// server's value (`open`, `resolved_server` or `resolved_client`).
/// `projectId` is local only: the pull fills it, the server does not send it.
class SyncConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get conflictingFields => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolutionNote => text()();
  TextColumn get status => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.name))();
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "sync_conflict";
}
