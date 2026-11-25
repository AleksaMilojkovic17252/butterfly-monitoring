import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';

/// Local copy of the server's `sensor_station_link` table: a simulated
/// microclimate station of a project (T078). A read-only reference table written
/// only by pull, so it has no `syncStatus` column (D-042).
///
/// The server's FROST ids are not here: the phone never calls FROST.
/// `transectIds` is the server's many-to-many link flattened to a JSON array of
/// transect ids.
class SensorStationLinks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get habitatTypeId => text().nullable()();
  TextColumn get transectIds => text().withDefault(const Constant('[]'))();
  BoolColumn get isSimulated => boolean().withDefault(const Constant(true))();
  BoolColumn get active => boolean()();

  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "sensor_station_link";
}
