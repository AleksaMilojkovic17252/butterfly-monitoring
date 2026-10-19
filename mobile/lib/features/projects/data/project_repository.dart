import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/http/dio_provider.dart';

/// Projects on this phone. Screens read the local Drift table, so the list
/// works offline; [refreshFromServer] updates that table when online.
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

  /// One project, or null when it is not on this phone.
  Stream<Project?> watchProject(String id) {
    final query = _db.select(_db.projects)
      ..where((p) => p.id.equals(id) & p.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// Downloads the caller's projects and stores them locally. Throws
  /// [DioException] when the server cannot be reached.
  ///
  /// Interim: the pull (T030/T031) replaces this. Projects the server no
  /// longer returns are kept on the phone (D-036).
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

  /// Maps one item of the projects API to a Drift row.
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
