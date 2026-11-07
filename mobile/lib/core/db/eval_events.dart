import 'package:drift/drift.dart';

/// Events logged while Evaluation mode is on (T073, D-114). Local only: the
/// rows are exported as CSV and never synced, so there are no `SyncColumns`.
@DataClassName('EvalEvent')
class EvalEvents extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get sessionId => text()();

  /// visit_form_open, visit_started, obs_open, obs_saved, tap, error,
  /// sync_start, sync_end.
  TextColumn get eventType => text()();
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  IntColumn get durationMs => integer().nullable()();

  /// JSON object with the event's details.
  TextColumn get payload => text().withDefault(const Constant('{}'))();

  @override
  String get tableName => "eval_event";
}
