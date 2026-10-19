import 'package:drift/drift.dart';

/// Local copy of the server's `project` table. A read-only reference table:
/// only the server writes it (today a refresh from `GET /api/v1/projects`,
/// later the pull in T030/T031), so it has no `syncStatus` column.
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get defaultCrs => integer().withDefault(const Constant(4326))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Study area as a GeoJSON MultiPolygon, or null.
  TextColumn get area => text().nullable()();

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'project';
}
