import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/sync/sync_state_repository.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/core/validation/visit_rules.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/visits/domain/finish_values.dart';
import 'package:mobile/features/visits/domain/route_length.dart';
import 'package:mobile/features/visits/domain/visit_pauses.dart';
import 'package:mobile/features/visits/domain/visit_rule_error.dart';
import 'package:mobile/features/visits/domain/visit_start_values.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:uuid/uuid.dart';

/// The caller's visits on this phone (T034). Pull brings back only the
/// caller's own visits, so every row here is "mine". Writes go through
/// [SyncRepository.write], so each one is queued for push (T035).
class VisitRepository {
  VisitRepository(this._db, this._sync, this._syncState);
  final AppDatabase _db;
  final SyncRepository _sync;
  final SyncStateRepository _syncState;

  /// The server's entity type and the local table name.
  static const _entityType = 'survey_visit';

  /// Statuses that count as a walked visit in the transect stats: not a draft,
  /// not cancelled. The server counts the same ones
  /// (`surveys.services.COUNTED_STATUSES`).
  static const countedStatuses = [
    'in_progress',
    'completed',
    'synced',
    'reviewed',
    'locked',
  ];

  /// Live list of the transect's walked visits, newest first.
  Stream<List<SurveyVisit>> watchCountedVisits(String transectId) {
    final query = _db.select(_db.surveyVisits)
      ..where(
        (visit) =>
            visit.transectId.equals(transectId) &
            visit.deletedAt.isNull() &
            visit.status.isIn(countedStatuses),
      )
      ..orderBy([(visit) => OrderingTerm.desc(visit.startedAt)]);
    return query.watch();
  }

  /// Live list of the transect's visits that have started, newest first, in
  /// any status (a visit cancelled after it started is listed too).
  Stream<List<SurveyVisit>> watchStartedVisits(String transectId) {
    final query = _db.select(_db.surveyVisits)
      ..where(
        (visit) =>
            visit.transectId.equals(transectId) &
            visit.deletedAt.isNull() &
            visit.startedAt.isNotNull(),
      )
      ..orderBy([(visit) => OrderingTerm.desc(visit.startedAt)]);
    return query.watch();
  }

