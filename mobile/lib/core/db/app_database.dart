import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.steps.dart';
import 'package:mobile/core/db/projects.dart';
import 'package:mobile/core/db/skeleton_pings.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SkeletonPings, Projects])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

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
    ),
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
