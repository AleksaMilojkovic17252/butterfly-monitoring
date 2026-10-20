import 'package:drift/drift.dart';

/// Key/value store for sync bookkeeping, used through `SyncStateRepository`.
@DataClassName('SyncStateEntry')
class SyncStateEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'sync_state';
}
