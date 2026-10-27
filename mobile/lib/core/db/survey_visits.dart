import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/sync_columns.dart';
import 'package:mobile/core/db/transects.dart';

/// Local copy of the server's `survey_visit` table (T034): one walk of a
/// transect. The phone writes it (through `SyncRepository.write`) and pull
/// brings back the caller's own visits.
///
/// Differences from the server:
/// - no `locked_*` columns: a lock arrives as `status = locked`;
/// - no `quality_flags` (server-only);
/// - decimals are `real`;
/// - `pausedAt` is local runtime state of a paused visit and is never sent.
///
/// `status` and `cancelReason` hold the server's values (`in_progress`, ...);
/// the allowed moves are in `features/visits/domain/visit_status.dart`.
class SurveyVisits extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get transectId => text().references(Transects, #id)();
  TextColumn get observerId => text()();
  TextColumn get protocolVersion => text()();
  TextColumn get surveyMethod =>
      text().withDefault(const Constant('pollard_walk'))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Walking time without pauses.
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get pausedSeconds => integer().withDefault(const Constant(0))();

  /// The phone's own figure (sent by T040). The server replaces it with the
  /// distance along the track points when it has at least two usable ones
  /// (T036), and the next pull brings that back.
  RealColumn get distanceWalkedM => real().nullable()();
  IntColumn get observerCount => integer().withDefault(const Constant(1))();
  TextColumn get observerNames => text().withDefault(const Constant(''))();
  RealColumn get temperatureStartC => real().nullable()();
  RealColumn get temperatureEndC => real().nullable()();
  IntColumn get windBeaufortStart => integer().nullable()();
  IntColumn get windBeaufortEnd => integer().nullable()();
  IntColumn get cloudCoverStartPct => integer().nullable()();
  IntColumn get cloudCoverEndPct => integer().nullable()();
  TextColumn get precipitation => text().withDefault(const Constant('none'))();
  BoolColumn get weatherSuitable => boolean().nullable()();
  TextColumn get weatherMissingReason =>
      text().withDefault(const Constant(''))();
  BoolColumn get zeroObservationConfirmed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Set exactly when `status` is `cancelled`, empty otherwise.
  TextColumn get cancelReason => text().withDefault(const Constant(''))();
  BoolColumn get batterySaverUsed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text().withDefault(const Constant(''))();
  BoolColumn get createdOffline =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  /// Local only: when the current pause began, null while walking.
  DateTimeColumn get pausedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('draft','in_progress','completed','synced','reviewed','locked','cancelled'))",
  ];

  @override
  String get tableName => "survey_visit";
}
