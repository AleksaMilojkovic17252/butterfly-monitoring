import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/validation/plant_rules.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/domain/draft_photo.dart';
import 'package:mobile/features/observations/domain/photo_parent.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/domain/plant_input.dart';
import 'package:mobile/features/resources/domain/plant_taxon_search.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:uuid/uuid.dart';

/// The caller's plant records on this phone (T052). Writes go through
/// [SyncRepository.write], so each one is queued for push, and a record, its
/// queue item and its photos are written in one transaction. Written like
/// `ObservationRepository` (D-054, D-082).
class PlantRepository {
  PlantRepository(this._db, this._sync, this._photos);
  final AppDatabase _db;
  final SyncRepository _sync;
  final PhotoRepository _photos;

  /// The server's entity type and the local table name. The pull's tombstone
  /// SQL uses the entity type as the table name (D-086), so it must not change.
  static const _entityType = 'plant_resource_observation';

  /// Shown when an edit is refused because the server refused or held back an
  /// earlier change of the record.
  static const syncProblemMessage =
      'This plant record has a sync problem. Open the sync screen first.';

  // --- Reads ---------------------------------------------------------------

  /// Live plant records of a project, newest first: the user's own and the
  /// other members' (T112). The caller checks that the user is a member.
  Stream<List<PlantResourceObservation>> watchProjectPlants(String projectId) {
    final query = _db.select(_db.plantResourceObservations)
      ..where((p) => p.projectId.equals(projectId) & p.deletedAt.isNull())
      ..orderBy([
        (p) => OrderingTerm.desc(p.observedAt),
        (p) => OrderingTerm.desc(p.createdAt),
      ]);
    return query.watch();
  }

  /// One live record, or null when it is not on this phone (or was deleted).
  Stream<PlantResourceObservation?> watchPlant(String id) {
    final query = _db.select(_db.plantResourceObservations)
      ..where((p) => p.id.equals(id) & p.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// The plants a user may pick: active and not deleted, by scientific name.
  Stream<List<PlantTaxon>> watchPickerPlantTaxa() {
    final query = _db.select(_db.plantTaxa)
      ..where((t) => t.active.equals(true) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.scientificName)]);
    return query.watch();
  }

  /// The plants with the given ids, deactivated ones included, so a record
  /// still shows the name it was saved with.
  Stream<List<PlantTaxon>> watchPlantTaxaByIds(List<String> ids) {
    final query = _db.select(_db.plantTaxa)..where((t) => t.id.isIn(ids));
    return query.watch();
  }

  /// Records a butterfly observation may link to: any member's, live, and
  /// not refused by the server (T112). Newest first.
  Stream<List<PlantResourceObservation>> watchLinkablePlants(String projectId) {
    final query = _db.select(_db.plantResourceObservations)
      ..where(
        (p) =>
            p.projectId.equals(projectId) &
            p.deletedAt.isNull() &
            p.syncStatus.equalsValue(SyncStatus.rejected).not(),
      )
      ..orderBy([
        (p) => OrderingTerm.desc(p.observedAt),
        (p) => OrderingTerm.desc(p.createdAt),
      ]);
    return query.watch();
  }

