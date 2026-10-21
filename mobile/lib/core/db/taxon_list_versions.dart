import 'package:drift/drift.dart';

/// Local copy of the server's `taxon_list_version` table: one release of the
/// butterfly list. A read-only reference table written only by pull, so it has
/// no `syncStatus` column (D-042).
class TaxonListVersions extends Table {
  TextColumn get id => text()();
  TextColumn get versionLabel => text()();
  TextColumn get source => text()();
  DateTimeColumn get publishedAt => dateTime()();
  BoolColumn get isCurrent => boolean()();
  TextColumn get notes => text()();

  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "taxon_list_version";
}
