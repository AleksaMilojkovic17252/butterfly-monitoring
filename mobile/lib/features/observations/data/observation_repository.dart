import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/validation/observation_rules.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/observations/domain/draft_photo.dart';
import 'package:mobile/features/observations/domain/observation_details.dart';
import 'package:mobile/features/observations/domain/photo_parent.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:uuid/uuid.dart';

/// The caller's butterfly observations on this phone (T045). Writes go through
/// [SyncRepository.write], so each one is queued for push.
class ObservationRepository {
  ObservationRepository(this._db, this._sync, this._taxa, this._photos);
  final AppDatabase _db;
  final SyncRepository _sync;
  final TaxonRepository _taxa;
  final PhotoRepository _photos;

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

  /// Live observations of a project on this phone that [recordedById] made, by
  /// the time they were seen, for the map (T059). Filtered by user because
  /// logout keeps the local data, so another user's rows can still be here.
  Stream<List<ButterflyObservation>> watchProjectObservations(
    String projectId,
    String recordedById,
  ) {
    final query = _db.select(_db.butterflyObservations)
      ..where(
        (o) =>
            o.projectId.equals(projectId) &
            o.recordedById.equals(recordedById) &
            o.deletedAt.isNull(),
      )
      ..orderBy([(o) => OrderingTerm.asc(o.observedAt)]);
    return query.watch();
  }

  /// Live row of one observation, or null when it is not on this phone (or
  /// was deleted), for the observation detail (T106).
  Stream<ButterflyObservation?> watchObservation(String id) {
    final query = _db.select(_db.butterflyObservations)
      ..where((o) => o.id.equals(id) & o.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// Ids of the visit's live observations that still need a photo (rule W01):
  /// the species has `photo_required` and the observation has no live photo.
  /// For the Finish screen's "Photos missing" tile (T050); it updates as photos
  /// are added.
  Stream<Set<String>> watchMissingPhotos(String visitId) {
    final observations = _db.butterflyObservations;
    final query = _db.select(observations).join([
      innerJoin(_db.taxa, _db.taxa.id.equalsExp(observations.taxonId)),
    ]);
    final livePhotos = _db.select(_db.photos)
      ..where(
        (p) =>
            p.observationId.equalsExp(observations.id) & p.deletedAt.isNull(),
      );
    query.where(
      observations.surveyVisitId.equals(visitId) &
          observations.deletedAt.isNull() &
          _db.taxa.photoRequired.equals(true) &
          notExistsQuery(livePhotos),
    );
    return query.watch().map(
      (rows) => {for (final row in rows) row.readTable(observations).id},
    );
  }

  /// Saves a quick entry of [count] butterflies of [taxonId] seen on [visit] at
  /// ([lat], [lon]), now, and returns the new observation's id. [details] are
  /// the optional extras of the Details form (T046); the default is a plain
  /// quick entry.
  ///
  /// [photos] are saved with the observation in the same transaction, the first
  /// one as the primary photo. A species that needs a photo (W01) is saved
  /// without one too: the rule only warns.
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
    List<DraftPhoto> photos = const [],
    ObservationDetails details = const ObservationDetails(),
  }) {
    return _db.transaction(() async {
      final current = await _checkVisit(visit.id);
      return _insert(
        projectId: visit.projectId,
        visit: current,
        source: 'transect',
        sectionId: sectionId,
        taxonId: taxonId,
        count: count,
        lat: lat,
        lon: lon,
        accuracyM: accuracyM,
        recordedById: recordedById,
        photos: photos,
        details: details,
      );
    });
  }

  /// Saves a free observation (T047): [count] butterflies of [taxonId] seen at
  /// ([lat], [lon]), now, with no visit, and returns its id. [source] is one of
  /// `freeObservationSources`. [accuracyM] is null for a point placed on the map.
  /// The section stays empty (D-096). [photos] and [details] work as in
  /// [createQuick].
  ///
  /// Throws a [StateError] when a rule of `core/validation` refuses the entry.
  Future<String> createFree({
    required String projectId,
    required String source,
    required String taxonId,
    required int count,
    required double lat,
    required double lon,
    required double? accuracyM,
    required String recordedById,
    List<DraftPhoto> photos = const [],
    ObservationDetails details = const ObservationDetails(),
  }) {
    return _db.transaction(
      () => _insert(
        projectId: projectId,
        visit: null,
        source: source,
        sectionId: null,
        taxonId: taxonId,
        count: count,
        lat: lat,
        lon: lon,
        accuracyM: accuracyM,
        recordedById: recordedById,
        photos: photos,
        details: details,
      ),
    );
  }

