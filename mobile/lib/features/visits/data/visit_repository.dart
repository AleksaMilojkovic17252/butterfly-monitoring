import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/sync/sync_state_repository.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
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
  /// visit when [draft] is null, otherwise the draft moves on.
  ///
  /// Throws a [StateError] when [observerId] already has a visit in progress:
  /// the form says so first, this is the check that always holds. It runs in
  /// the same transaction as the write.
  ///
  /// TODO(T037): start GPS tracking for the visit.
  Future<void> start({
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
        await _create(
          protocol: protocol,
          transectId: transectId,
          observerId: observerId,
          values: values,
          status: 'in_progress',
          startedAt: startedAt,
        );
      } else {
        await _update(
          draft,
          values,
          status: 'in_progress',
          startedAt: startedAt,
        );
      }
    });
  }

  /// Inserts a new visit and queues its `create`. The payload holds every
  /// field the phone sets; the server fills in the rest.
  Future<void> _create({
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
      if (current.status != status && !appMayMove(current.status, status)) {
        throw StateError('A ${current.status} visit cannot become $status.');
      }
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
