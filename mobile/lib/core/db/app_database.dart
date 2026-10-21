import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.steps.dart';
import 'package:mobile/core/db/habitat_types.dart';
import 'package:mobile/core/db/management_types.dart';
import 'package:mobile/core/db/plant_taxa.dart';
import 'package:mobile/core/db/project_protocols.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/skeleton_pings.dart';
import 'package:mobile/core/db/sync_conflicts.dart';
import 'package:mobile/core/db/sync_queue.dart';
import 'package:mobile/core/db/sync_state_entries.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/db/taxa.dart';
import 'package:mobile/core/db/taxon_list_versions.dart';
import 'package:mobile/core/db/transect_sections.dart';
import 'package:mobile/core/db/transects.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SkeletonPings,
    Projects,
    SyncQueue,
    SyncStateEntries,
    HabitatTypes,
    ManagementTypes,
    PlantTaxa,
    ProjectProtocols,
    SyncConflicts,
    Taxa,
    TaxonListVersions,
    TransectSections,
    Transects,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'butterfly');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.skeletonPing);
      },
      from2To3: (m, schema) async {
        await m.createTable(schema.project);
      },
      from3To4: (m, schema) async {
        await m.createTable(schema.syncQueue);
        await m.createTable(schema.syncState);
        await m.create(schema.syncQueueEntity);
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.habitatType);
        await m.createTable(schema.managementType);
        await m.createTable(schema.plantTaxon);
        await m.createTable(schema.projectProtocol);
        await m.createTable(schema.syncConflict);
        await m.createTable(schema.taxon);
        await m.createTable(schema.taxonListVersion);
        await m.createTable(schema.transectSection);
        await m.createTable(schema.transect);
        await m.addColumn(schema.project, schema.project.taxonListVersionId);
      },
    ),
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
