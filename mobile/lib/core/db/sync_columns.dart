import 'package:drift/drift.dart';
import 'package:mobile/core/db/sync_status.dart';

/// Local sync columns every synced table carries (CONVENTIONS A.6).
mixin SyncColumns on Table {
  /// Version the server last gave this row; null until pushed.
  IntColumn get serverVersion => integer().nullable()();

  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.name))();

  /// Set by a soft delete.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
