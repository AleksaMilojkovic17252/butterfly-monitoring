import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_queue.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/sync/sync_api.dart';
import 'package:mobile/core/sync/sync_state_repository.dart';

/// One row of a pull reply, with the server's field names.
typedef _Json = Map<String, dynamic>;

/// Writes pulled pages into the local database. It never calls the network:
/// the sync runner pulls a page and hands it to [applyPage].
///
/// Live rows are upserted. A soft-deleted row arrives as a tombstone
/// `{id, deleted_at, server_version}` and only gets `deleted_at` set (D-049).
/// Entity types without a local table are ignored.
class PullApplier {
  PullApplier(this._db, this._syncState);
  final AppDatabase _db;
  final SyncStateRepository _syncState;

  /// Entity type (also the local table name) to the code that upserts its rows.
  late final Map<String, Future<void> Function(List<_Json>)> _stores = {
    'project': (rows) => _store(_db.projects, rows, _project),
    'project_protocol': (rows) =>
        _store(_db.projectProtocols, rows, _projectProtocol),
    'taxon_list_version': (rows) =>
        _store(_db.taxonListVersions, rows, _taxonListVersion),
    'taxon': (rows) => _store(_db.taxa, rows, _taxon),
    'plant_taxon': (rows) => _store(_db.plantTaxa, rows, _plantTaxon),
    'habitat_type': (rows) => _store(_db.habitatTypes, rows, _habitatType),
    'management_type': (rows) =>
        _store(_db.managementTypes, rows, _managementType),
    'transect': (rows) => _store(_db.transects, rows, _transect),
    'transect_section': (rows) =>
        _store(_db.transectSections, rows, _transectSection),
    'sync_conflict': (rows) => _store(_db.syncConflicts, rows, _syncConflict),
    'survey_visit': (rows) => _store(_db.surveyVisits, rows, _surveyVisit),
    'butterfly_observation': (rows) =>
        _store(_db.butterflyObservations, rows, _butterflyObservation),
  };

  /// Applies one page of [projectId] and saves its cursor, in one transaction:
  /// if anything fails, nothing is kept and the page is pulled again.
  /// `sync_conflict` goes first, so releasing a resolved conflict happens
  /// before the entity rows of the same page are written.
  Future<void> applyPage(String projectId, PullPage page) {
    return _db.transaction(() async {
      final conflicts =
          page.changes['sync_conflict']
              ?.map((e) => {...e, 'project_id': projectId})
              .toList() ??
          [];
      await _applyType('sync_conflict', conflicts);
      for (final entry in page.changes.entries) {
        if (entry.key == 'sync_conflict') continue;
        await _applyType(entry.key, entry.value);
      }
      await _syncState.setLastPullCursor(projectId, page.nextCursor);
    });
  }

  /// Applies the rows of one entity type: tombstones, then the live rows that
  /// are not waiting to be pushed.
  Future<void> _applyType(String type, List<_Json> rows) async {
    final store = _stores[type];
    if (store == null) return;

    final live = <_Json>[];
    for (final row in rows) {
      if (row['deleted_at'] == null) {
        live.add(row);
      } else {
        await _tombstone(type, row);
      }
    }

    if (type == 'survey_visit') {
      await _rejectChangesToLockedVisits(live);
    }
    final fresh = await _withoutPending(type, live);
    await store(fresh);
    if (type == 'sync_conflict') {
      await _releaseConflicts(fresh);
    }
  }

  /// Sets `deleted_at` and `server_version` of a deleted row. The row stays.
  Future<void> _tombstone(String type, _Json row) {
    final deletedAt = DateTime.parse(row['deleted_at'] as String);
    return _db.customUpdate(
      'UPDATE "$type" SET deleted_at = ?, server_version = ? WHERE id = ?',
      variables: [
        Variable.withString(deletedAt.toUtc().toIso8601String()),
        Variable.withInt(row['server_version'] as int),
        Variable.withString(row['id'] as String),
      ],
      updates: {_tableOf(type)!},
    );
  }

