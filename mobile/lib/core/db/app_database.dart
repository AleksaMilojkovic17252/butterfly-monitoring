import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.steps.dart';
import 'package:mobile/core/db/butterfly_observations.dart';
import 'package:mobile/core/db/habitat_features.dart';
import 'package:mobile/core/db/habitat_types.dart';
import 'package:mobile/core/db/management_types.dart';
import 'package:mobile/core/db/photos.dart';
import 'package:mobile/core/db/plant_resource_observations.dart';
import 'package:mobile/core/db/plant_taxa.dart';
import 'package:mobile/core/db/project_protocols.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/route_recording_points.dart';
import 'package:mobile/core/db/route_recordings.dart';
import 'package:mobile/core/db/survey_track_points.dart';
import 'package:mobile/core/db/survey_visits.dart';
import 'package:mobile/core/db/sync_conflicts.dart';
import 'package:mobile/core/db/sync_queue.dart';
import 'package:mobile/core/db/sync_state_entries.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/db/search_text.dart';
import 'package:mobile/core/db/taxa.dart';
import 'package:mobile/core/db/taxon_list_versions.dart';
import 'package:mobile/core/db/taxon_usages.dart';
import 'package:mobile/core/db/transect_proposals.dart';
import 'package:mobile/core/db/transect_sections.dart';
import 'package:mobile/core/db/transects.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ButterflyObservations,
    Projects,
    SyncQueue,
    SyncStateEntries,
    HabitatTypes,
    ManagementTypes,
    PlantTaxa,
    PlantResourceObservations,
    HabitatFeatures,
    Photos,
    ProjectProtocols,
    SyncConflicts,
    SurveyTrackPoints,
    SurveyVisits,
    Taxa,
    TaxonListVersions,
    TaxonUsages,
    TransectProposals,
    TransectSections,
    Transects,
    RouteRecordings,
    RouteRecordingPoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 18;

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
      from5To6: (m, schema) async {
        await m.addColumn(schema.syncConflict, schema.syncConflict.projectId);
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from6To7: (m, schema) async {
        await m.createTable(schema.surveyVisit);
      },
      from7To8: (m, schema) async {
        await m.createTable(schema.surveyTrackPoint);
      },
      from8To9: (m, schema) async {
        // The T007 walking skeleton is gone; observations take its place.
        await m.deleteTable('skeleton_ping');
        await m.createTable(schema.butterflyObservation);
        // Start every pull from the beginning, as from5To6 did: observations the
        // server sent before this version had no table here, so they would
        // otherwise never be pulled.
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from9To10: (m, schema) async {
        await m.createTable(schema.taxonUsage);
        await m.addColumn(schema.taxon, schema.taxon.searchText);
        // Fill the new column for the taxa already on the phone (about 200).
        final taxa = await m.database
            .customSelect(
              'SELECT id, scientific_name, vernacular_name_sr, '
              'vernacular_name_en FROM taxon',
            )
            .get();
        for (final row in taxa) {
          await m.database.customUpdate(
            'UPDATE taxon SET search_text = ? WHERE id = ?',
            variables: [
              Variable.withString(
                taxonSearchText(
                  row.read<String>('scientific_name'),
                  row.read<String>('vernacular_name_sr'),
                  row.read<String>('vernacular_name_en'),
                ),
              ),
              Variable.withString(row.read<String>('id')),
            ],
          );
        }
      },
      from10To11: (m, schema) async {
        // The server added both columns without changing any row, and the
        // defaults agree with it ('[]' and null), so no cursor reset.
        await m.addColumn(schema.surveyVisit, schema.surveyVisit.pauses);
        await m.addColumn(
          schema.surveyVisit,
          schema.surveyVisit.trackPointCount,
        );
      },
      from11To12: (m, schema) async {
        // Photos arrive through pull only after this version, so every
        // project's photo rows need a full pull: start from the beginning.
        await m.createTable(schema.photo);
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from12To13: (m, schema) async {
        await m.createTable(schema.plantResourceObservation);
        await m.addColumn(schema.photo, schema.photo.plantResourceId);
        // Plant rows (and plant photos) the server sent before this version had
        // no table here, so pull skipped them and moved its cursor past them.
        // Start every pull from the beginning, as from11To12 did. Rows waiting
        // in the queue are not touched.
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from13To14: (m, schema) async {
        await m.createTable(schema.habitatFeature);
        // Habitat rows the server sent before this version had no table here,
        // so pull skipped them and moved its cursor past them. Start every pull
        // from the beginning, as from12To13 did. Rows waiting in the queue are
        // not touched.
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from14To15: (m, schema) async {
        await m.addColumn(
          schema.projectProtocol,
          schema.projectProtocol.timeZone,
        );
        // Season dates were stored as local midnight with the phone's offset.
        // The first ten characters are the calendar date, so keep those at UTC
        // midnight: a phone that has not pulled yet still reads the right days.
        await m.database.customStatement(
          "UPDATE project_protocol SET "
          "season_start = substr(season_start, 1, 10) || 'T00:00:00.000Z', "
          "season_end = substr(season_end, 1, 10) || 'T00:00:00.000Z'",
        );
        // The server added time_zone without changing any row's server_version,
        // so pull would never send it. Start every pull from the beginning, as
        // from13To14 did. Rows waiting in the queue are not touched.
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from15To16: (m, schema) async {
        await m.createTable(schema.transectProposal);
        await m.createTable(schema.routeRecording);
        await m.createTable(schema.routeRecordingPoint);
        // Proposals the server sent before this version had no table here, so
        // pull skipped them and moved its cursor past them. Start every pull
        // from the beginning, as from13To14 did. Rows waiting in the queue are
        // not touched.
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from16To17: (m, schema) async {
        await m.addColumn(schema.project, schema.project.closedAt);
        // A project closed before this version has an old server_version, so
        // pull would never send closed_at. Start every pull from the beginning,
        // as from15To16 did. Rows waiting in the queue are not touched.
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
      from17To18: (m, schema) async {
        await m.addColumn(
          schema.plantResourceObservation,
          schema.plantResourceObservation.createdByName,
        );
        await m.addColumn(
          schema.habitatFeature,
          schema.habitatFeature.createdByName,
        );
        await m.addColumn(
          schema.butterflyObservation,
          schema.butterflyObservation.recordedByName,
        );
        // Project members now see each other's records (T112), but a phone's
        // cursor is already past the other members' older rows, so they would
        // never arrive. Start every pull from the beginning, as from16To17
        // did. Rows waiting in the queue are not touched.
        await m.database.customStatement(
          "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
        );
      },
    ),
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
