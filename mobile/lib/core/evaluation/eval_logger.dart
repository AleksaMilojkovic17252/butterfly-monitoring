import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/evaluation/evaluation_mode.dart';

/// Event types written to the `eval_event` table (T073).
const evalVisitFormOpen = 'visit_form_open';
const evalVisitStarted = 'visit_started';
const evalObsOpen = 'obs_open';
const evalObsSaved = 'obs_saved';
const evalTap = 'tap';
const evalError = 'error';
const evalSyncStart = 'sync_start';
const evalSyncEnd = 'sync_end';

/// Writes evaluation events to the local database and reads them back for the
/// export (T073, D-114).
///
/// [log] never waits and never throws: it returns at once when Evaluation mode
/// is off, otherwise it starts the insert without awaiting it. Drift runs
/// SQLite on a background isolate, so the UI thread only pays for sending the
/// message.
class EvalLogger {
  EvalLogger(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  /// Logs one event if Evaluation mode is on. [payload] is stored as JSON.
  void log(
    String eventType, {
    String? entityId,
    int? durationMs,
    Map<String, Object?> payload = const {},
  }) {
    final mode = _ref.read(evaluationModeProvider);
    final sessionId = mode.sessionId;
    if (!mode.enabled || sessionId == null) return;
    unawaited(
      _db
          .into(_db.evalEvents)
          .insert(
            EvalEventsCompanion.insert(
              sessionId: sessionId,
              eventType: eventType,
              entityId: Value(entityId),
              at: DateTime.now().toUtc(),
              durationMs: Value(durationMs),
              payload: Value(jsonEncode(payload)),
            ),
          )
          .catchError((Object e) {
            debugPrint('eval log failed: $e');
            return 0;
          }),
    );
  }

  /// The number of logged events, kept up to date.
  Stream<int> watchCount() {
    final count = _db.evalEvents.seq.count();
    final query = _db.selectOnly(_db.evalEvents)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  /// Every logged event, oldest first.
  Future<List<EvalEvent>> allEvents() {
    final query = _db.select(_db.evalEvents)
      ..orderBy([(t) => OrderingTerm.asc(t.seq)]);
    return query.get();
  }

  /// Deletes every logged event.
  Future<void> clear() => _db.delete(_db.evalEvents).go();
}

final evalLoggerProvider = Provider<EvalLogger>((ref) => EvalLogger(ref));

final evalEventCountProvider = StreamProvider<int>(
  (ref) => ref.watch(evalLoggerProvider).watchCount(),
);
