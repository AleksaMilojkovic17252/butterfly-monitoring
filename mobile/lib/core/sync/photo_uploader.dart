import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/photo_api.dart';
import 'package:mobile/core/sync/sync_repository.dart';

/// Sends the files of photos to the server, after the sync runner has pushed
/// the queue (T050, D-072). The queue carries a photo's metadata; this class
/// carries its bytes.
class PhotoUploader {
  PhotoUploader(this._db, this._api);
  final AppDatabase _db;
  final PhotoApi _api;

  /// Uploads every photo that is `pending`, not deleted, has its file on this
  /// phone and has **no queue item**. A queue item means the server may not
  /// have the photo's row yet, or a change to it is waiting, so the photo
  /// waits for the next run.
  ///
  /// Returns null when it finished, or the error text when the server could
  /// not be reached (the rest of the photos are left for the next run). A
  /// photo the server refuses for good (see [_isPermanent]) gets its
  /// `uploadError` and is not tried again until the user retries it. Any other
  /// failure of one photo (a 5xx, an unreadable file) is skipped and tried
  /// again next run, as D-054 does for the queue; a missing file is skipped
  /// too.
  Future<String?> uploadPending() async {
    final queued = _db.select(_db.syncQueue)
      ..where(
        (q) =>
            q.entityType.equals('photo') & q.entityId.equalsExp(_db.photos.id),
      );
    final photos =
        await (_db.select(_db.photos)..where(
              (p) =>
                  p.uploadStatus.equals('pending') &
                  p.uploadError.isNull() &
                  p.deletedAt.isNull() &
                  notExistsQuery(queued),
            ))
            .get();

    for (final photo in photos) {
      final file = File(photo.localPath);
      // A photo from another phone has no file here (T107).
      if (!await file.exists()) continue;
      try {
        await _upload(photo, file);
      } on DioException catch (e) {
        final response = e.response;
        // No response: the network is down or too slow. Stop here.
        if (response == null) return e.toString();
        if (_isPermanent(response.statusCode)) {
          // Trying again would be refused again: keep the reason for the
          // sync screen and leave the photo alone until the user retries.
          await _markFailed(photo.id, _errorText(response));
        } else {
          _log('photo ${photo.id} not uploaded: ${response.statusCode}');
        }
      } catch (e) {
        // Anything else (an unreadable file, a reply the app cannot read) only
        // costs this photo, for this run.
        _log('photo ${photo.id} not uploaded: $e');
      }
    }
    return null;
  }

  /// A 4xx that a repeat cannot fix (422 the file does not match its record,
  /// 415, 413, 404, ...). Not permanent: 401 (the session, not the photo), 408
  /// and 429 (try later), 409 (the steps are out of order; the next run's
  /// `init` sorts that out), and every 5xx.
  bool _isPermanent(int? status) {
    if (status == null || status < 400 || status >= 500) return false;
    return !{401, 408, 409, 429}.contains(status);
  }

  /// The server's error as the JSON text `[{code, detail, fields}]` that
  /// `syncErrorMessage` reads. A reply that is not in that form (for example
  /// an error page from nginx) becomes a short sentence with the status.
  String _errorText(Response<dynamic> response) {
    final body = response.data;
    if (body is Map && body['detail'] is String) {
      return jsonEncode([body]);
    }
    return jsonEncode([
      {
        'code': 'http_${response.statusCode}',
        'detail': 'The server refused the upload (${response.statusCode}).',
        'fields': <String, Object?>{},
      },
    ]);
  }

  /// Keeps [error] on the photo; it stays `pending`.
  Future<void> _markFailed(String photoId, String error) {
    return (_db.update(_db.photos)..where((p) => p.id.equals(photoId))).write(
      PhotosCompanion(uploadError: Value(error)),
    );
  }

  /// The three steps for one photo. Running it again is safe: `init` can be
  /// repeated until `complete`, and `complete` can be repeated.
  Future<void> _upload(Photo photo, File file) async {
    final init = await _api.init(
      photoId: photo.id,
      sha256: photo.sha256,
      fileSize: photo.fileSize,
      mimeType: photo.mimeType,
    );
    var serverVersion = init.serverVersion;
    var uploadedAt = DateTime.now().toUtc();
    if (!init.exists) {
      try {
        await _api.put(init.uploadUrl!, file, photo.fileSize);
      } on DioException catch (e) {
        // 409: the file was stored by an earlier run that did not get to
        // `complete`. Finish it.
        if (e.response?.statusCode != 409) rethrow;
      }
      final done = await _api.complete(photo.id);
      serverVersion = done.serverVersion;
      uploadedAt = done.uploadedAt;
    }
    await _markUploaded(photo.id, serverVersion, uploadedAt);
  }

  /// Stores the new `server_version` and the upload state. The version is
  /// needed: upload saves the row on the server, so a later delete with the old
  /// version would be a conflict (D-072). A queue item made in the meantime
  /// (an edit while the file went up) is moved to the new version as well.
  Future<void> _markUploaded(
    String photoId,
    int serverVersion,
    DateTime uploadedAt,
  ) {
    return _db.transaction(() async {
      await (_db.update(_db.photos)..where((p) => p.id.equals(photoId))).write(
        PhotosCompanion(
          serverVersion: Value(serverVersion),
          uploadStatus: const Value('uploaded'),
          uploadedAt: Value(uploadedAt),
          uploadError: const Value(null),
        ),
      );
      await (_db.update(_db.syncQueue)..where(
            (q) =>
                q.entityType.equals('photo') &
                q.entityId.equals(photoId) &
                q.operation.isIn([
                  SyncOperation.update.wireName,
                  SyncOperation.delete.wireName,
                ]),
          ))
          .write(SyncQueueCompanion(baseVersion: Value(serverVersion)));
    });
  }

  void _log(String message) {
    if (kDebugMode) Logger().w(message);
  }
}

final photoUploaderProvider = Provider<PhotoUploader>(
  (ref) => PhotoUploader(
    ref.watch(appDatabaseProvider),
    ref.watch(photoApiProvider),
  ),
);
