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
  };

  /// Applies one page of [projectId] and saves its cursor, in one transaction:
  /// if anything fails, nothing is kept and the page is pulled again.
  /// `sync_conflict` goes first, so releasing a resolved conflict happens
  /// before the entity rows of the same page are written.
  Future<void> applyPage(String projectId, PullPage page) {
    return _db.transaction(() async {
      await _applyType('sync_conflict', page.changes['sync_conflict'] ?? []);
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
  /// overwritten. Only tables with a `sync_status` column are checked (today
  /// `sync_conflict`).
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

  /// The local table of an entity type, or null when there is none.
  TableInfo<Table, Object?>? _tableOf(String type) {
    return _db.allTables.where((t) => t.actualTableName == type).firstOrNull;
  }

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
    );
  }

  /// A decimal arrives as a string (`"13.0"`).
  static double _decimal(Object? value) => double.parse(value as String);

  static DateTime? _dateOrNull(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}

final pullApplierProvider = Provider<PullApplier>(
  (ref) => PullApplier(
    ref.watch(appDatabaseProvider),
    ref.watch(syncStateRepositoryProvider),
  ),
);