  /// Leaves out rows whose local copy is not `synced` (`pending`, `conflict` or
  /// `rejected`): a local change the server has not accepted must not be
  /// overwritten. Only tables with a `sync_status` column are checked
  /// (`sync_conflict`, `survey_visit`).
  Future<List<_Json>> _withoutPending(String type, List<_Json> rows) async {
    final table = _tableOf(type);
    if (rows.isEmpty ||
        table == null ||
        !table.columnsByName.containsKey('sync_status')) {
      return rows;
    }
    final marks = List.filled(rows.length, '?').join(', ');
    final found = await _db
        .customSelect(
          'SELECT id FROM "$type" WHERE sync_status <> ? AND id IN ($marks)',
          variables: [
            Variable.withString(SyncStatus.synced.name),
            for (final row in rows) Variable.withString(row['id'] as String),
          ],
        )
        .get();
    final notSynced = {for (final row in found) row.read<String>('id')};
    return [
      for (final row in rows)
        if (!notSynced.contains(row['id'])) row,
    ];
  }

  /// What a change to a locked visit gets as its `lastError`, in the server's
  /// `[{code, detail, fields}]` form, so the sync screen reads it like a
  /// rejection from the server.
  static final _lockedError = jsonEncode([
    {
      'code': 'visit_locked',
      'detail': 'An admin locked this visit before this change was sent.',
      'fields': <String, Object?>{},
    },
  ]);

  /// For each pulled visit an admin has locked (T042): the local changes never
  /// sent yet (the visit's updates, its track point batches and the changes to
  /// its observations) become `rejected`, because the server would refuse them, and the sync screen
  /// shows them with the lock message. The row is then set `synced`, so the
  /// pending guard lets the server's locked row in and the visit shows as
  /// locked. Changes the server has already rejected keep their message.
  ///
  /// An item sent before (`retryCount` > 0, e.g. its reply was lost) stays
  /// queued: the server may already have it and then answers `duplicate`;
  /// otherwise it rejects it itself. A `conflict` item is left alone: it is
  /// settled on the server, and until then the row keeps its local values.
  Future<void> _rejectChangesToLockedVisits(List<_Json> visits) async {
    for (final visit in visits) {
      if (visit['status'] != 'locked') continue;
      final id = visit['id'] as String;
      // The visit's own items and its track point batches (`entityId` is the
      // visit for both).
      final visitItems =
          _db.syncQueue.entityId.equals(id) &
          _db.syncQueue.entityType.isIn(['survey_visit', 'survey_track_point']);

      // The queue items of the visit's observations: `entityId` is the
      // observation here, so look up which observations the visit has.
      final observations = await (_db.select(
        _db.butterflyObservations,
      )..where((t) => t.surveyVisitId.equals(id))).get();
      final observationItems =
          _db.syncQueue.entityType.equals('butterfly_observation') &
          _db.syncQueue.entityId.isIn([for (final o in observations) o.id]);

      await (_db.update(_db.syncQueue)..where(
            (t) =>
                (visitItems | observationItems) &
                t.status.equalsValue(QueueStatus.queued) &
                t.retryCount.equals(0),
          ))
          .write(
            SyncQueueCompanion(
              status: const Value(QueueStatus.rejected),
              lastError: Value(_lockedError),
            ),
          );

      final conflicts =
          await (_db.select(_db.syncQueue)..where(
                (t) => visitItems & t.status.equalsValue(QueueStatus.conflict),
              ))
              .get();
      if (conflicts.isEmpty) {
        await _setRowStatus('survey_visit', id, SyncStatus.synced);
      }
    }
  }

