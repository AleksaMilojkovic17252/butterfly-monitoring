import 'package:mobile/core/db/app_database.dart';

/// The few columns of a visit that the statistics need (T062). Plain data, so
/// the unit test can build it without a database.
class StatVisit {
  const StatVisit({
    required this.id,
    required this.transectId,
    required this.status,
    required this.startedAt,
    required this.durationSeconds,
    required this.distanceWalkedM,
    required this.zeroObservationConfirmed,
    required this.deletedAt,
  });

  /// From a Drift row.
  factory StatVisit.fromRow(SurveyVisit row) => StatVisit(
    id: row.id,
    transectId: row.transectId,
    status: row.status,
    startedAt: row.startedAt,
    durationSeconds: row.durationSeconds,
    distanceWalkedM: row.distanceWalkedM,
    zeroObservationConfirmed: row.zeroObservationConfirmed,
    deletedAt: row.deletedAt,
  );

  final String id;
  final String transectId;
  final String status;
  final DateTime? startedAt;
  final int? durationSeconds;
  final double? distanceWalkedM;
  final bool zeroObservationConfirmed;
  final DateTime? deletedAt;

  /// Completed, synced, reviewed or locked, not deleted, and started. The same
  /// visits as the server's indicator view (D-099).
  bool get isFinished =>
      deletedAt == null &&
      startedAt != null &&
      const {'completed', 'synced', 'reviewed', 'locked'}.contains(status);
}

/// The few columns of a butterfly observation that the statistics need (T062).
/// [taxonId] is as recorded: the phone has no validated taxon (D-100).
class StatRecord {
  const StatRecord({
    required this.id,
    required this.surveyVisitId,
    required this.taxonId,
    required this.count,
    required this.source,
    required this.observedAt,
    required this.deletedAt,
  });

  /// From a Drift row.
  factory StatRecord.fromRow(ButterflyObservation row) => StatRecord(
    id: row.id,
    surveyVisitId: row.surveyVisitId,
    taxonId: row.taxonId,
    count: row.count,
    source: row.source,
    observedAt: row.observedAt,
    deletedAt: row.deletedAt,
  );

  final String id;

  /// Null for a free record (no visit).
  final String? surveyVisitId;
  final String taxonId;
  final int count;
  final String source;
  final DateTime observedAt;
  final DateTime? deletedAt;
}