  /// What to call plant record [id] in a "Saved" message: the plant's name, or
  /// "Unidentified plant". Null when the record is not on this phone.
  Future<String?> titleOf(String id) async {
    final record = await (_db.select(
      _db.plantResourceObservations,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (record == null) return null;
    final taxonId = record.plantTaxonId;
    if (taxonId == null) return 'Unidentified plant';
    final plant = await (_db.select(
      _db.plantTaxa,
    )..where((t) => t.id.equals(taxonId))).getSingleOrNull();
    return plant == null ? 'Plant' : plantTitle(plant);
  }

  // --- Writes --------------------------------------------------------------

  /// Saves a new plant record of [projectId] and returns its id. [visitId] is
  /// the visit it was recorded on, or null (the project's tile). [drafts] are
  /// saved with it in the same transaction, the first as the primary photo.
  ///
  /// Throws a [StateError] when the visit is gone or locked, when the species
  /// and the notes are both empty, or when a rule of `core/validation` (V02,
  /// V07, V08) refuses the record; the message says why.
  Future<String> create({
    required String projectId,
    required String? visitId,
    required String createdById,
    required PlantInput input,
    List<DraftPhoto> drafts = const [],
  }) {
    return _db.transaction(() async {
      await _checkUnlockedVisit(visitId);
      final values = input.trimmed();
      final shape = values.geometry;
      final now = DateTime.now().toUtc();
      _check(values, now);
      if (shape == null) throw StateError(ruleMessage('V02'));

      final id = const Uuid().v4();
      final centre = shape.centroid;
      await _sync.write(
        projectId: projectId,
        entityType: _entityType,
        entityId: id,
        operation: SyncOperation.create,
        payload: {
          'project': projectId,
          'survey_visit': visitId,
          'observed_at': now.toIso8601String(),
          ...values.toPayload(),
          'created_at': now.toIso8601String(),
        },
        writeRow: () => _db
            .into(_db.plantResourceObservations)
            .insert(
              PlantResourceObservationsCompanion.insert(
                id: id,
                projectId: projectId,
                surveyVisitId: Value(visitId),
                plantTaxonId: Value(values.plantTaxonId),
                resourceType: values.resourceType,
                observedAt: now,
                geometryGeojson: shape.geoJsonText,
                lat: centre.latitude,
                lon: centre.longitude,
                abundanceClass: Value(values.abundanceClass),
                phenologyStage: Value(values.phenologyStage),
                floweringIntensity: Value(values.floweringIntensity),
                eggsPresent: Value(values.eggsPresent),
                larvaePresent: Value(values.larvaePresent),
                feedingDamagePresent: Value(values.feedingDamagePresent),
                notes: Value(values.notes),
                createdAt: now,
                createdById: Value(createdById),
              ),
            ),
      );
      await _photos.addDrafts(
        parent: PhotoParent.plant(
          id: id,
          projectId: projectId,
          surveyVisitId: visitId,
        ),
        drafts: drafts,
        firstIsPrimary: true,
      );
      return id;
    });
  }

  /// Changes [opened] to [input] and queues an `update` with only the fields
  /// that changed (D-054, D-082). Nothing changed means nothing is queued. The
  /// project and the visit are never changed or sent.
  ///
  /// [opened] is the row as the form loaded it. The changes are worked out
  /// against it, not against the row as it is now: a pull may have updated the
  /// row while the form was open, and those server values must not come back
  /// as the user's edits. `baseVersion` uses the current row.
  ///
  /// Throws a [StateError] when the record is gone, has a sync problem, its
  /// visit is gone or locked, or a rule refuses it.
  Future<void> update({
    required PlantResourceObservation opened,
    required PlantInput input,
  }) {
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.plantResourceObservations,
      )..where((p) => p.id.equals(opened.id))).getSingleOrNull();
      if (current == null || current.deletedAt != null) {
        throw StateError('This plant record is no longer on this phone.');
      }
      // A new update would stack on an item the server refused or that is
      // held back.
      if (current.syncStatus == SyncStatus.conflict ||
          current.syncStatus == SyncStatus.rejected) {
        throw StateError(syncProblemMessage);
      }
      await _checkUnlockedVisit(current.surveyVisitId);

      final after = input.trimmed();
      final shape = after.geometry;
      _check(after, current.observedAt);
      if (shape == null) throw StateError(ruleMessage('V02'));

      final before = PlantInput.fromRow(opened).toPayload();
      final afterValues = after.toPayload();
      // Compared as JSON text: the geometry is a map, and `!=` on two maps
      // compares identity, so it would always look changed.
      final changed = {
        for (final field in afterValues.keys)
          if (jsonEncode(afterValues[field]) != jsonEncode(before[field]))
            field: afterValues[field],
      };
      if (changed.isEmpty) return;

      final geometryChanged = changed.containsKey('geometry');
      final centre = shape.centroid;
      await _sync.write(
        projectId: current.projectId,
        entityType: _entityType,
        entityId: current.id,
        operation: SyncOperation.update,
        payload: changed,
        baseVersion: current.serverVersion,
        // Only the changed columns, so a value a pull brought in is kept.
        writeRow: () =>
            (_db.update(
              _db.plantResourceObservations,
            )..where((p) => p.id.equals(current.id))).write(
              PlantResourceObservationsCompanion(
                plantTaxonId: changed.containsKey('plant_taxon')
                    ? Value(after.plantTaxonId)
                    : const Value.absent(),
                resourceType: changed.containsKey('resource_type')
                    ? Value(after.resourceType)
                    : const Value.absent(),
                abundanceClass: changed.containsKey('abundance_class')
                    ? Value(after.abundanceClass)
                    : const Value.absent(),
                phenologyStage: changed.containsKey('phenology_stage')
                    ? Value(after.phenologyStage)
                    : const Value.absent(),
                floweringIntensity: changed.containsKey('flowering_intensity')
                    ? Value(after.floweringIntensity)
                    : const Value.absent(),
                eggsPresent: changed.containsKey('eggs_present')
                    ? Value(after.eggsPresent)
                    : const Value.absent(),
                larvaePresent: changed.containsKey('larvae_present')
                    ? Value(after.larvaePresent)
                    : const Value.absent(),
                feedingDamagePresent:
                    changed.containsKey('feeding_damage_present')
                    ? Value(after.feedingDamagePresent)
                    : const Value.absent(),
                notes: changed.containsKey('notes')
                    ? Value(after.notes)
                    : const Value.absent(),
                // A new shape makes the stored area wrong. It is not sent: the
                // server works out the new one and the next pull brings it
                // back (D-086).
                geometryGeojson: geometryChanged
                    ? Value(shape.geoJsonText)
                    : const Value.absent(),
                lat: geometryChanged
                    ? Value(centre.latitude)
                    : const Value.absent(),
                lon: geometryChanged
                    ? Value(centre.longitude)
                    : const Value.absent(),
                patchAreaM2: geometryChanged
                    ? const Value(null)
                    : const Value.absent(),
              ),
            ),
      );
    });
  }

  /// Deletes [row]: its photos first (and their files, when the server never
  /// saw them), then the record. A create the server never saw disappears with
  /// its queue item; a synced record is soft-deleted and a `delete` is queued,
  /// so other devices learn of it.
  ///
  /// Throws a [StateError] when a live butterfly observation still links to the
  /// record, or when its visit is locked.
  Future<void> delete(PlantResourceObservation row) async {
    final files = await _db.transaction(() async {
      final current = await (_db.select(
        _db.plantResourceObservations,
      )..where((p) => p.id.equals(row.id))).getSingleOrNull();
      if (current == null || current.deletedAt != null) return <String>[];
      await _checkUnlockedVisit(current.surveyVisitId);

      final linked = await _linkedObservationCount(current);
      if (linked > 0) {
        throw StateError(
          'Linked to $linked butterfly '
          '${linked == 1 ? 'record' : 'records'}. Remove the link first.',
        );
      }
      final paths = await _photos.deletePlantPhotos(current.id);
      await _sync.write(
        projectId: current.projectId,
        entityType: _entityType,
        entityId: current.id,
        operation: SyncOperation.delete,
        payload: {},
        baseVersion: current.serverVersion,
      );
      return paths;
    });
    // After the commit: a rollback must not leave rows without their files.
    await _photos.deleteFiles(files);
  }

  // --- Helpers -------------------------------------------------------------

  /// How many live observations link to the plant record as host or nectar.
  /// Only the creator's own observations are counted (T112): another member's
  /// link is a server-side fact this phone may not have pulled, so the check
  /// cannot cover it, and the creator may delete the record anyway (D-086
  /// keeps links on a soft delete). When the creator is unknown, every live
  /// observation counts, as before.
  Future<int> _linkedObservationCount(PlantResourceObservation plant) async {
    final observations = _db.butterflyObservations;
    final count = observations.id.count();
    var linkedToPlant =
        observations.hostPlantRecordId.equals(plant.id) |
        observations.nectarPlantRecordId.equals(plant.id);
    if (plant.createdById != null) {
      linkedToPlant =
          linkedToPlant & observations.recordedById.equals(plant.createdById!);
    }
    final query = _db.selectOnly(observations)
      ..addColumns([count])
      ..where(observations.deletedAt.isNull() & linkedToPlant);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Throws a [StateError] with the message of the first rule [input] breaks.
  void _check(PlantInput input, DateTime observedAt) {
    final errors = validatePlantResource(
      PlantRuleInput(
        observedAt: observedAt,
        resourceType: input.resourceType,
        geometryType: switch (input.geometry?.mode) {
          null => null,
          GeometryMode.point => 'Point',
          GeometryMode.line => 'LineString',
          GeometryMode.polygon => 'Polygon',
        },
        points: input.geometry?.points ?? const [],
        abundanceClass: input.abundanceClass,
        phenologyStage: input.phenologyStage,
        floweringIntensity: input.floweringIntensity,
      ),
    );
    if (errors.isNotEmpty) throw StateError(ruleErrorText(errors));
    if (plantNotesMissing(input.plantTaxonId, input.notes)) {
      throw StateError(plantNotesRequiredMessage);
    }
  }

  /// Throws a [StateError] unless [visitId] is null or the visit is on the
  /// phone and not locked. Any other status is fine: a plant may be recorded
  /// before or after the walk.
  Future<void> _checkUnlockedVisit(String? visitId) async {
    if (visitId == null) return;
    final visit = await (_db.select(
      _db.surveyVisits,
    )..where((v) => v.id.equals(visitId))).getSingleOrNull();
    if (visit == null || visit.deletedAt != null) {
      throw StateError('The visit is no longer on this phone.');
    }
    if (visitIsLocked(visit.status)) {
      throw StateError('The visit is locked.');
    }
  }
}

