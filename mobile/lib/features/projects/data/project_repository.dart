import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/http/dio_provider.dart';

/// Projects on this phone. Screens read the local Drift table, so the list
/// works offline. The table is filled by [refreshFromServer] (which finds the
/// projects) and kept up to date by the sync pull.
class ProjectRepository {
  ProjectRepository(this._db, this._dio);
  final AppDatabase _db;
  final Dio _dio;

  /// Live list of local projects, sorted by name. Emits again on every change.
  Stream<List<Project>> watchProjects() {
    final query = _db.select(_db.projects)
      ..where((p) => p.deletedAt.isNull())
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.watch();
  }

  /// The projects on this phone right now, sorted by name. The sync runner
  /// pulls each of them.
  Future<List<Project>> localProjects() {
    final query = _db.select(_db.projects)
      ..where((p) => p.deletedAt.isNull())
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.get();
  }

  /// One project, or null when it is not on this phone.
  Stream<Project?> watchProject(String id) {
    final query = _db.select(_db.projects)
      ..where((p) => p.id.equals(id) & p.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// Downloads the caller's projects and stores them locally. Throws
  /// [DioException] when the server cannot be reached.
  ///
  /// The sync run calls this first: it is how a project that is new to this
  /// user gets a local row, so that the pull then asks for it. Projects the
  /// server no longer returns are kept on the phone (D-036).
  Future<void> refreshFromServer() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/projects');
    final rows = response.data!
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.projects, rows);
    });
  }

  /// Maps one item of the projects API to a Drift row. The pull applier has its
  /// own mapper for the project rows that the pull sends.
  ProjectsCompanion _fromJson(Map<String, dynamic> json) {
    final area = json['area'];
    return ProjectsCompanion.insert(
      id: json['id'] as String,
      name: json['name'] as String,
      description: Value(json['description'] as String? ?? ''),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: Value(_parseDate(json['end_date'])),
      defaultCrs: Value(json['default_crs'] as int),
      active: Value(json['active'] as bool),
      area: Value(area == null ? null : jsonEncode(area)),
      serverVersion: Value(json['server_version'] as int?),
      deletedAt: Value(_parseDate(json['deleted_at'])),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) =>
      ProjectRepository(ref.watch(appDatabaseProvider), ref.watch(dioProvider)),
);

final projectListProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(projectRepositoryProvider).watchProjects(),
);

final projectProvider = StreamProvider.family<Project?, String>(
  (ref, id) => ref.watch(projectRepositoryProvider).watchProject(id),
);
