import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/validation/habitat_rules.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/domain/habitat_input.dart';
import 'package:mobile/features/resources/domain/habitat_names.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:uuid/uuid.dart';

/// The caller's habitat features on this phone (T054). Writes go through
/// [SyncRepository.write], so each one is queued for push, and a feature and
/// its queue item are written in one transaction. Written like
/// `PlantRepository`, without photos or links.
class HabitatRepository {
  HabitatRepository(this._db, this._sync);
  final AppDatabase _db;
  final SyncRepository _sync;

  /// The server's entity type and the local table name. The pull's tombstone
  /// SQL uses the entity type as the table name, so it must not change.
  static const _entityType = 'habitat_feature';

  /// Shown when an edit is refused because the server refused or held back an
  /// earlier change of the feature.
  static const syncProblemMessage =
      'This habitat feature has a sync problem. Open the sync screen first.';

  // --- Reads ---------------------------------------------------------------

  /// Live habitat features of a project, newest first: the user's own and the
  /// other members' (T112). The caller checks that the user is a member.
  Stream<List<HabitatFeature>> watchProjectFeatures(String projectId) {
    final query = _db.select(_db.habitatFeatures)
      ..where((h) => h.projectId.equals(projectId) & h.deletedAt.isNull())
      ..orderBy([
        (h) => OrderingTerm.desc(h.observedAt),
        (h) => OrderingTerm.desc(h.createdAt),
      ]);
    return query.watch();
  }

  /// One live feature, or null when it is not on this phone (or was deleted).
  Stream<HabitatFeature?> watchFeature(String id) {
    final query = _db.select(_db.habitatFeatures)
      ..where((h) => h.id.equals(id) & h.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// Every habitat type on the phone, deactivated and deleted ones included,
  /// by sort order. The form filters them for its picker; tiles and popups use
  /// all of them, so an old feature keeps the name it was saved with.
  Stream<List<HabitatType>> watchHabitatTypes() {
    final query = _db.select(_db.habitatTypes)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch();
  }

  /// Every management type on the phone, as [watchHabitatTypes].
  Stream<List<ManagementType>> watchManagementTypes() {
    final query = _db.select(_db.managementTypes)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch();
  }

  /// The name of the habitat type of feature [id], for a "Saved" message; null
  /// when the feature or its type is not on this phone.
  Future<String?> titleOf(String id) async {
    final feature = await (_db.select(
      _db.habitatFeatures,
    )..where((h) => h.id.equals(id))).getSingleOrNull();
    if (feature == null) return null;
    final type = await (_db.select(
      _db.habitatTypes,
    )..where((t) => t.id.equals(feature.habitatTypeId))).getSingleOrNull();
    return type == null ? null : habitatTypeTitle(type);
  }

  // --- Writes --------------------------------------------------------------

  /// Saves a new habitat feature of [projectId] and returns its id. [visitId]
  /// is the visit it was recorded on, or null (the project's tile).
  ///
  /// Throws a [StateError] when the visit is gone or locked, when there is no
  /// habitat type, or when a rule of `core/validation` (V02, V07, V08) or the
  /// height check refuses the feature; the message says why.
  Future<String> create({
    required String projectId,
    required String? visitId,
    required String createdById,
    required HabitatInput input,
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
            .into(_db.habitatFeatures)
            .insert(
              HabitatFeaturesCompanion.insert(
                id: id,
                projectId: projectId,
                surveyVisitId: Value(visitId),
                habitatTypeId: values.habitatTypeId,
                managementTypeId: Value(values.managementTypeId),
                observedAt: now,
                geometryGeojson: shape.geoJsonText,
                lat: centre.latitude,
                lon: centre.longitude,
                vegetationHeightCm: Value(values.vegetationHeightCm),
                shrubCoverPct: Value(values.shrubCoverPct),
                treeCoverPct: Value(values.treeCoverPct),
                bareGroundPct: Value(values.bareGroundPct),
                flowerAbundanceClass: Value(values.flowerAbundanceClass),
                grazingIntensity: Value(values.grazingIntensity),
                mowingStatus: Value(values.mowingStatus),
                disturbanceType: Value(values.disturbanceType),
                notes: Value(values.notes),
                createdAt: now,
                createdById: Value(createdById),
              ),
            ),
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
  /// Throws a [StateError] when the feature is gone, has a sync problem, its
  /// visit is gone or locked, or a rule refuses it.
  Future<void> update({
    required HabitatFeature opened,
    required HabitatInput input,
  }) {
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.habitatFeatures,
      )..where((h) => h.id.equals(opened.id))).getSingleOrNull();
      if (current == null || current.deletedAt != null) {
        throw StateError('This habitat feature is no longer on this phone.');
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

      final before = HabitatInput.fromRow(opened).toPayload();
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
              _db.habitatFeatures,
            )..where((h) => h.id.equals(current.id))).write(
              HabitatFeaturesCompanion(
                habitatTypeId: changed.containsKey('habitat_type')
                    ? Value(after.habitatTypeId)
                    : const Value.absent(),
                managementTypeId: changed.containsKey('management_type')
                    ? Value(after.managementTypeId)
                    : const Value.absent(),
                vegetationHeightCm: changed.containsKey('vegetation_height_cm')
                    ? Value(after.vegetationHeightCm)
                    : const Value.absent(),
                shrubCoverPct: changed.containsKey('shrub_cover_pct')
                    ? Value(after.shrubCoverPct)
                    : const Value.absent(),
                treeCoverPct: changed.containsKey('tree_cover_pct')
                    ? Value(after.treeCoverPct)
                    : const Value.absent(),
                bareGroundPct: changed.containsKey('bare_ground_pct')
                    ? Value(after.bareGroundPct)
                    : const Value.absent(),
                flowerAbundanceClass:
                    changed.containsKey('flower_abundance_class')
                    ? Value(after.flowerAbundanceClass)
                    : const Value.absent(),
                grazingIntensity: changed.containsKey('grazing_intensity')
                    ? Value(after.grazingIntensity)
                    : const Value.absent(),
                mowingStatus: changed.containsKey('mowing_status')
                    ? Value(after.mowingStatus)
                    : const Value.absent(),
                disturbanceType: changed.containsKey('disturbance_type')
                    ? Value(after.disturbanceType)
                    : const Value.absent(),
                notes: changed.containsKey('notes')
                    ? Value(after.notes)
                    : const Value.absent(),
                geometryGeojson: geometryChanged
                    ? Value(shape.geoJsonText)
                    : const Value.absent(),
                lat: geometryChanged
                    ? Value(centre.latitude)
                    : const Value.absent(),
                lon: geometryChanged
                    ? Value(centre.longitude)
                    : const Value.absent(),
              ),
            ),
      );
    });
  }

  /// Deletes [row]. A create the server never saw disappears with its queue
  /// item; a synced feature is soft-deleted and a `delete` is queued, so other
  /// devices learn of it (`SyncRepository.write` decides which).
  ///
  /// Throws a [StateError] when its visit is locked.
  Future<void> delete(HabitatFeature row) {
    return _db.transaction(() async {
      final current = await (_db.select(
        _db.habitatFeatures,
      )..where((h) => h.id.equals(row.id))).getSingleOrNull();
      if (current == null || current.deletedAt != null) return;
      await _checkUnlockedVisit(current.surveyVisitId);

      await _sync.write(
        projectId: current.projectId,
        entityType: _entityType,
        entityId: current.id,
        operation: SyncOperation.delete,
        payload: {},
        baseVersion: current.serverVersion,
      );
    });
  }

  // --- Helpers -------------------------------------------------------------

  /// Throws a [StateError] with the message of the first problem [input] has:
  /// no habitat type, a rule it breaks, or a height the server cannot store.
  void _check(HabitatInput input, DateTime observedAt) {
    if (input.habitatTypeId.isEmpty) {
      throw StateError('Choose a habitat type');
    }
    final errors = validateHabitatFeature(
      HabitatRuleInput(
        observedAt: observedAt,
        geometryType: switch (input.geometry?.mode) {
          null => null,
          GeometryMode.point => 'Point',
          GeometryMode.line => 'LineString',
          GeometryMode.polygon => 'Polygon',
        },
        points: input.geometry?.points ?? const [],
        flowerAbundanceClass: input.flowerAbundanceClass,
        grazingIntensity: input.grazingIntensity,
        mowingStatus: input.mowingStatus,
        disturbanceType: input.disturbanceType,
      ),
    );
    if (errors.isNotEmpty) throw StateError(ruleErrorText(errors));
    final heightProblem = vegetationHeightProblem(input.vegetationHeightCm);
    if (heightProblem != null) throw StateError(heightProblem);
  }

  /// Throws a [StateError] unless [visitId] is null or the visit is on the
  /// phone and not locked. Any other status is fine: a feature may be recorded
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

