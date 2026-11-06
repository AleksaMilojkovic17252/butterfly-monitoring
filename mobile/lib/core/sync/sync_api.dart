import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/http/dio_provider.dart';

/// What the server did with one pushed mutation.
enum PushResultStatus { applied, merged, conflict, duplicate, rejected }

/// The server's answer for one mutation of a push batch.
class PushResult {
  PushResult({
    required this.mutationId,
    required this.status,
    this.serverVersion,
    this.errors,
  });

  final String mutationId;
  final PushResultStatus status;

  /// The row's new version; null for rejections, conflicts and `create_batch`.
  final int? serverVersion;

  /// The server's `[{code, detail, fields}]` list as a JSON string, ready for
  /// the queue's `lastError` column. Only meaningful for `rejected`.
  final String? errors;

  /// Maps one item of the `results` list of the push reply.
  factory PushResult.fromJson(Map<String, dynamic> json) {
    return PushResult(
      mutationId: json["mutation_id"] as String,
      status: PushResultStatus.values.byName(json['status'] as String),
      errors: jsonEncode(json['errors']),
      serverVersion: (json['server_version'] as int?),
    );
  }
}

/// One page of a pull: the changed rows per entity type, plus the cursor to
/// continue from.
class PullPage {
  PullPage({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
  });

  /// Entity type to rows. Every type has a key; a live row is a full record, a
  /// tombstone is `{id, deleted_at, server_version}`.
  final Map<String, List<Map<String, dynamic>>> changes;

  /// Send this as the next `cursor`.
  final int nextCursor;

  /// True while the server has more rows after this page.
  final bool hasMore;

  /// Maps the body of the pull reply.
  factory PullPage.fromJson(Map<String, dynamic> json) {
    final map = json['changes'] as Map<String, dynamic>;
    final changes = map.map(
      (type, rows) =>
          MapEntry(type, (rows as List).cast<Map<String, dynamic>>()),
    );
    return PullPage(
      changes: changes,
      nextCursor: json['next_cursor'] as int,
      hasMore: json['has_more'] as bool,
    );
  }
}

/// The sync endpoints (`/api/v1/sync/push` and `/pull`, and the offline package
/// status). It only builds requests and maps replies; the runner decides what a failure means, so a
/// [DioException] is not caught here.
class SyncApi {
  final Dio _dio;

  SyncApi(this._dio);

  /// Sends queue items as one batch. The results come back in the same order as
  /// [items]. Throws [DioException] when the server cannot be reached or
  /// answers with an error status.
  Future<List<PushResult>> push(
    String deviceId,
    List<SyncQueueItem> items,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      "/api/v1/sync/push",
      data: {
        'device_id': deviceId,
        'mutations': items
            .map(
              (val) => {
                'mutation_id': val.mutationId,
                'entity_type': val.entityType,
                'entity_id': val.entityId,
                'operation': val.operation,
                'base_version': val.baseVersion,
                'payload': jsonDecode(val.payload),
                'client_created_at': val.createdAt.toUtc().toIso8601String(),
              },
            )
            .toList(),
      },
    );
    final list = response.data!['results'] as List;
    final rows = list.cast<Map<String, dynamic>>();
    return rows.map(PushResult.fromJson).toList();
  }

  /// Fetches one page of changes for [projectId] after [cursor] (0 is the full
  /// initial package). Pass a [cancelToken] to be able to stop the request.
  /// Throws [DioException]; a project the caller cannot see is a 404, and a
  /// cancelled request is a [DioException] too (`CancelToken.isCancel`).
  Future<PullPage> pull(
    String projectId,
    int cursor, {
    int limit = 1000,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      "/api/v1/sync/pull",
      data: {'project_id': projectId, 'cursor': cursor, 'limit': limit},
      cancelToken: cancelToken,
    );
    return PullPage.fromJson(response.data!);
  }

  /// What the server says about a project's offline package
  /// (`GET .../offline-package/status`): the highest `server_version` of the
  /// reference tables, which the app compares with its pull cursor to see if a
  /// download is out of date, and the basemap file if there is one (T060).
  /// Throws [DioException].
  Future<OfflinePackageInfo> offlinePackageStatus(String projectId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      "/api/v1/projects/$projectId/offline-package/status",
    );
    return OfflinePackageInfo.fromJson(response.data!);
  }

  /// Downloads the project's MBTiles basemap to [savePath]
  /// (`GET .../projects/{id}/basemap`, T060). [onReceiveProgress] gets the
  /// bytes received and the total. Throws [DioException]; a cancel through
  /// [cancelToken] is one too.
  Future<void> downloadBasemap(
    String projectId,
    String savePath, {
    CancelToken? cancelToken,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    await _dio.download(
      "/api/v1/projects/$projectId/basemap",
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

/// The answer of `offline-package/status`: [referenceVersion] and, when the
/// project has an MBTiles basemap, its size in bytes and SHA-256.
class OfflinePackageInfo {
  OfflinePackageInfo({
    required this.referenceVersion,
    this.basemapSize,
    this.basemapSha256,
  });

  final int referenceVersion;

  /// Size of the basemap file; null when the project has none.
  final int? basemapSize;

  /// SHA-256 (hex) of the basemap file; null when the project has none.
  final String? basemapSha256;

  /// Whether the project has a basemap on the server.
  bool get hasBasemap => basemapSha256 != null;

  factory OfflinePackageInfo.fromJson(Map<String, dynamic> json) {
    final basemap = json['basemap'] as Map<String, dynamic>?;
    return OfflinePackageInfo(
      referenceVersion: json['reference_version'] as int,
      basemapSize: basemap?['size'] as int?,
      basemapSha256: basemap?['sha256'] as String?,
    );
  }
}

/// The [SyncApi] on the shared [Dio].
final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(ref.watch(dioProvider)),
);
