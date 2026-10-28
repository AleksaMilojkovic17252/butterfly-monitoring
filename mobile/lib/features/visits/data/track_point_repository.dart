import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:uuid/uuid.dart';

/// One GPS fix waiting in the tracker's buffer, with the number it will be
/// stored under.
class NewTrackPoint {
  const NewTrackPoint({required this.position, required this.sequenceNumber});
  final Position position;
  final int sequenceNumber;
}

/// The track points of a visit (T037). Writes go through
/// [SyncRepository.writeBatch], so the rows and their `create_batch` queue
/// item are saved in one transaction (D-060).
class TrackPointRepository {
  TrackPointRepository(this._db, this._sync);
  final AppDatabase _db;
  final SyncRepository _sync;

  /// The server's entity type and the local table name.
  static const _entityType = 'survey_track_point';

  /// geolocator's Android client is Google's fused provider when Play
  /// services are on the phone (D-061).
  static const _provider = 'fused';

  /// The number the visit's next point gets: one more than the highest stored,
  /// or 1 for the first. Read again whenever tracking starts, so numbers
  /// continue after the app was killed.
  Future<int> nextSequenceNumber(String visitId) async {
    final highest = _db.surveyTrackPoints.sequenceNumber.max();
    final query = _db.selectOnly(_db.surveyTrackPoints)
      ..addColumns([highest])
      ..where(_db.surveyTrackPoints.surveyVisitId.equals(visitId));
    final row = await query.getSingle();
    return (row.read(highest) ?? 0) + 1;
  }

  /// When the visit's newest stored point was recorded (UTC), or null.
  Future<DateTime?> lastRecordedAt(String visitId) async {
    final newest = _db.surveyTrackPoints.recordedAt.max();
    final query = _db.selectOnly(_db.surveyTrackPoints)
      ..addColumns([newest])
      ..where(_db.surveyTrackPoints.surveyVisitId.equals(visitId));
    final row = await query.getSingle();
    return row.read(newest)?.toUtc();
  }

  /// Live number of stored points of the visit.
  Stream<int> watchCount(String visitId) {
    return _db.surveyTrackPoints
        .count(where: (t) => t.surveyVisitId.equals(visitId))
        .watchSingle();
  }

  /// Live list of the visit's stored points in recorded order: the walked
  /// route (T039). Fixes still in the tracker's buffer are not in it yet.
  Stream<List<SurveyTrackPoint>> watchRoute(String visitId) {
    final query = _db.select(_db.surveyTrackPoints)
      ..where((t) => t.surveyVisitId.equals(visitId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.recordedAt),
        (t) => OrderingTerm.asc(t.sequenceNumber),
      ]);
    return query.watch();
  }

  /// Stores [points] of [visit] and queues them for push. Does nothing when
  /// the visit is no longer on the phone (Remove data, a discarded create):
  /// the points would be orphans pushed for a visit nobody has. Nor when an
  /// admin has locked it: the server would refuse them (T042).
  Future<void> addPoints(SurveyVisit visit, List<NewTrackPoint> points) {
    final rows = [for (final point in points) _row(point)];
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.surveyVisits,
      )..where((v) => v.id.equals(visit.id))).getSingleOrNull();
      if (current == null || current.deletedAt != null) return;
      if (visitIsLocked(current.status)) return;

      await _sync.writeBatch(
        projectId: visit.projectId,
        entityType: _entityType,
        parentId: visit.id,
        rows: [for (final row in rows) row.payload],
        writeRows: () => _db.batch((batch) {
          batch.insertAll(_db.surveyTrackPoints, [
            for (final row in rows) row.companion(visit.id),
          ]);
        }),
      );
    });
  }

  /// A new id and the values of one point, rounded as the server stores
  /// them. The server does not round: a value with more decimals or out of
  /// range is an error, and one bad row rejects the whole batch (D-060). So
  /// a value the server cannot take is sent as null instead.
  _Row _row(NewTrackPoint point) {
    final p = point.position;
    final heading = _round(p.heading, 1);
    final speed = _round(p.speed, 2);
    final accuracy = _round(p.accuracy, 1);
    final altitude = _round(p.altitude, 1);
    return _Row(
      id: const Uuid().v4(),
      recordedAt: p.timestamp.toUtc(),
      lat: p.latitude,
      lon: p.longitude,
      // decimal(6,1), (7,1), (5,2) and (5,1) on the server.
      accuracyM: accuracy != null && accuracy >= 0 && accuracy < 100000
          ? accuracy
          : null,
      altitudeM: altitude != null && altitude.abs() < 1000000 ? altitude : null,
      speedMS: speed != null && speed >= 0 && speed < 1000 ? speed : null,
      headingDeg: heading != null && heading >= 0 && heading < 360
          ? heading
          : null,
      sequenceNumber: point.sequenceNumber,
    );
  }

  /// [value] rounded to [places] decimals; null when it is not a number.
  static double? _round(double value, int places) {
    if (!value.isFinite) return null;
    final factor = places == 1 ? 10 : 100;
    return (value * factor).round() / factor;
  }
}

/// One point as it is stored locally and sent.
class _Row {
  const _Row({
    required this.id,
    required this.recordedAt,
    required this.lat,
    required this.lon,
    required this.accuracyM,
    required this.altitudeM,
    required this.speedMS,
    required this.headingDeg,
    required this.sequenceNumber,
  });
  final String id;
  final DateTime recordedAt;
  final double lat;
  final double lon;
  final double? accuracyM;
  final double? altitudeM;
  final double? speedMS;
  final double? headingDeg;
  final int sequenceNumber;

  /// The `create_batch` row, with server field names. The visit is the queue
  /// item's `entity_id`, so it is not in the row.
  Map<String, Object?> get payload => {
    'id': id,
    'recorded_at': recordedAt.toIso8601String(),
    'geometry': {
      'type': 'Point',
      'coordinates': [lon, lat],
    },
    'accuracy_m': accuracyM,
    'altitude_m': altitudeM,
    'speed_m_s': speedMS,
    'heading_deg': headingDeg,
    'provider': TrackPointRepository._provider,
    'sequence_number': sequenceNumber,
  };

  /// The local row of visit [visitId].
  SurveyTrackPointsCompanion companion(String visitId) {
    return SurveyTrackPointsCompanion.insert(
      id: id,
      surveyVisitId: visitId,
      recordedAt: recordedAt,
      lat: lat,
      lon: lon,
      accuracyM: Value(accuracyM),
      altitudeM: Value(altitudeM),
      speedMS: Value(speedMS),
      headingDeg: Value(headingDeg),
      provider: const Value(TrackPointRepository._provider),
      sequenceNumber: sequenceNumber,
    );
  }
}

final trackPointRepositoryProvider = Provider<TrackPointRepository>(
  (ref) => TrackPointRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  ),
);

/// Live number of stored points of a visit (T037).
final trackPointCountProvider = StreamProvider.family<int, String>(
  (ref, visitId) => ref.watch(trackPointRepositoryProvider).watchCount(visitId),
);

/// Live route of a visit: its stored points in recorded order (T039).
/// `autoDispose`: the query stops when the active visit screen closes.
final visitRouteProvider = StreamProvider.autoDispose
    .family<List<SurveyTrackPoint>, String>(
      (ref, visitId) =>
          ref.watch(trackPointRepositoryProvider).watchRoute(visitId),
    );
