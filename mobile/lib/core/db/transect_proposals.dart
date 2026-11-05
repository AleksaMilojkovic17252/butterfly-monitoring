import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/sync_columns.dart';

/// Local copy of the server's `transect_proposal` table (T108): a route the
/// researcher walked and proposes as a new or replacement transect. The
/// proposals screen writes new ones through `SyncRepository.write`
/// (`ProposalRepository`); pull brings back the caller's own proposals with the
/// admin's review (status, note, the transect made from it).
///
/// Differences from the server:
/// - `geometryGeojson` is the GeoJSON text of the LineString;
/// - `replacesTransectId` and `createdTransectId` have no foreign key,
///   because transects are reference data that pull may change;
/// - `lengthM` is the server's figure and stays null until pull brings it
///   (the screen shows its own estimate from the line until then);
/// - `reviewedBy` is not kept.
@DataClassName('TransectProposal')
class TransectProposals extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get name => text()();

  /// `private_property`, `unsafe`, `impassable`, `better_route` or `other`.
  TextColumn get reason => text()();

  /// The transect this route would replace; null for a new route.
  TextColumn get replacesTransectId => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// GeoJSON text of the LineString.
  TextColumn get geometryGeojson => text()();

  /// Times of the first and last GPS fix in the line (UTC).
  DateTimeColumn get recordedFrom => dateTime()();
  DateTimeColumn get recordedTo => dateTime()();

  /// Length in metres, worked out by the server; null until pull.
  RealColumn get lengthM => real().nullable()();

  /// `pending`, `accepted` or `rejected`; set by the server only.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get reviewNote => text().withDefault(const Constant(''))();
  DateTimeColumn get reviewedAt => dateTime().nullable()();

  /// The inactive transect an admin made from the proposal.
  TextColumn get createdTransectId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// Who made the proposal; set when it is written here, and by pull.
  TextColumn get createdById => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  /// Same as the entity type, so the pull applier, the tombstone SQL and
  /// `SyncRepository` find the table by it.
  @override
  String get tableName => 'transect_proposal';
}
