import 'package:drift/drift.dart';
import 'package:mobile/core/db/route_recordings.dart';

/// One GPS fix of a route recording (T108). Local only. All fixes are stored;
/// the unusable ones (poor accuracy) are left out when the line is made, as
/// for track points (D-060).
@DataClassName('RouteRecordingPoint')
class RouteRecordingPoints extends Table {
  TextColumn get recordingId => text().references(RouteRecordings, #id)();

  /// Order of the fix within its recording, continuing across app restarts.
  IntColumn get sequenceNumber => integer()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real().nullable()();

  @override
  Set<Column> get primaryKey => {recordingId, sequenceNumber};

  @override
  String get tableName => 'route_recording_point';
}
