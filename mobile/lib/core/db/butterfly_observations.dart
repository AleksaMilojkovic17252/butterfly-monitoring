import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/survey_visits.dart';
import 'package:mobile/core/db/sync_columns.dart';
import 'package:mobile/core/db/taxa.dart';

/// Local copy of the server's `butterfly_observation` table (T044): one
/// sighting, with what, how many, where and when. Pull brings back the
/// caller's own observations. The entry screen (T045) writes new ones through
/// `SyncRepository.write`.
///
/// Differences from the server:
/// - `lat`/`lon` instead of a geometry; the payload sends them as a GeoJSON
///   Point;
/// - `behaviour` is a JSON text array, for example `["flying","resting"]`;
/// - decimals are `real`;
/// - no `validation_*` columns and no `quality_flags`: the server owns them,
///   and the app does not show validation;
/// - `photo_count` is not stored anywhere (photos arrive with T049).
class ButterflyObservations extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();

  /// Null for an observation made outside a visit (source `incidental`, ...).
  TextColumn get surveyVisitId =>
      text().nullable().references(SurveyVisits, #id)();

  /// No foreign key: sections are reference data that pull may remove.
  TextColumn get transectSectionId => text().nullable()();
  DateTimeColumn get observedAt => dateTime()();
  TextColumn get taxonId => text().references(Taxa, #id)();
  IntColumn get count => integer().withDefault(const Constant(1))();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get locationAccuracyM => real().nullable()();
  TextColumn get identificationConfidence => text()();
  TextColumn get recordedById => text()();
  TextColumn get sex => text().withDefault(const Constant('unknown'))();
  TextColumn get lifeStage => text().withDefault(const Constant('adult'))();
  TextColumn get behaviour => text().withDefault(const Constant('[]'))();
  TextColumn get microhabitat => text().withDefault(const Constant(''))();
  IntColumn get flightDirectionDeg => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('transect'))();

  /// T051 will fill these two; the server has no such columns yet.
  TextColumn get hostPlantRecordId => text().nullable()();
  TextColumn get nectarPlantRecordId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (count >= 1)",
    "CHECK (source <> 'transect' OR survey_visit_id IS NOT NULL)",
  ];

  /// Same as the entity type, so the pull applier and `SyncRepository` find
  /// the table by it.
  @override
  String get tableName => "butterfly_observation";
}
