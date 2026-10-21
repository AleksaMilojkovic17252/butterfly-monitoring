import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';

/// Local copy of the server's `project_protocol` table: the survey protocol of
/// one project. A read-only reference table written only by pull, so it has no
/// `syncStatus` column (D-042). Times of day are `HH:MM:SS` text.
class ProjectProtocols extends Table {
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get id => text()();
  TextColumn get protocolVersion => text()();
  TextColumn get surveyMethod => text()();
  DateTimeColumn get seasonStart => dateTime()();
  DateTimeColumn get seasonEnd => dateTime()();
  TextColumn get dayStartTime => text()();
  TextColumn get dayEndTime => text()();
  RealColumn get minTemperatureC => real()();
  RealColumn get sunnyTemperatureC => real()();
  IntColumn get maxCloudCoverPctIfCool => integer()();
  IntColumn get maxWindBeaufort => integer()();
  BoolColumn get allowPrecipitation => boolean()();
  IntColumn get targetVisitsPerSeason => integer()();
  RealColumn get maxDistanceFromTransectM => real()();
  IntColumn get observationTimeToleranceMin => integer()();
  IntColumn get gpsIntervalS => integer()();
  IntColumn get gpsIntervalBatterySaverS => integer()();
  RealColumn get gpsAccuracyWarningM => real()();
  IntColumn get gpsGapS => integer()();
  IntColumn get highCountThreshold => integer()();
  IntColumn get minCoveragePct => integer()();

  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "project_protocol";
}
