import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:uuid/uuid.dart';

/// The caller's butterfly observations on this phone (T045). Writes go through
/// [SyncRepository.write], so each one is queued for push.
class ObservationRepository {
  ObservationRepository(this._db, this._sync, this._taxa);
  final AppDatabase _db;
  final SyncRepository _sync;
  final TaxonRepository _taxa;

  /// The server's entity type and the local table name.
  static const _entityType = 'butterfly_observation';

  /// Saves a quick entry of [count] butterflies of [taxonId] seen on [visit] at
  /// ([lat], [lon]), now, and returns the new observation's id. The server
  /// fills in the fields that are not sent (sex, life stage, ...).
  ///
  /// Throws a [StateError] when the visit is gone, no longer in progress or
  /// locked.
  Future<String> createQuick({
    required SurveyVisit visit,
    required String taxonId,
    required int count,
    required double lat,
    required double lon,
    required double? accuracyM,
    required String? sectionId,
    required String recordedById,
  }) {
    return _db.transaction(() async {
      await _checkVisit(visit.id);

      final id = const Uuid().v4();
      final now = DateTime.now().toUtc();
      // The server stores one decimal (`Decimal(6,1)`).
      final accuracy = accuracyM == null
          ? null
          : double.parse(accuracyM.toStringAsFixed(1));

      await _sync.write(
        projectId: visit.projectId,
        entityType: _entityType,
        entityId: id,
        operation: SyncOperation.create,
        payload: {
          'project': visit.projectId,
          'survey_visit': visit.id,
          'transect_section': sectionId,
          'observed_at': now.toIso8601String(),
          'taxon': taxonId,
          'count': count,
          'geometry': {
            'type': 'Point',
            'coordinates': [lon, lat],
          },
          'location_accuracy_m': accuracy,
          'identification_confidence': 'confirmed_in_field',
          'recorded_by': recordedById,
          'source': 'transect',
          'created_at': now.toIso8601String(),
        },
        writeRow: () => _db
            .into(_db.butterflyObservations)
            .insert(
              ButterflyObservationsCompanion.insert(
                id: id,
                projectId: visit.projectId,
                surveyVisitId: Value(visit.id),
                transectSectionId: Value(sectionId),
                observedAt: now,
                taxonId: taxonId,
                count: Value(count),
                lat: lat,
                lon: lon,
                locationAccuracyM: Value(accuracy),
                identificationConfidence: 'confirmed_in_field',
                recordedById: recordedById,
                createdAt: now,
              ),
            ),
      );
      await _taxa.recordUse(visit.projectId, taxonId);
      return id;
    });
  }

  /// Takes back an observation: a create the server never saw disappears
  /// with its queue item, otherwise the row is soft-deleted and a `delete` is
  /// queued. Does nothing when it is already gone.
  Future<void> undo(String observationId) async {
    final row = await (_db.select(
      _db.butterflyObservations,
    )..where((o) => o.id.equals(observationId))).getSingleOrNull();
    if (row == null || row.deletedAt != null) return;
    await _sync.write(
      projectId: row.projectId,
      entityType: _entityType,
      entityId: row.id,
      operation: SyncOperation.delete,
      payload: {},
      baseVersion: row.serverVersion,
    );
  }

  /// Throws a [StateError] unless the visit is still on the phone, in
  /// progress and not locked (the same checks as `VisitRepository`).
  Future<void> _checkVisit(String visitId) async {
    final current = await (_db.select(
      _db.surveyVisits,
    )..where((v) => v.id.equals(visitId))).getSingleOrNull();
    if (current == null || current.deletedAt != null) {
      throw StateError('The visit is no longer on this phone.');
    }
    if (visitIsLocked(current.status)) {
      throw StateError('The visit is locked.');
    }
    if (current.status != 'in_progress') {
      throw StateError('The visit is no longer in progress.');
    }
  }
}

final observationRepositoryProvider = Provider<ObservationRepository>(
  (ref) => ObservationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
    ref.watch(taxonRepositoryProvider),
  ),
);