  /// Frees the queue items held by a conflict the admin has settled. It acts
  /// only when the queue still has a `conflict` item for the entity, so pulling
  /// the same conflict again changes nothing.
  ///
  /// `resolved_server`: the server's version won, so the conflict item and
  /// every later item of the entity are dropped. `resolved_client`: only the
  /// conflict item is dropped, which releases the items behind it.
  Future<void> _releaseConflicts(List<_Json> conflicts) async {
    for (final conflict in conflicts) {
      final status = conflict['status'] as String;
      if (status != 'resolved_server' && status != 'resolved_client') continue;
      final type = conflict['entity_type'] as String;
      final id = conflict['entity_id'] as String;

      final held =
          await (_db.select(_db.syncQueue)
                ..where(
                  (t) =>
                      t.entityType.equals(type) &
                      t.entityId.equals(id) &
                      t.status.equalsValue(QueueStatus.conflict),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
              .get();
      if (held.isEmpty) continue;

      if (status == 'resolved_server') {
        await (_db.delete(_db.syncQueue)..where(
              (t) =>
                  t.entityType.equals(type) &
                  t.entityId.equals(id) &
                  t.seq.isBiggerOrEqualValue(held.first.seq),
            ))
            .go();
        await _setRowStatus(type, id, SyncStatus.synced);
      } else {
        await (_db.delete(
          _db.syncQueue,
        )..where((t) => t.seq.isIn(held.map((item) => item.seq)))).go();
        final left =
            await (_db.select(_db.syncQueue)..where(
                  (t) => t.entityType.equals(type) & t.entityId.equals(id),
                ))
                .get();
        await _setRowStatus(
          type,
          id,
          left.isEmpty ? SyncStatus.synced : SyncStatus.pending,
        );
      }
    }
  }

  /// Sets `sync_status` on an entity row, if its table has that column.
  Future<void> _setRowStatus(String type, String id, SyncStatus status) async {
    final table = _tableOf(type);
    if (table == null || !table.columnsByName.containsKey('sync_status')) {
      return;
    }
    await _db.customUpdate(
      'UPDATE "$type" SET sync_status = ? WHERE id = ?',
      variables: [Variable.withString(status.name), Variable.withString(id)],
      updates: {table},
    );
  }

  /// Every local table by its SQL name (`survey_visit`, ...). Built once, on
  /// first use: the tables do not change while the app runs.
  late final Map<String, TableInfo<Table, Object?>> _tablesByName = {
    for (final table in _db.allTables) table.actualTableName: table,
  };

  /// The local table of an entity type, or null when there is none.
  TableInfo<Table, Object?>? _tableOf(String type) => _tablesByName[type];

  /// Upserts [rows] into [table] in one batch, mapping each with [toRow].
  Future<void> _store<T extends Table, D>(
    TableInfo<T, D> table,
    List<_Json> rows,
    Insertable<D> Function(_Json) toRow,
  ) {
    return _db.batch((batch) {
      batch.insertAllOnConflictUpdate(table, rows.map(toRow).toList());
    });
  }

  // The mappers below read live rows only, so `deleted_at` is always null: a
  // row that was deleted earlier and is live again gets its `deleted_at` reset.

  static ProjectsCompanion _project(_Json json) {
    final area = json['area'];
    return ProjectsCompanion.insert(
      id: json['id'] as String,
      name: json['name'] as String,
      description: Value(json['description'] as String? ?? ''),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: Value(_dateOrNull(json['end_date'])),
      defaultCrs: Value(json['default_crs'] as int),
      active: Value(json['active'] as bool),
      taxonListVersionId: Value(json['taxon_list_version'] as String?),
      area: Value(area == null ? null : jsonEncode(area)),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static ProjectProtocolsCompanion _projectProtocol(_Json json) {
    return ProjectProtocolsCompanion.insert(
      id: json['id'] as String,
      projectId: json['project'] as String,
      protocolVersion: json['protocol_version'] as String,
      surveyMethod: json['survey_method'] as String,
      seasonStart: DateTime.parse(json['season_start'] as String),
      seasonEnd: DateTime.parse(json['season_end'] as String),
      dayStartTime: json['day_start_time'] as String,
      dayEndTime: json['day_end_time'] as String,
      minTemperatureC: _decimal(json['min_temperature_c']),
      sunnyTemperatureC: _decimal(json['sunny_temperature_c']),
      maxCloudCoverPctIfCool: json['max_cloud_cover_pct_if_cool'] as int,
      maxWindBeaufort: json['max_wind_beaufort'] as int,
      allowPrecipitation: json['allow_precipitation'] as bool,
      targetVisitsPerSeason: json['target_visits_per_season'] as int,
      maxDistanceFromTransectM: _decimal(json['max_distance_from_transect_m']),
      observationTimeToleranceMin:
          json['observation_time_tolerance_min'] as int,
      gpsIntervalS: json['gps_interval_s'] as int,
      gpsIntervalBatterySaverS: json['gps_interval_battery_saver_s'] as int,
      gpsAccuracyWarningM: _decimal(json['gps_accuracy_warning_m']),
      gpsGapS: json['gps_gap_s'] as int,
      highCountThreshold: json['high_count_threshold'] as int,
      minCoveragePct: json['min_coverage_pct'] as int,
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static TaxonListVersionsCompanion _taxonListVersion(_Json json) {
    return TaxonListVersionsCompanion.insert(
      id: json['id'] as String,
      versionLabel: json['version_label'] as String,
      source: json['source'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      isCurrent: json['is_current'] as bool,
      notes: json['notes'] as String,
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static TaxaCompanion _taxon(_Json json) {
    return TaxaCompanion.insert(
      id: json['id'] as String,
      scientificName: json['scientific_name'] as String,
      author: json['author'] as String,
      rank: json['rank'] as String,
      genus: json['genus'] as String,
      family: json['family'] as String,
      vernacularNameSr: json['vernacular_name_sr'] as String,
      vernacularNameEn: json['vernacular_name_en'] as String,
      taxonSource: json['taxon_source'] as String,
      taxonSourceId: json['taxon_source_id'] as String,
      active: json['active'] as bool,
      photoRequired: json['photo_required'] as bool,
      identificationNotes: Value(json['identification_notes'] as String?),
      acceptedNameId: Value(json['accepted_name'] as String?),
      introducedInId: json['introduced_in'] as String,
      retiredInId: Value(json['retired_in'] as String?),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static PlantTaxaCompanion _plantTaxon(_Json json) {
    return PlantTaxaCompanion.insert(
      id: json['id'] as String,
      scientificName: json['scientific_name'] as String,
      family: json['family'] as String,
      vernacularName: json['vernacular_name'] as String,
      vernacularNameEn: json['vernacular_name_en'] as String,
      taxonSource: json['taxon_source'] as String,
      taxonSourceId: json['taxon_source_id'] as String,
      active: json['active'] as bool,
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static HabitatTypesCompanion _habitatType(_Json json) {
    return HabitatTypesCompanion.insert(
      id: json['id'] as String,
      code: json['code'] as String,
      nameEn: json['name_en'] as String,
      nameSr: json['name_sr'] as String,
      description: json['description'] as String,
      sortOrder: json['sort_order'] as int,
      active: json['active'] as bool,
      eunisCode: json['eunis_code'] as String,
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static ManagementTypesCompanion _managementType(_Json json) {
    return ManagementTypesCompanion.insert(
      id: json['id'] as String,
      code: json['code'] as String,
      nameEn: json['name_en'] as String,
      nameSr: json['name_sr'] as String,
      description: json['description'] as String,
      sortOrder: json['sort_order'] as int,
      active: json['active'] as bool,
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static TransectsCompanion _transect(_Json json) {
    final targetLength = json['target_length_m'];
    return TransectsCompanion.insert(
      id: json['id'] as String,
      projectId: json['project'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      targetLengthM: Value(
        targetLength == null ? null : _decimal(targetLength),
      ),
      habitatSummary: json['habitat_summary'] as String,
      active: json['active'] as bool,
      geometry: jsonEncode(json['geometry']),
      lengthM: (json['length_m'] as num).toDouble(),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static TransectSectionsCompanion _transectSection(_Json json) {
    return TransectSectionsCompanion.insert(
      id: json['id'] as String,
      transectId: json['transect'] as String,
      sectionCode: json['section_code'] as String,
      sequenceNumber: json['sequence_number'] as int,
      notes: json['notes'] as String,
      habitatTypeId: Value(json['habitat_type'] as String?),
      managementTypeId: Value(json['management_type'] as String?),
      geometry: jsonEncode(json['geometry']),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  static SyncConflictsCompanion _syncConflict(_Json json) {
    return SyncConflictsCompanion.insert(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      operation: json['operation'] as String,
      conflictingFields: jsonEncode(json['conflicting_fields']),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: Value(_dateOrNull(json['resolved_at'])),
      resolutionNote: json['resolution_note'] as String,
      status: json['status'] as String,
      syncStatus: const Value(SyncStatus.synced),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
      projectId: Value(json['project_id'] as String?),
    );
  }

  /// A visit the caller recorded. `pausedAt` is local state and is not in the
  /// pull, so it is left as it is.
  static SurveyVisitsCompanion _surveyVisit(_Json json) {
    return SurveyVisitsCompanion.insert(
      id: json['id'] as String,
      projectId: json['project'] as String,
      transectId: json['transect'] as String,
      observerId: json['observer'] as String,
      protocolVersion: json['protocol_version'] as String,
      surveyMethod: Value(json['survey_method'] as String),
      startedAt: Value(_dateOrNull(json['started_at'])),
      endedAt: Value(_dateOrNull(json['ended_at'])),
      durationSeconds: Value(json['duration_seconds'] as int?),
      pausedSeconds: Value(json['paused_seconds'] as int),
      distanceWalkedM: Value(_decimalOrNull(json['distance_walked_m'])),
      observerCount: Value(json['observer_count'] as int),
      observerNames: Value(json['observer_names'] as String),
      temperatureStartC: Value(_decimalOrNull(json['temperature_start_c'])),
      temperatureEndC: Value(_decimalOrNull(json['temperature_end_c'])),
      windBeaufortStart: Value(json['wind_beaufort_start'] as int?),
      windBeaufortEnd: Value(json['wind_beaufort_end'] as int?),
      cloudCoverStartPct: Value(json['cloud_cover_start_pct'] as int?),
      cloudCoverEndPct: Value(json['cloud_cover_end_pct'] as int?),
      precipitation: Value(json['precipitation'] as String),
      weatherSuitable: Value(json['weather_suitable'] as bool?),
      weatherMissingReason: Value(json['weather_missing_reason'] as String),
      zeroObservationConfirmed: Value(
        json['zero_observation_confirmed'] as bool,
      ),
      notes: Value(json['notes'] as String),
      status: Value(json['status'] as String),
      cancelReason: Value(json['cancel_reason'] as String),
      batterySaverUsed: Value(json['battery_saver_used'] as bool),
      deviceId: Value(json['device_id'] as String),
      createdOffline: Value(json['created_offline'] as bool),
      createdAt: DateTime.parse(json['created_at'] as String),
      syncStatus: const Value(SyncStatus.synced),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  /// An observation the caller recorded. Foreign keys arrive without `_id`, and
  /// the geometry is a GeoJSON Point (`[lon, lat]`). The server's
  /// `validation_*` fields are not in the pull, and the app keeps none.
  static ButterflyObservationsCompanion _butterflyObservation(_Json json) {
    final coordinates = (json['geometry']['coordinates'] as List).cast<num>();
    return ButterflyObservationsCompanion.insert(
      id: json['id'] as String,
      projectId: json['project'] as String,
      surveyVisitId: Value(json['survey_visit'] as String?),
      transectSectionId: Value(json['transect_section'] as String?),
      observedAt: DateTime.parse(json['observed_at'] as String),
      taxonId: json['taxon'] as String,
      count: Value(json['count'] as int),
      lat: coordinates[1].toDouble(),
      lon: coordinates[0].toDouble(),
      locationAccuracyM: Value(_decimalOrNull(json['location_accuracy_m'])),
      identificationConfidence: json['identification_confidence'] as String,
      recordedById: json['recorded_by'] as String,
      sex: Value(json['sex'] as String),
      lifeStage: Value(json['life_stage'] as String),
      behaviour: Value(jsonEncode(json['behaviour'])),
      microhabitat: Value(json['microhabitat'] as String),
      flightDirectionDeg: Value(json['flight_direction_deg'] as int?),
      notes: Value(json['notes'] as String),
      source: Value(json['source'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      syncStatus: const Value(SyncStatus.synced),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: const Value(null),
    );
  }

  /// A decimal arrives as a string (`"13.0"`).
  static double _decimal(Object? value) => double.parse(value as String);

  static double? _decimalOrNull(Object? value) =>
      value == null ? null : _decimal(value);

  static DateTime? _dateOrNull(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}

final pullApplierProvider = Provider<PullApplier>(
  (ref) => PullApplier(
    ref.watch(appDatabaseProvider),
    ref.watch(syncStateRepositoryProvider),
  ),
);
