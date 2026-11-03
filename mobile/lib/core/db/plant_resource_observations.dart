import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/survey_visits.dart';
import 'package:mobile/core/db/sync_columns.dart';

/// Local copy of the server's `plant_resource_observation` table (T052): one
/// plant record, with which plant, its role for butterflies, where it is (a
/// point or the polygon of a patch) and in what state. Pull brings back the
/// caller's own records; the plant form writes new ones through
/// `SyncRepository.write` (`PlantRepository`).
///
/// Differences from the server:
/// - `geometryGeojson` is the GeoJSON text of the Point or Polygon, and
///   `lat`/`lon` hold the point, or the centroid of the polygon, for lists and
///   the map;
/// - decimals are `real`;
/// - `patchAreaM2` is the server's figure after a pull. The phone never pushes
///   it (D-086): when the shape changes the local value is set to null and the
///   next pull brings the new one;
/// - `createdById` is local-only knowledge the pull now carries, so a second
///   user on the same phone does not see the first user's records.
@DataClassName('PlantResourceObservation')
class PlantResourceObservations extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();

  /// Null for a record made outside a visit (from the project's tile).
  TextColumn get surveyVisitId =>
      text().nullable().references(SurveyVisits, #id)();

  /// No foreign key: plant taxa are reference data that pull may change.
  /// Null for an unidentified plant (then `notes` is required).
  TextColumn get plantTaxonId => text().nullable()();

  /// `larval_host`, `nectar_source`, `oviposition_plant`, `resting_plant` or
  /// `unknown_association`.
  TextColumn get resourceType => text()();
  DateTimeColumn get observedAt => dateTime()();

  /// GeoJSON text of a Point or a Polygon.
  TextColumn get geometryGeojson => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get abundanceClass => text().withDefault(const Constant(''))();
  RealColumn get patchAreaM2 => real().nullable()();
  TextColumn get phenologyStage => text().withDefault(const Constant(''))();
  TextColumn get floweringIntensity => text().withDefault(const Constant(''))();
  BoolColumn get eggsPresent => boolean().nullable()();
  BoolColumn get larvaePresent => boolean().nullable()();
  BoolColumn get feedingDamagePresent => boolean().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  /// Who made the record. Null until a pull brings it back for a record made
  /// on this phone, so the repository also sets it when it writes one.
  TextColumn get createdById => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  /// Same as the entity type, so the pull applier, the tombstone SQL and
  /// `SyncRepository` find the table by it (D-086).
  @override
  String get tableName => 'plant_resource_observation';
}
