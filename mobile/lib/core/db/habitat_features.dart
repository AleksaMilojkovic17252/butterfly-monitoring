import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/survey_visits.dart';
import 'package:mobile/core/db/sync_columns.dart';

/// Local copy of the server's `habitat_feature` table (T054): one habitat
/// feature, with its habitat and management type, the vegetation structure and
/// disturbance, and where it is (a point, a line or a polygon). Pull brings
/// back the caller's own features; the habitat form writes new ones through
/// `SyncRepository.write` (`HabitatRepository`).
///
/// Differences from the server:
/// - `geometryGeojson` is the GeoJSON text of the Point, LineString or Polygon,
///   and `lat`/`lon` hold the point, or the centre of the line or polygon, for
///   lists and the map;
/// - the codelist ids have no foreign key, because habitat and management
///   types are reference data that pull may change;
/// - `createdById` and `createdByName` are local-only knowledge the pull
///   carries (T112): the pull brings every member's features of the project,
///   so they tell the user's own features from the others', which are read-only.
@DataClassName('HabitatFeature')
class HabitatFeatures extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();

  /// Null for a feature made outside a visit (from the project's tile).
  TextColumn get surveyVisitId =>
      text().nullable().references(SurveyVisits, #id)();

  /// Required. No foreign key (reference data).
  TextColumn get habitatTypeId => text()();

  /// Null when not recorded. No foreign key (reference data).
  TextColumn get managementTypeId => text().nullable()();
  DateTimeColumn get observedAt => dateTime()();

  /// GeoJSON text of a Point, a LineString or a Polygon.
  TextColumn get geometryGeojson => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();

  /// Centimetres; null when not measured.
  IntColumn get vegetationHeightCm => integer().nullable()();

  /// Cover in percent (0-100); null means "not recorded", which is not 0 %.
  IntColumn get shrubCoverPct => integer().nullable()();
  IntColumn get treeCoverPct => integer().nullable()();
  IntColumn get bareGroundPct => integer().nullable()();

  /// `none`, `low`, `medium` or `high`; `''` when not recorded.
  TextColumn get flowerAbundanceClass =>
      text().withDefault(const Constant(''))();
  TextColumn get grazingIntensity => text().withDefault(const Constant(''))();

  /// `unmown`, `recently_mown`, `mown_this_season` or `unknown`; `''` when not
  /// recorded.
  TextColumn get mowingStatus => text().withDefault(const Constant(''))();

  /// `none`, `trampling`, `vehicle_tracks`, `fire`, `erosion`, `dumping` or
  /// `other`; `''` when not recorded.
  TextColumn get disturbanceType => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  /// Who made the feature. Null until a pull brings it back for a feature made
  /// on this phone, so the repository also sets it when it writes one.
  TextColumn get createdById => text().nullable()();

  /// The creator's name, for the "Recorded by" line (T112). Output-only on the
  /// server (`created_by_name`); null for a feature made on this phone until a
  /// pull brings it back.
  TextColumn get createdByName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  /// Same as the entity type, so the pull applier, the tombstone SQL and
  /// `SyncRepository` find the table by it (T053).
  @override
  String get tableName => 'habitat_feature';
}
