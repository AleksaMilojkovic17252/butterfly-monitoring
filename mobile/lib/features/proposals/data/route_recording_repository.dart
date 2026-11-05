import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

/// One GPS fix waiting in the recorder's buffer, with the number it will be
/// stored under.
class NewRecordingPoint {
  const NewRecordingPoint({
    required this.position,
    required this.sequenceNumber,
  });
  final Position position;
  final int sequenceNumber;
}

/// The route recording in progress (T108): the only code that touches the two
/// local tables `route_recording` and `route_recording_point`. Nothing here is
/// synced. Finishing turns the recording into a proposal
/// (`ProposalRepository.createFromRecording`), which deletes it.
///
/// At most one recording exists, because there is one GPS stream (D-087).
class RouteRecordingRepository {
  RouteRecordingRepository(this._db);
  final AppDatabase _db;

  // --- Reads ---------------------------------------------------------------

  /// The recording in progress, or null. Live.
  Stream<RouteRecording?> watchOpen() {
    return _db.select(_db.routeRecordings).watchSingleOrNull();
  }

  /// The stored fixes of recording [id] in recorded order. Live. Fixes still
  /// in the recorder's buffer are not in it yet.
  Stream<List<RouteRecordingPoint>> watchPoints(String id) {
    final query = _db.select(_db.routeRecordingPoints)
      ..where((p) => p.recordingId.equals(id))
      ..orderBy([(p) => OrderingTerm.asc(p.sequenceNumber)]);
    return query.watch();
  }

  /// The number the recording's next fix gets: one more than the highest
  /// stored, or 1 for the first. Read again whenever recording starts, so the
  /// numbers continue after the app was killed.
  Future<int> nextSequenceNumber(String id) async {
    final highest = _db.routeRecordingPoints.sequenceNumber.max();
    final query = _db.selectOnly(_db.routeRecordingPoints)
      ..addColumns([highest])
      ..where(_db.routeRecordingPoints.recordingId.equals(id));
    final row = await query.getSingle();
    return (row.read(highest) ?? 0) + 1;
  }

  /// When the newest stored fix was recorded (UTC), or null.
  Future<DateTime?> lastRecordedAt(String id) async {
    final newest = _db.routeRecordingPoints.recordedAt.max();
    final query = _db.selectOnly(_db.routeRecordingPoints)
      ..addColumns([newest])
      ..where(_db.routeRecordingPoints.recordingId.equals(id));
    final row = await query.getSingle();
    return row.read(newest)?.toUtc();
  }

  // --- Writes --------------------------------------------------------------

  /// Starts a recording for [projectId] and returns its id. [replacesTransectId]
  /// is the transect the route would replace.
  ///
  /// Throws a [StateError] when a recording already exists, or when a visit is
  /// in progress on this phone (one GPS stream, D-087).
  Future<String> start(String projectId, {String? replacesTransectId}) {
    return _db.transaction(() async {
      final open = await _db.select(_db.routeRecordings).get();
      if (open.isNotEmpty) {
        throw StateError('A route recording is already in progress.');
      }
      final visits =
          await (_db.select(_db.surveyVisits)..where(
                (v) => v.deletedAt.isNull() & v.status.equals('in_progress'),
              ))
              .get();
      if (visits.isNotEmpty) {
        throw StateError('Finish the visit in progress first.');
      }
      final id = const Uuid().v4();
      await _db
          .into(_db.routeRecordings)
          .insert(
            RouteRecordingsCompanion.insert(
              id: id,
              projectId: projectId,
              replacesTransectId: Value(replacesTransectId),
              startedAt: DateTime.now().toUtc(),
            ),
          );
      return id;
    });
  }

  /// Pauses recording [id]: stores when the pause began. The recorder sees the
  /// change and stops GPS. Pausing a paused recording does nothing.
  Future<void> pause(String id) {
    return _db.transaction(() async {
      final current = await _row(id);
      if (current == null || current.pausedAt != null) return;
      await (_db.update(_db.routeRecordings)..where((r) => r.id.equals(id)))
          .write(RouteRecordingsCompanion(pausedAt: Value(_now())));
    });
  }

  /// Resumes recording [id]: adds the pause to `pausedSeconds` and clears
  /// `pausedAt`, which makes the recorder start GPS again. Resuming a running
  /// recording does nothing.
  Future<void> resume(String id) {
    return _db.transaction(() async {
      final current = await _row(id);
      final pausedAt = current?.pausedAt;
      if (current == null || pausedAt == null) return;
      final pause = _now().difference(pausedAt).inSeconds;
      await (_db.update(
        _db.routeRecordings,
      )..where((r) => r.id.equals(id))).write(
        RouteRecordingsCompanion(
          pausedAt: const Value(null),
          pausedSeconds: Value(current.pausedSeconds + (pause < 0 ? 0 : pause)),
        ),
      );
    });
  }

  /// Stores [fixes] of recording [id], in one transaction. Does nothing when
  /// the recording is gone (discarded or finished): the fixes would be orphans.
  Future<void> addPoints(String id, List<NewRecordingPoint> fixes) {
    if (fixes.isEmpty) return Future.value();
    return _db.transaction(() async {
      if (await _row(id) == null) return;
      await _db.batch((batch) {
        batch.insertAll(_db.routeRecordingPoints, [
          for (final fix in fixes)
            RouteRecordingPointsCompanion.insert(
              recordingId: id,
              sequenceNumber: fix.sequenceNumber,
              recordedAt: fix.position.timestamp.toUtc(),
              lat: fix.position.latitude,
              lon: fix.position.longitude,
              accuracyM: Value(
                fix.position.accuracy.isFinite && fix.position.accuracy >= 0
                    ? fix.position.accuracy
                    : null,
              ),
            ),
        ]);
      });
    });
  }

  /// Deletes recording [id] and its fixes. Nothing is queued: a recording is
  /// never sent.
  Future<void> discard(String id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.routeRecordingPoints,
      )..where((p) => p.recordingId.equals(id))).go();
      await (_db.delete(
        _db.routeRecordings,
      )..where((r) => r.id.equals(id))).go();
    });
  }

  Future<RouteRecording?> _row(String id) {
    return (_db.select(
      _db.routeRecordings,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  DateTime _now() => DateTime.now().toUtc();
}

final routeRecordingRepositoryProvider = Provider<RouteRecordingRepository>(
  (ref) => RouteRecordingRepository(ref.watch(appDatabaseProvider)),
);

/// The route recording in progress on this phone, or null (T108).
final openRecordingProvider = StreamProvider<RouteRecording?>(
  (ref) => ref.watch(routeRecordingRepositoryProvider).watchOpen(),
);

/// The stored fixes of a recording in recorded order (T108).
/// `autoDispose`: the query stops when the record screen closes.
final recordingPointsProvider = StreamProvider.autoDispose
    .family<List<RouteRecordingPoint>, String>(
      (ref, id) => ref.watch(routeRecordingRepositoryProvider).watchPoints(id),
    );
