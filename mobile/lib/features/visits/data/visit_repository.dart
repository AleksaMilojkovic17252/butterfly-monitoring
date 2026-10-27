import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';

/// The caller's visits on this phone (T034). Pull brings back only the
/// caller's own visits, so every row here is "mine". Read only for now; the
/// start-visit form (T035) adds the writes, through `SyncRepository.write`.
class VisitRepository {
  VisitRepository(this._db);
  final AppDatabase _db;

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
}

final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => VisitRepository(ref.watch(appDatabaseProvider)),
);