  /// The write shared by [createQuick] and [createFree]; the caller has opened
  /// the transaction and checked the visit. [visit] is null for a free
  /// observation.
  Future<String> _insert({
    required String projectId,
    required SurveyVisit? visit,
    required String source,
    required String? sectionId,
    required String taxonId,
    required int count,
    required double lat,
    required double lon,
    required double? accuracyM,
    required String recordedById,
    required List<DraftPhoto> photos,
    required ObservationDetails details,
  }) async {
    final extras = details.trimmed();

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
        source: source,
        sex: extras.sex,
        lifeStage: extras.lifeStage,
        confidence: extras.confidence,
        behaviour: extras.behaviour,
        hostPlantRecordId: extras.hostPlantRecordId,
      ),
      await _ruleContext(projectId, visit, taxonId, photos.length),
    );
    if (errors.isNotEmpty) throw StateError(ruleErrorText(errors));

    await _sync.write(
      projectId: projectId,
      entityType: _entityType,
      entityId: id,
      operation: SyncOperation.create,
      payload: {
        'project': projectId,
        'survey_visit': visit?.id,
        'transect_section': sectionId,
        'observed_at': now.toIso8601String(),
        'taxon': taxonId,
        'count': count,
        'geometry': {
          'type': 'Point',
          'coordinates': [lon, lat],
        },
        'location_accuracy_m': accuracy,
        ...extras.toPayload(),
        'recorded_by': recordedById,
        'source': source,
        'created_at': now.toIso8601String(),
      },
      writeRow: () => _db
          .into(_db.butterflyObservations)
          .insert(
            ButterflyObservationsCompanion.insert(
              id: id,
              projectId: projectId,
              surveyVisitId: Value(visit?.id),
              transectSectionId: Value(sectionId),
              observedAt: now,
              taxonId: taxonId,
              count: Value(count),
              lat: lat,
              lon: lon,
              locationAccuracyM: Value(accuracy),
              identificationConfidence: extras.confidence,
              sex: Value(extras.sex),
              lifeStage: Value(extras.lifeStage),
              behaviour: Value(extras.behaviourJson),
              microhabitat: Value(extras.microhabitat),
              flightDirectionDeg: Value(extras.flightDirectionDeg),
              notes: Value(extras.notes),
              hostPlantRecordId: Value(extras.hostPlantRecordId),
              nectarPlantRecordId: Value(extras.nectarPlantRecordId),
              source: Value(source),
              recordedById: recordedById,
              createdAt: now,
            ),
          ),
    );
    await _photos.addDrafts(
      parent: PhotoParent.observation(
        id: id,
        projectId: projectId,
        surveyVisitId: visit?.id,
      ),
      drafts: photos,
      firstIsPrimary: true,
    );
    await _taxa.recordUse(projectId, taxonId);
    return id;
  }

  /// Changes the species, count and details of [opened] and queues an `update`
  /// with only the fields that changed (T046, D-054). Nothing changed means
  /// nothing is queued. Position, time, section and source stay as they are.
  ///
  /// [opened] is the row as the edit sheet loaded it. The changes are worked
  /// out against it, not against the row as it is now: a pull may have updated
  /// the row while the sheet was open, and those server values must not come
  /// back as the user's edits. `baseVersion` uses the current row.
  ///
  /// Throws a [StateError] when the observation is gone, has a sync problem,
  /// its visit is gone or locked, or a rule of `core/validation` refuses it.
  Future<void> updateObservation({
    required ButterflyObservation opened,
    required String taxonId,
    required int count,
    required ObservationDetails details,
  }) {
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.butterflyObservations,
      )..where((o) => o.id.equals(opened.id))).getSingleOrNull();
      if (current == null || current.deletedAt != null) {
        throw StateError('This observation is no longer on this phone.');
      }
      // A new update would stack on an item the server refused or that is
      // held back.
      if (current.syncStatus == SyncStatus.conflict ||
          current.syncStatus == SyncStatus.rejected) {
        throw StateError(syncProblemMessage);
      }
      // An edit is allowed until the visit is locked, so this is not
      // `_checkVisit` (which wants `in_progress`).
      final visit = await _checkUnlockedVisit(current.surveyVisitId);

      final after = details.trimmed();
      final errors = validateObservation(
        ObservationInput(
          observedAt: current.observedAt,
          count: count,
          lat: current.lat,
          lon: current.lon,
          accuracyM: current.locationAccuracyM,
          source: current.source,
          sex: after.sex,
          lifeStage: after.lifeStage,
          confidence: after.confidence,
          behaviour: after.behaviour,
          hostPlantRecordId: after.hostPlantRecordId,
        ),
        // Only the warnings read the photo count, and they are not used here.
        await _ruleContext(current.projectId, visit, taxonId, 0),
      );
      if (errors.isNotEmpty) throw StateError(ruleErrorText(errors));

      final beforeValues = {
        'taxon': opened.taxonId,
        'count': opened.count,
        ...ObservationDetails.fromObservation(opened).trimmed().toPayload(),
      };
      final afterValues = {
        'taxon': taxonId,
        'count': count,
        ...after.toPayload(),
      };
      // Compared as JSON text: `behaviour` is a list, and `!=` on two lists
      // compares identity, so it would always look changed.
      final changed = {
        for (final field in afterValues.keys)
          if (jsonEncode(afterValues[field]) != jsonEncode(beforeValues[field]))
            field: afterValues[field],
      };
      if (changed.isEmpty) return;

      // A link to a plant record (T052) must go out as an item of its own. Merged
      // into an earlier unsent item of this observation it would keep that
      // item's seq, and the plant record queued later would reach the server
      // after the observation that points at it, which is refused. A cleared
      // link (null) can merge: it points at nothing.
      final linksAPlant = [
        'host_plant_record',
        'nectar_plant_record',
      ].any((key) => changed[key] != null);
      await _sync.write(
        projectId: current.projectId,
        entityType: _entityType,
        entityId: current.id,
        operation: SyncOperation.update,
        payload: changed,
        baseVersion: current.serverVersion,
        mergeUpdate: !linksAPlant,
        // Only the changed columns, so a value a pull brought in is kept.
        writeRow: () {
          final query = _db.update(_db.butterflyObservations)
            ..where((o) => o.id.equals(current.id));
          return query.write(
            ButterflyObservationsCompanion(
              taxonId: changed.containsKey('taxon')
                  ? Value(taxonId)
                  : const Value.absent(),
              count: changed.containsKey('count')
                  ? Value(count)
                  : const Value.absent(),
              sex: changed.containsKey('sex')
                  ? Value(after.sex)
                  : const Value.absent(),
              lifeStage: changed.containsKey('life_stage')
                  ? Value(after.lifeStage)
                  : const Value.absent(),
              behaviour: changed.containsKey('behaviour')
                  ? Value(after.behaviourJson)
                  : const Value.absent(),
              identificationConfidence:
                  changed.containsKey('identification_confidence')
                  ? Value(after.confidence)
                  : const Value.absent(),
              microhabitat: changed.containsKey('microhabitat')
                  ? Value(after.microhabitat)
                  : const Value.absent(),
              flightDirectionDeg: changed.containsKey('flight_direction_deg')
                  ? Value(after.flightDirectionDeg)
                  : const Value.absent(),
              notes: changed.containsKey('notes')
                  ? Value(after.notes)
                  : const Value.absent(),
              hostPlantRecordId: changed.containsKey('host_plant_record')
                  ? Value(after.hostPlantRecordId)
                  : const Value.absent(),
              nectarPlantRecordId: changed.containsKey('nectar_plant_record')
                  ? Value(after.nectarPlantRecordId)
                  : const Value.absent(),
            ),
          );
        },
      );
      if (changed.containsKey('taxon')) {
        await _taxa.recordUse(current.projectId, taxonId);
      }
    });
  }

  /// Shown when an edit is refused because the server refused or held back an
  /// earlier change of the observation.
  static const syncProblemMessage =
      'This observation has a sync problem. Open the sync screen first.';

  /// Takes back an observation: a create the server never saw disappears
  /// with its queue item, otherwise the row is soft-deleted and a `delete` is
  /// queued. Its photos are deleted first (and their files, when the server
  /// never saw them). Does nothing when it is already gone.
  Future<void> undo(String observationId) async {
    final row = await (_db.select(
      _db.butterflyObservations,
    )..where((o) => o.id.equals(observationId))).getSingleOrNull();
    if (row == null || row.deletedAt != null) return;
    final files = await _db.transaction(() async {
      final paths = await _photos.deleteObservationPhotos(row.id);
      await _sync.write(
        projectId: row.projectId,
        entityType: _entityType,
        entityId: row.id,
        operation: SyncOperation.delete,
        payload: {},
        baseVersion: row.serverVersion,
      );
      return paths;
    });
    // After the commit: a rollback must not leave rows without their files.
    await _photos.deleteFiles(files);
  }

  /// What the rules need to know besides the observation: its visit (null for
  /// an observation without one, as on the server), the project's protocol and
  /// the taxon.
  Future<ObservationRuleContext> _ruleContext(
    String projectId,
    SurveyVisit? visit,
    String taxonId,
    int photoCount,
  ) async {
    final protocol = await (_db.select(
      _db.projectProtocols,
    )..where((p) => p.projectId.equals(projectId))).getSingleOrNull();
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
      visitStatus: visit?.status,
      visitStartedAt: visit?.startedAt,
      visitEndedAt: visit?.endedAt,
      visitZeroConfirmed: visit?.zeroObservationConfirmed ?? false,
      toleranceMin: protocol.observationTimeToleranceMin,
      accuracyWarningM: protocol.gpsAccuracyWarningM,
      taxonPhotoRequired: taxon.photoRequired,
      photoCount: photoCount,
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

  /// The visit of an observation as it is now, or null when [visitId] is null
  /// (an observation without a visit). Throws a [StateError] when the visit is
  /// not on the phone or is locked; any other status is fine, as in
  /// `PhotoRepository.addToParent`.
  Future<SurveyVisit?> _checkUnlockedVisit(String? visitId) async {
    if (visitId == null) return null;
    final visit = await (_db.select(
      _db.surveyVisits,
    )..where((v) => v.id.equals(visitId))).getSingleOrNull();
    if (visit == null || visit.deletedAt != null) {
      throw StateError('The visit is no longer on this phone.');
    }
    if (visitIsLocked(visit.status)) {
      throw StateError('The visit is locked.');
    }
    return visit;
  }
}

