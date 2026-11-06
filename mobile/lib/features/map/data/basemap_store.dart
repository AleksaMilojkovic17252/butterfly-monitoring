import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/sync/sync_api.dart';
import 'package:mobile/core/sync/sync_state_repository.dart';
import 'package:path_provider/path_provider.dart';

/// The offline basemap files on this phone (T060, D-102): one MBTiles file per
/// project in `<documents>/basemaps/<projectId>.mbtiles`. The SHA-256 of each
/// file is kept in `sync_state`, so the app can tell whether the server has a
/// newer file without reading the file again.
///
/// The files are downloaded package data, like the Drift database: logout
/// keeps them, "Remove all local data" deletes them ([deleteAll]).
class BasemapStore {
  BasemapStore(this._api, this._syncState);
  final SyncApi _api;
  final SyncStateRepository _syncState;

  /// Where the basemap of [projectId] lives (the file may not exist).
  Future<String> pathFor(String projectId) async {
    final documents = await getApplicationDocumentsDirectory();
    return '${documents.path}/basemaps/$projectId.mbtiles';
  }

  /// The basemap file of [projectId], or null when this phone has none.
  Future<File?> fileFor(String projectId) async {
    final file = File(await pathFor(projectId));
    return await file.exists() ? file : null;
  }

  /// SHA-256 of the file we hold for [projectId]; null when there is none.
  /// If the file was lost (cleared by the system), the stored hash is
  /// ignored, so the next Update downloads it again.
  Future<String?> localSha256(String projectId) async {
    if (await fileFor(projectId) == null) return null;
    return _syncState.basemapSha256(projectId);
  }

  /// Downloads the basemap of [projectId] and checks it against the [size] and
  /// [sha256] the server announced. The bytes go to a `.part` file first and
  /// are renamed onto the final path only when they match, so a cancelled or
  /// broken download never replaces a good file (the same idea as the photo
  /// thumbnails, D-083). [onProgress] gets the bytes received and the total.
  /// Throws [DioException] (a cancel is one too) or [StateError] when the
  /// file does not match.
  Future<void> download(
    String projectId, {
    required int size,
    required String sha256,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    final path = await pathFor(projectId);
    await File(path).parent.create(recursive: true);
    final part = File('$path.part');
    try {
      await _api.downloadBasemap(
        projectId,
        part.path,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );
      if (await part.length() != size) {
        throw StateError('The basemap download has the wrong size.');
      }
      if (await _hashOf(part) != sha256) {
        throw StateError('The basemap download is damaged (checksum).');
      }
      await part.rename(path);
      await _syncState.setBasemapSha256(projectId, sha256);
    } finally {
      // After a rename the .part file is gone; after a failure or a cancel it
      // is half a file.
      if (await part.exists()) await part.delete();
    }
  }

  /// Deletes the basemap of [projectId], for a project whose basemap the
  /// server no longer has. A missing file is fine.
  Future<void> remove(String projectId) async {
    final file = File(await pathFor(projectId));
    if (await file.exists()) await file.delete();
    await _syncState.clearBasemapSha256(projectId);
  }

  /// Deletes the whole `basemaps/` folder ("Remove all local data").
  Future<void> deleteAll() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/basemaps');
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  /// SHA-256 of a file, read in chunks (a basemap can be 100 MB).
  Future<String> _hashOf(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}

final basemapStoreProvider = Provider<BasemapStore>(
  (ref) => BasemapStore(
    ref.watch(syncApiProvider),
    ref.watch(syncStateRepositoryProvider),
  ),
);
