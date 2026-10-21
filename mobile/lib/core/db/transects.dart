import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';

/// Local copy of the server's `transect` table: a fixed walking route of a
/// project. A read-only reference table written only by pull, so it has no
/// `syncStatus` column (D-042). `geometry` is a GeoJSON LineString as text;
/// `lengthM` is computed by the server and is not a stored field there.
class Transects extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  RealColumn get targetLengthM => real().nullable()();
  TextColumn get habitatSummary => text()();
  BoolColumn get active => boolean()();
  TextColumn get geometry => text()();
  RealColumn get lengthM => real()();

  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "transect";
}
