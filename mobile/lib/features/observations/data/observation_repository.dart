import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/validation/observation_rules.dart';
import 'package:mobile/core/validation/rule_messages.dart';
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

  /// Live observations of a visit (any source), by the time they were seen,
  /// for the Finish screen (T040).
  Stream<List<ButterflyObservation>> watchVisitObservations(String visitId) {
    final query = _db.select(_db.butterflyObservations)
      ..where((o) => o.surveyVisitId.equals(visitId) & o.deletedAt.isNull())
      ..orderBy([(o) => OrderingTerm.asc(o.observedAt)]);
    return query.watch();
  }

  /// Saves a quick entry of [count] butterflies of [taxonId] seen on [visit] at
  /// ([lat], [lon]), now, and returns the new observation's id. The server
  /// fills in the fields that are not sent (sex, life stage, ...).
  ///
  /// Throws a [StateError] when the visit is gone, no longer in progress or
  /// locked, or when a rule of `core/validation` (V01-V08) refuses the entry;
  /// the message says why.
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
      final current = await _checkVisit(visit.id);

      final id = const Uuid().v4();
      final now = DateTime.now().toUtc();
      // The server stores one decimal (`Decimal(6,1)`).
      final accuracy = accuracyM == null
          ? null
          : double.parse(accuracyM.toStringAsFixed(1));

      final errors = validateObservation(
        ObservationInput(
          observedAt: now,
          count: count,
          lat: lat,
          lon: lon,
          accuracyM: accuracy,
        ),
        await _ruleContext(current, taxonId),
      );
      if (errors.isNotEmpty) throw StateError(ruleErrorText(errors));

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

  /// What the rules need to know besides the observation: the visit as it is
  /// now, the project's protocol and the taxon.
  Future<ObservationRuleContext> _ruleContext(
    SurveyVisit visit,
    String taxonId,
  ) async {
    final protocol = await (_db.select(
      _db.projectProtocols,
    )..where((p) => p.projectId.equals(visit.projectId))).getSingleOrNull();
    if (protocol == null) {
      throw StateError(
        "The project's protocol is not on this phone. Sync first.",
      );
    }
    final taxon = await (_db.select(
      _db.taxa,
    )..where((t) => t.id.equals(taxonId))).getSingleOrNull();
    if (taxon == null) {
      throw StateError('This species is no longer on this phone. Sync first.');
    }
    return ObservationRuleContext(
      visitStatus: visit.status,
      visitStartedAt: visit.startedAt,
      visitEndedAt: visit.endedAt,
      visitZeroConfirmed: visit.zeroObservationConfirmed,
      toleranceMin: protocol.observationTimeToleranceMin,
      accuracyWarningM: protocol.gpsAccuracyWarningM,
      taxonPhotoRequired: taxon.photoRequired,
      photoCount: 0, // TODO(T049): count the observation's photos
    );
  }

  /// Returns the visit as it is now. Throws a [StateError] unless it is still
  /// on the phone, in progress and not locked (the same checks as
  /// `VisitRepository`).
  Future<SurveyVisit> _checkVisit(String visitId) async {
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
    return current;
  }
}

final observationRepositoryProvider = Provider<ObservationRepository>(
  (ref) => ObservationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
    ref.watch(taxonRepositoryProvider),
  ),
);

/// Live observations of a visit (T040). `autoDispose`: the query stops when
/// the Finish screen closes.
final visitObservationsProvider = StreamProvider.autoDispose
    .family<List<ButterflyObservation>, String>(
      (ref, visitId) => ref
          .watch(observationRepositoryProvider)
          .watchVisitObservations(visitId),
    );