final habitatRepositoryProvider = Provider<HabitatRepository>(
  (ref) => HabitatRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  ),
);

/// The project's habitat features, newest first, live (T054): the user's own
/// and the other members' (T112). Empty unless the signed-in user is a member
/// of the project, because logout keeps the local rows.
/// `autoDispose`: the query stops when the list or the map closes.
final habitatFeaturesProvider = StreamProvider.autoDispose
    .family<List<HabitatFeature>, String>((ref, projectId) {
      final profile = ref.watch(authControllerProvider).profile;
      if (profile == null || !profile.isMemberOf(projectId)) {
        return Stream.value(const []);
      }
      return ref
          .watch(habitatRepositoryProvider)
          .watchProjectFeatures(projectId);
    });

/// One habitat feature, live, or null when it is not on this phone.
final habitatFeatureProvider = StreamProvider.autoDispose
    .family<HabitatFeature?, String>(
      (ref, id) => ref.watch(habitatRepositoryProvider).watchFeature(id),
    );

/// Every habitat type on the phone, inactive and deleted ones included.
final habitatTypesProvider = StreamProvider.autoDispose<List<HabitatType>>(
  (ref) => ref.watch(habitatRepositoryProvider).watchHabitatTypes(),
);

/// Every management type on the phone, inactive and deleted ones included.
final managementTypesProvider =
    StreamProvider.autoDispose<List<ManagementType>>(
      (ref) => ref.watch(habitatRepositoryProvider).watchManagementTypes(),
    );
