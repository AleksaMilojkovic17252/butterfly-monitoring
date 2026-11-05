import 'package:drift/drift.dart';
import 'package:mobile/core/db/projects.dart';

/// A route proposal being recorded (T108). Local only: nothing here is synced.
/// At most one row exists (`RouteRecordingRepository` enforces it). The row is
/// the truth about the recording, so an app that was killed picks it up again.
/// Finishing turns it into a `transect_proposal`, and the row and its points
/// are deleted.
@DataClassName('RouteRecording')
class RouteRecordings extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();

  /// The transect being replaced; null for a new route. No foreign key
  /// (reference data).
  TextColumn get replacesTransectId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();

  /// When the current pause began; null while recording.
  DateTimeColumn get pausedAt => dateTime().nullable()();

  /// Seconds of earlier pauses, so the walking time can be worked out.
  IntColumn get pausedSeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'route_recording';
}
