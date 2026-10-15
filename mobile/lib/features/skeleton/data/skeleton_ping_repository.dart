import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/http/dio_provider.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:uuid/uuid.dart';

// T044: delete with the skeleton.
class SendResult {
  const SendResult({required this.sent, required this.failed});
  final int sent;
  final int failed;
}

class SkeletonPingRepository {
  SkeletonPingRepository(this._db, this._dio, this._getPosition);

  final AppDatabase _db;
  final Dio _dio;
  final Future<Position> Function() _getPosition;

  Stream<List<SkeletonPing>> watchAll() {
    final query = _db.select(_db.skeletonPings)
      ..orderBy([(t) => OrderingTerm.desc(t.observedAt)]);
    return query.watch();
  }

  Future<void> dropPing(String note) async {
    final position = await _getPosition();
    await _db
        .into(_db.skeletonPings)
        .insert(
          SkeletonPingsCompanion.insert(
            id: const Uuid().v4(),
            observedAt: DateTime.now().toUtc(),
            lat: position.latitude,
            lon: position.longitude,
            note: Value(note.trim()),
          ),
        );
  }

  /// Posts every pending ping. A failed row stays pending for the next try.
  Future<SendResult> sendPending() async {
    final pending = await (_db.select(
      _db.skeletonPings,
    )..where((t) => t.sentAt.isNull())).get();

    var sent = 0;
    var failed = 0;
    for (final ping in pending) {
      try {
        await _dio.post(
          '/api/v1/skeleton/pings',
          data: {
            'id': ping.id,
            'observed_at': ping.observedAt.toUtc().toIso8601String(),
            'lat': ping.lat,
            'lon': ping.lon,
            'note': ping.note,
          },
        );
        await (_db.update(
          _db.skeletonPings,
        )..where((t) => t.id.equals(ping.id))).write(
          SkeletonPingsCompanion(sentAt: Value(DateTime.now().toUtc())),
        );
        sent++;
      } on DioException {
        failed++;
      }
    }
    return SendResult(sent: sent, failed: failed);
  }
}

final skeletonPingRepositoryProvider = Provider<SkeletonPingRepository>((ref) {
  return SkeletonPingRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
    ref.watch(currentPositionProvider),
  );
});
