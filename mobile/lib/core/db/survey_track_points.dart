import 'package:drift/drift.dart';
import 'package:mobile/core/db/survey_visits.dart';
import 'package:mobile/core/db/sync_status.dart';

/// Local copy of the server's `survey_track_point` table (T036): one GPS fix
/// of a visit. The tracker (T037) writes them through
/// `SyncRepository.writeBatch`, which queues them as `create_batch` items of
/// their visit. Pull never brings them back (the server's pull scope is empty),
/// so the phone that recorded a route is the only one that has it locally.
///
/// Differences from the server:
/// - `lat`/`lon` instead of a geometry; the payload sends them as a GeoJSON
///   Point;
/// - no `deletedAt`: points are never deleted one by one;
/// - decimals are `real`.
class SurveyTrackPoints extends Table {
  TextColumn get id => text()();
  TextColumn get surveyVisitId => text().references(SurveyVisits, #id)();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get altitudeM => real().nullable()();
  RealColumn get speedMS => real().nullable()();
  RealColumn get headingDeg => real().nullable()();

  /// `gps`, `fused`, `network` or `simulated` (T072 replays).
  TextColumn get provider => text().withDefault(const Constant('gps'))();

  /// Order of the fix within its visit, continuing across app restarts (T037).
  IntColumn get sequenceNumber => integer()();

  /// Always null: the server gives `create_batch` rows no version.
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.name))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {surveyVisitId, sequenceNumber},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (provider IN ('gps','fused','network','simulated'))",
  ];

  @override
  String get tableName => "survey_track_point";
}