  /// Live newest draft of the transect by [observerId], or null. The
  /// start-visit form carries on with it, so a transect has at most one draft
  /// from this form. Filtered by observer because logout keeps the local
  /// data, so another user's visits can still be on the phone.
  Stream<SurveyVisit?> watchDraft(String transectId, String observerId) {
    final query = _db.select(_db.surveyVisits)
      ..where(
        (visit) =>
            visit.transectId.equals(transectId) &
            visit.observerId.equals(observerId) &
            visit.deletedAt.isNull() &
            visit.status.equals('draft'),
      )
      ..orderBy([(visit) => OrderingTerm.desc(visit.createdAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  /// Live visit in progress of [observerId], on any transect, or null. Only
  /// one visit is walked (and tracked, T037) at a time.
  Stream<SurveyVisit?> watchInProgress(String observerId) {
    return _inProgressQuery(observerId).watchSingleOrNull();
  }

  /// Live visit in progress that was started on this phone ([deviceId]), by
  /// any user, or null. The GPS tracker follows it (T037), so an expired
  /// session or a logout does not stop the recording of a walk.
  Stream<SurveyVisit?> watchInProgressOnDevice(String deviceId) {
    final query = _db.select(_db.surveyVisits)
      ..where(
        (visit) =>
            visit.deviceId.equals(deviceId) &
            visit.deletedAt.isNull() &
            visit.status.equals('in_progress'),
      )
      ..orderBy([(visit) => OrderingTerm.desc(visit.startedAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  SimpleSelectStatement<$SurveyVisitsTable, SurveyVisit> _inProgressQuery(
    String observerId,
  ) {
    return _db.select(_db.surveyVisits)
      ..where(
        (visit) =>
            visit.observerId.equals(observerId) &
            visit.deletedAt.isNull() &
            visit.status.equals('in_progress'),
      )
      ..orderBy([(visit) => OrderingTerm.desc(visit.startedAt)])
      ..limit(1);
  }

  /// Saves the form as a draft: a new visit when [draft] is null, otherwise
  /// an update of [draft]. [draft] is the row as the form loaded it (see
  /// [_update]). [protocol] gives the project, protocol version and survey
  /// method of a new visit.
  Future<void> saveDraft({
    required SurveyVisit? draft,
    required ProjectProtocol protocol,
    required String transectId,
    required String observerId,
    required VisitStartValues values,
  }) {
    if (draft == null) {
      return _create(
        protocol: protocol,
        transectId: transectId,
        observerId: observerId,
        values: values,
        status: 'draft',
        startedAt: null,
      );
    }
    return _update(draft, values, status: 'draft', startedAt: null);
  }

  /// Starts the visit: `status = in_progress` and `started_at = now`. A new
  /// visit when [draft] is null, otherwise the draft moves on. Returns the
  /// visit's id, for the active visit screen (T039).
  ///
  /// Throws a [StateError] when [observerId] already has a visit in progress:
  /// the form says so first, this is the check that always holds. It runs in
  /// the same transaction as the write.
  ///
  /// GPS tracking starts by itself: `TrackingController` follows the visit
  /// in progress (T037).
  Future<String> start({
    required SurveyVisit? draft,
    required ProjectProtocol protocol,
    required String transectId,
    required String observerId,
    required VisitStartValues values,
  }) {
    final startedAt = DateTime.now().toUtc();
    return _db.transaction(() async {
      final inProgress = await _inProgressQuery(observerId).getSingleOrNull();
      if (inProgress != null) {
        throw StateError('Another visit is already in progress.');
      }
      if (draft == null) {
        return _create(
          protocol: protocol,
          transectId: transectId,
          observerId: observerId,
          values: values,
          status: 'in_progress',
          startedAt: startedAt,
        );
      }
      await _update(draft, values, status: 'in_progress', startedAt: startedAt);
      return draft.id;
    });
  }

  /// Pauses the visit in progress (T039) by storing when the pause began.
  /// `pausedAt` is local and never sent, so nothing is queued; the server
  /// learns about the pause on [resume]. The tracker sees the change and
  /// stops GPS. Pausing a paused visit does nothing.
  Future<void> pause(String visitId) {
    return _db.transaction(() async {
      final current = await _inProgressRow(visitId);
      if (current.pausedAt != null) return;
      final query = _db.update(_db.surveyVisits)
        ..where((v) => v.id.equals(visitId));
      await query.write(
        SurveyVisitsCompanion(pausedAt: Value(DateTime.now().toUtc())),
      );
    });
  }

  /// Ends the pause (T039): the time since `pausedAt` is added to
  /// `pausedSeconds`, the pause is added to the `pauses` list (T040, D-068),
  /// `pausedAt` is cleared, and an `update` with `paused_seconds` and
  /// `pauses` is queued. The tracker sees the change and starts GPS
  /// again. Resuming a visit that is not paused does nothing.
  Future<void> resume(String visitId) {
    return _db.transaction(() async {
      final current = await _inProgressRow(visitId);
      if (current.pausedAt == null) return;
      final (:pausedSeconds, :pauses) = closePause(
        current,
        DateTime.now().toUtc(),
      );

      await _sync.write(
        projectId: current.projectId,
        entityType: _entityType,
        entityId: current.id,
        operation: SyncOperation.update,
        payload: {
          'paused_seconds': pausedSeconds,
          'pauses': pausesPayload(pauses),
        },
        baseVersion: current.serverVersion,
        writeRow: () {
          final query = _db.update(_db.surveyVisits)
            ..where((v) => v.id.equals(visitId));
          return query.write(
            SurveyVisitsCompanion(
              pausedSeconds: Value(pausedSeconds),
              pauses: Value(encodePauses(pauses)),
              pausedAt: const Value(null),
            ),
          );
        },
      );
    });
  }

  /// Finishes the visit (T040): `status = completed`, `ended_at`, the walking
  /// time, the end weather and the true-zero confirmation, in one `update`
  /// that sends only the fields that changed (D-054).
  ///
  /// A pause that is still running is closed first, as [resume] does. When
  /// this phone recorded the route (the visit's `deviceId` is this phone's),
  /// the update also carries the number of track points and the distance
  /// along them, so the caller must stop the tracker first (its buffer is
  /// written then). A visit walked on another phone sends neither: that phone
  /// has the points.
  ///
  /// Throws a [VisitRuleError] when a rule refuses the visit (V05: the end
  /// weather or a reason is missing; V06: the true-zero confirmation does not
  /// match the observations), and a [StateError] when the visit is gone,
  /// locked or not in progress. Nothing is written then.
  Future<void> finish(String visitId, FinishValues values) {
    return _db.transaction(() async {
      final current = await _inProgressRow(visitId);
      if (!appMayMove(current.status, 'completed')) {
        throw StateError('A ${current.status} visit cannot be finished.');
      }
      final protocol = await _protocolOf(current);

      final now = DateTime.now().toUtc();
      // Closes a running pause, as resume does.
      final (:pausedSeconds, :pauses) = closePause(current, now);
      final startedAt = current.startedAt ?? now;
      final walkedSeconds = now.difference(startedAt).inSeconds - pausedSeconds;
      final durationSeconds = walkedSeconds < 0 ? 0 : walkedSeconds;

      // Only the phone that recorded the route knows its points.
      final recordedHere = current.deviceId == await _syncState.deviceId();
      int? trackPointCount;
      double? distanceWalkedM;
      if (recordedHere) {
        final points =
            await (_db.select(_db.surveyTrackPoints)
                  ..where((t) => t.surveyVisitId.equals(visitId))
                  ..orderBy([
                    (t) => OrderingTerm.asc(t.recordedAt),
                    (t) => OrderingTerm.asc(t.sequenceNumber),
                  ]))
                .get();
        trackPointCount = points.length;
        // The server stores one decimal (`Decimal(8,1)`).
        distanceWalkedM = double.parse(
          routeLengthM(points, protocol.gpsAccuracyWarningM).toStringAsFixed(1),
        );
      }

      await _checkFinishRules(current, protocol, values);
      final reason = values.weatherMissingReason.trim();

      // Only what differs from the row: an unchanged field resent after the
      // server moved on would be a conflict (D-054).
      final changed = <String, Object?>{
        'status': 'completed',
        'ended_at': now.toIso8601String(),
        'duration_seconds': durationSeconds,
      };
      void addIfChanged(String field, Object? before, Object? after) {
        if (before != after) changed[field] = after;
      }

      addIfChanged(
        'temperature_end_c',
        current.temperatureEndC,
        values.temperatureEndC,
      );
      addIfChanged(
        'wind_beaufort_end',
        current.windBeaufortEnd,
        values.windBeaufortEnd,
      );
      addIfChanged(
        'cloud_cover_end_pct',
        current.cloudCoverEndPct,
        values.cloudCoverEndPct,
      );
      addIfChanged(
        'weather_missing_reason',
        current.weatherMissingReason,
        reason,
      );
      addIfChanged(
        'zero_observation_confirmed',
        current.zeroObservationConfirmed,
        values.zeroObservationConfirmed,
      );
      addIfChanged('paused_seconds', current.pausedSeconds, pausedSeconds);
      if (current.pausedAt != null) changed['pauses'] = pausesPayload(pauses);
      if (recordedHere) {
        addIfChanged(
          'distance_walked_m',
          current.distanceWalkedM,
          distanceWalkedM,
        );
        addIfChanged(
          'track_point_count',
          current.trackPointCount,
          trackPointCount,
        );
      }

      await _sync.write(
        projectId: current.projectId,
        entityType: _entityType,
        entityId: current.id,
        operation: SyncOperation.update,
        payload: changed,
        baseVersion: current.serverVersion,
        writeRow: () {
          final query = _db.update(_db.surveyVisits)
            ..where((v) => v.id.equals(visitId));
          return query.write(
            SurveyVisitsCompanion(
              status: const Value('completed'),
              endedAt: Value(now),
              durationSeconds: Value(durationSeconds),
              pausedSeconds: Value(pausedSeconds),
              pauses: Value(encodePauses(pauses)),
              pausedAt: const Value(null),
              temperatureEndC: Value(values.temperatureEndC),
              windBeaufortEnd: Value(values.windBeaufortEnd),
              cloudCoverEndPct: Value(values.cloudCoverEndPct),
              weatherMissingReason: Value(reason),
              zeroObservationConfirmed: Value(values.zeroObservationConfirmed),
              // Left as they are for a visit walked on another phone.
              distanceWalkedM: recordedHere
                  ? Value(distanceWalkedM)
                  : const Value.absent(),
              trackPointCount: recordedHere
                  ? Value(trackPointCount)
                  : const Value.absent(),
            ),
          );
        },
      );
    });
  }

  /// Checks the rules of [finish] without writing anything, so the Finish
  /// screen can refuse before it stops the tracker. Throws what [finish]
  /// throws for a rule or a missing visit.
  Future<void> checkCanFinish(String visitId, FinishValues values) {
    return _db.transaction(() async {
      final current = await _inProgressRow(visitId);
      await _checkFinishRules(current, await _protocolOf(current), values);
    });
  }

  /// The project's protocol for [visit], or a [StateError] when it is not on
  /// this phone.
  Future<ProjectProtocol> _protocolOf(SurveyVisit visit) async {
    final protocol = await (_db.select(
      _db.projectProtocols,
    )..where((p) => p.projectId.equals(visit.projectId))).getSingleOrNull();
    if (protocol == null) {
      throw StateError("The project's protocol is not on this phone.");
    }
    return protocol;
  }

  /// Throws a [VisitRuleError] when [current] with [values] may not be
  /// completed: V05 (end weather), V06 (true zero) or V07.
  Future<void> _checkFinishRules(
    SurveyVisit current,
    ProjectProtocol protocol,
    FinishValues values,
  ) async {
    final errors = validateVisit(
      VisitInput(
        status: 'completed',
        startedAt: current.startedAt,
        temperatureStartC: current.temperatureStartC,
        temperatureEndC: values.temperatureEndC,
        windBeaufortStart: current.windBeaufortStart,
        windBeaufortEnd: values.windBeaufortEnd,
        cloudCoverStartPct: current.cloudCoverStartPct,
        cloudCoverEndPct: values.cloudCoverEndPct,
        precipitation: current.precipitation,
        weatherMissingReason: values.weatherMissingReason.trim(),
        zeroObservationConfirmed: values.zeroObservationConfirmed,
      ),
      VisitRuleContext(
        protocol: protocol,
        transectObservationCount: await _transectObservationCount(current.id),
      ),
    );
    if (errors.isNotEmpty) throw VisitRuleError(errors);
  }

  /// The visit [visitId] as it is now, for a pause, resume or finish. Throws a
  /// [StateError] when it is gone or no longer in progress (finished,
  /// cancelled or locked by a pull meanwhile).
  Future<SurveyVisit> _inProgressRow(String visitId) async {
    final current = await (_db.select(
      _db.surveyVisits,
    )..where((v) => v.id.equals(visitId))).getSingleOrNull();
    if (current == null || current.deletedAt != null) {
      throw StateError('The visit is no longer on this phone.');
    }
    if (current.status != 'in_progress') {
      throw StateError('The visit is no longer in progress.');
    }
    return current;
  }

  /// Live row of one visit, or null when it is not on this phone.
  Stream<SurveyVisit?> watchVisit(String visitId) {
    final query = _db.select(_db.surveyVisits)
      ..where((visit) => visit.id.equals(visitId) & visit.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// Number of live observations recorded on a visit, kept up to date (T039's
  /// header counts them).
  Stream<int> watchObservationCount(String visitId) {
    final count = _db.butterflyObservations.id.count();
    final query = _db.selectOnly(_db.butterflyObservations)
      ..addColumns([count])
      ..where(
        _db.butterflyObservations.surveyVisitId.equals(visitId) &
            _db.butterflyObservations.deletedAt.isNull(),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Inserts a new visit and queues its `create`, and returns its id. The
  /// payload holds every field the phone sets; the server fills in the rest.
  Future<String> _create({
    required ProjectProtocol protocol,
    required String transectId,
    required String observerId,
    required VisitStartValues values,
    required String status,
    required DateTime? startedAt,
  }) async {
    final id = const Uuid().v4();
    final deviceId = await _syncState.deviceId();
    final createdAt = DateTime.now().toUtc();

    _checkRules(
      VisitInput(
        status: status,
        startedAt: startedAt,
        temperatureStartC: values.temperatureC,
        windBeaufortStart: values.windBeaufort,
        cloudCoverStartPct: values.cloudCoverPct,
        precipitation: values.precipitation,
      ),
      protocol,
      0,
    );

    await _sync.write(
      projectId: protocol.projectId,
      entityType: _entityType,
      entityId: id,
      operation: SyncOperation.create,
      payload: {
        'project': protocol.projectId,
        'transect': transectId,
        'observer': observerId,
        'protocol_version': protocol.protocolVersion,
        'survey_method': protocol.surveyMethod,
        'device_id': deviceId,
        'created_at': createdAt.toIso8601String(),
        'status': status,
        'started_at': startedAt?.toIso8601String(),
        ...values.toPayload(),
      },
      writeRow: () => _db
          .into(_db.surveyVisits)
          .insert(
            _rowValues(values, status: status, startedAt: startedAt).copyWith(
              id: Value(id),
              projectId: Value(protocol.projectId),
              transectId: Value(transectId),
              observerId: Value(observerId),
              protocolVersion: Value(protocol.protocolVersion),
              surveyMethod: Value(protocol.surveyMethod),
              deviceId: Value(deviceId),
              createdAt: Value(createdAt),
            ),
          ),
    );
    return id;
  }

  /// Updates the visit [opened] and queues an `update` with only the fields
  /// that changed (D-054, D-058): an unchanged field resent after the server
  /// moved on would be a conflict. Nothing changed means nothing is queued.
  ///
  /// [opened] is the row as the form loaded it, and the changes are worked
  /// out against it, not against the row as it is now: a pull may have
  /// updated the row while the form was open, and those server values must
  /// not come back as the user's edits. `baseVersion` and the status check
  /// use the current row.
  Future<void> _update(
    SurveyVisit opened,
    VisitStartValues values, {
    required String status,
    required DateTime? startedAt,
  }) {
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.surveyVisits,
      )..where((v) => v.id.equals(opened.id))).getSingleOrNull();
      if (current == null || current.deletedAt != null) {
        throw StateError('The draft is no longer on this phone.');
      }
      if (visitIsLocked(current.status)) {
        throw StateError('An admin has locked this visit.');
      }
      if (current.status != status && !appMayMove(current.status, status)) {
        throw StateError('A ${current.status} visit cannot become $status.');
      }
      final protocol = await (_db.select(
        _db.projectProtocols,
      )..where((p) => p.projectId.equals(current.projectId))).getSingleOrNull();
      if (protocol == null) {
        throw StateError("The project's protocol is not on this phone.");
      }
      _checkRules(
        _storedInput(current, values, status, startedAt),
        protocol,
        await _transectObservationCount(current.id),
      );
      final before = {
        ...VisitStartValues.fromVisit(opened).toPayload(),
        'status': opened.status,
        'started_at': opened.startedAt?.toUtc().toIso8601String(),
      };
      final after = {
        ...values.toPayload(),
        'status': status,
        'started_at': startedAt?.toIso8601String(),
      };
      final changed = {
        for (final field in after.keys)
          if (after[field] != before[field]) field: after[field],
      };
      if (changed.isEmpty) return;

      await _sync.write(
        projectId: current.projectId,
        entityType: _entityType,
        entityId: current.id,
        operation: SyncOperation.update,
        payload: changed,
        baseVersion: current.serverVersion,
        writeRow: () {
          final query = _db.update(_db.surveyVisits)
            ..where((v) => v.id.equals(current.id));
          return query.write(
            _rowValues(values, status: status, startedAt: startedAt),
          );
        },
      );
    });
  }

  /// The visit as it will be stored: the row [current] with the form's
  /// [values], [status] and [startedAt].
  VisitInput _storedInput(
    SurveyVisit current,
    VisitStartValues values,
    String status,
    DateTime? startedAt,
  ) {
    return VisitInput(
      status: status,
      startedAt: startedAt,
      temperatureStartC: values.temperatureC,
      temperatureEndC: current.temperatureEndC,
      windBeaufortStart: values.windBeaufort,
      windBeaufortEnd: current.windBeaufortEnd,
      cloudCoverStartPct: values.cloudCoverPct,
      cloudCoverEndPct: current.cloudCoverEndPct,
      precipitation: values.precipitation,
      weatherMissingReason: current.weatherMissingReason,
      zeroObservationConfirmed: current.zeroObservationConfirmed,
    );
  }

  /// How many live transect observations the visit has on this phone.
  Future<int> _transectObservationCount(String visitId) {
    final count = _db.butterflyObservations.id.count();
    final query = _db.selectOnly(_db.butterflyObservations)
      ..addColumns([count])
      ..where(
        _db.butterflyObservations.surveyVisitId.equals(visitId) &
            _db.butterflyObservations.deletedAt.isNull() &
            _db.butterflyObservations.source.equals('transect'),
      );
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// Throws a [StateError] with the rule messages (V05-V07) when [input] may
  /// not be stored. V05 and V06 only fire in [finish].
  void _checkRules(VisitInput input, ProjectProtocol protocol, int count) {
    final errors = validateVisit(
      input,
      VisitRuleContext(protocol: protocol, transectObservationCount: count),
    );
    if (errors.isNotEmpty) throw StateError(ruleErrorText(errors));
  }

  /// The form's columns of a visit row, for an insert or an update.
  SurveyVisitsCompanion _rowValues(
    VisitStartValues values, {
    required String status,
    required DateTime? startedAt,
  }) {
    return SurveyVisitsCompanion(
      observerCount: Value(values.observerCount),
      observerNames: Value(values.observerNames),
      temperatureStartC: Value(values.temperatureC),
      windBeaufortStart: Value(values.windBeaufort),
      cloudCoverStartPct: Value(values.cloudCoverPct),
      precipitation: Value(values.precipitation),
      notes: Value(values.notes),
      weatherSuitable: Value(values.weatherSuitable),
      status: Value(status),
      startedAt: Value(startedAt),
    );
  }
}

final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => VisitRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
    ref.watch(syncStateRepositoryProvider),
  ),
);

/// One visit, live, or null when it is not on this phone (T039).
final visitProvider = StreamProvider.family<SurveyVisit?, String>(
  (ref, visitId) => ref.watch(visitRepositoryProvider).watchVisit(visitId),
);

/// The logged-in user's newest draft of a transect, or null (T035).
final transectDraftProvider = StreamProvider.family<SurveyVisit?, String>((
  ref,
  transectId,
) {
  final userId = ref.watch(authControllerProvider).profile?.id;
  if (userId == null) return Stream.value(null);
  return ref.watch(visitRepositoryProvider).watchDraft(transectId, userId);
});

/// The logged-in user's visit in progress on any transect, or null (T035).
final visitInProgressProvider = StreamProvider<SurveyVisit?>((ref) {
  final userId = ref.watch(authControllerProvider).profile?.id;
  if (userId == null) return Stream.value(null);
  return ref.watch(visitRepositoryProvider).watchInProgress(userId);
});

/// The visit in progress started on this phone, by any user, or null (T037).
/// Rebuilt when the logged-in user changes, so the device id is read again
/// after Remove data (which deletes it).
final deviceVisitInProgressProvider = StreamProvider<SurveyVisit?>((
  ref,
) async* {
  ref.watch(authControllerProvider.select((auth) => auth.profile?.id));
  // Everything from `ref` before the await: a login while it waits rebuilds
  // this provider, and the old `ref` may not be used any more.
  final repository = ref.watch(visitRepositoryProvider);
  final deviceId = await ref.watch(syncStateRepositoryProvider).deviceId();
  yield* repository.watchInProgressOnDevice(deviceId);
});

/// Number of observations recorded on a visit (T039's header); null while the
/// first count is loading.
final visitObservationCountProvider = StreamProvider.family<int, String>(
  (ref, visitId) =>
      ref.watch(visitRepositoryProvider).watchObservationCount(visitId),
);