final observationRepositoryProvider = Provider<ObservationRepository>(
  (ref) => ObservationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
    ref.watch(taxonRepositoryProvider),
    ref.watch(photoRepositoryProvider),
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

/// The logged-in user's observations of a project, live, for the map (T059).
/// `autoDispose`: the query stops when the map closes.
final projectObservationsProvider = StreamProvider.autoDispose
    .family<List<ButterflyObservation>, String>((ref, projectId) {
      final userId = ref.watch(authControllerProvider).profile?.id;
      if (userId == null) return Stream.value(const []);
      return ref
          .watch(observationRepositoryProvider)
          .watchProjectObservations(projectId, userId);
    });

/// One observation, live, or null when it is not on this phone (T106).
/// `autoDispose`: the query stops when the detail screen closes.
final observationProvider = StreamProvider.autoDispose
    .family<ButterflyObservation?, String>(
      (ref, id) =>
          ref.watch(observationRepositoryProvider).watchObservation(id),
    );

/// Ids of a visit's observations that still need a photo (W01), live, for the
/// Finish screen (T050). `autoDispose`: the query stops when it closes.
final missingPhotosProvider = StreamProvider.autoDispose
    .family<Set<String>, String>(
      (ref, visitId) =>
          ref.watch(observationRepositoryProvider).watchMissingPhotos(visitId),
    );