final plantRepositoryProvider = Provider<PlantRepository>(
  (ref) => PlantRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
    ref.watch(photoRepositoryProvider),
  ),
);

/// The project's plant records, newest first, live (T052): the user's own and
/// the other members' (T112). Empty unless the signed-in user is a member of
/// the project, because logout keeps the local rows.
/// `autoDispose`: the query stops when the list or the map closes.
final plantRecordsProvider = StreamProvider.autoDispose
    .family<List<PlantResourceObservation>, String>((ref, projectId) {
      final profile = ref.watch(authControllerProvider).profile;
      if (profile == null || !profile.isMemberOf(projectId)) {
        return Stream.value(const []);
      }
      return ref.watch(plantRepositoryProvider).watchProjectPlants(projectId);
    });

/// One plant record, live, or null when it is not on this phone.
final plantRecordProvider = StreamProvider.autoDispose
    .family<PlantResourceObservation?, String>(
      (ref, id) => ref.watch(plantRepositoryProvider).watchPlant(id),
    );

/// The plants the species picker offers (active only).
final pickerPlantTaxaProvider = StreamProvider.autoDispose<List<PlantTaxon>>(
  (ref) => ref.watch(plantRepositoryProvider).watchPickerPlantTaxa(),
);

/// Plants by id, deactivated ones included, for names on stored records. The
/// key is the ids joined with commas, so the same ids share one query.
final plantTaxaByIdsProvider = StreamProvider.autoDispose
    .family<List<PlantTaxon>, String>(
      (ref, ids) => ref
          .watch(plantRepositoryProvider)
          .watchPlantTaxaByIds(ids.isEmpty ? [] : ids.split(',')),
    );

/// The records a butterfly observation of the project may link to: any
/// member's (T112). Empty unless the signed-in user is a member.
final linkablePlantsProvider = StreamProvider.autoDispose
    .family<List<PlantResourceObservation>, String>((ref, projectId) {
      final profile = ref.watch(authControllerProvider).profile;
      if (profile == null || !profile.isMemberOf(projectId)) {
        return Stream.value(const []);
      }
      return ref.watch(plantRepositoryProvider).watchLinkablePlants(projectId);
    });
