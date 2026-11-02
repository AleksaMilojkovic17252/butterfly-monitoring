import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/photo_api.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/features/observations/domain/draft_photo.dart';
import 'package:mobile/features/observations/domain/photo_preview.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Photos (T050): the only code that touches photo files and the
/// `photo` table. Taking a photo makes a [DraftPhoto] (a file, no row). A row
/// and its queue item are written by [addDrafts], through
/// [SyncRepository.write], so both exist or neither does.
///
/// A photo taken on another phone has a row but no file here. [preview] and
/// [fullImage] fetch it from the server for display (T107).
class PhotoRepository {
  PhotoRepository(this._db, this._sync, this._api);
  final AppDatabase _db;
  final SyncRepository _sync;
  final PhotoApi _api;

  /// The server's entity type and the local table name.
  static const _entityType = 'photo';

  /// Longest side of a stored photo, in pixels.
  static const maxLongEdge = 2048;

  static const _jpegQuality = 85;

  /// The folder the photo files live in; created when missing.
  Future<Directory> photosDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/photos').create(recursive: true);
  }

  /// Asks the system for a photo ([ImageSource.camera] or
  /// [ImageSource.gallery]), shrinks it and hashes it. Returns null when the
  /// user cancels.
  ///
  /// The file the picker returns is always the picker's own copy in the app's
  /// cache, never the original in the user's gallery, so deleting it is safe.
  /// It is deleted once the compressed file exists.
  ///
  /// Throws a [StateError] when the photo cannot be compressed.
  Future<DraftPhoto?> capture(ImageSource source) async {
    // `requestFullMetadata: false` stops the picker from asking for the media
    // location permission, which the app does not need.
    final picked = await ImagePicker().pickImage(
      source: source,
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final id = const Uuid().v4();
    final directory = await photosDirectory();
    final target = '${directory.path}/$id.jpg';
    try {
      final (width: sourceWidth, height: sourceHeight) = await _imageSize(
        picked.path,
      );
      // The plugin shrinks by max(1, min(width / minWidth, height / minHeight))
      // of the raw picture, so asking for 2048 x 2048 would leave the long
      // edge above 2048. Giving the same value m for both makes the scale
      // shortEdge / m, whichever way the sizes are reported (EXIF may swap
      // them), and m = shortEdge * 2048 / longEdge makes that longEdge / 2048.
      // `floor` rounds the scale up, never down, so the result stays within
      // 2048. A picture that is small enough gets m = shortEdge: scale 1.
      final longEdge = sourceWidth > sourceHeight ? sourceWidth : sourceHeight;
      final shortEdge = sourceWidth > sourceHeight ? sourceHeight : sourceWidth;
      final minSide = longEdge > maxLongEdge
          ? (shortEdge * maxLongEdge / longEdge).floor()
          : shortEdge;
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        target,
        quality: _jpegQuality,
        minWidth: minSide,
        minHeight: minSide,
        // Turns the picture upright, since the EXIF data is dropped.
        autoCorrectionAngle: true,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (compressed == null) {
        throw StateError('The photo could not be processed.');
      }

      // Width and height come from the result: a rotation by EXIF swaps them.
      final (:width, :height) = await _imageSize(compressed.path);
      final size = await File(compressed.path).length();
      final hash = await Isolate.run(
        () =>
            sha256.convert(File(compressed.path).readAsBytesSync()).toString(),
      );
      return DraftPhoto(
        id: id,
        path: compressed.path,
        size: size,
        sha256: hash,
        width: width,
        height: height,
        capturedAt: DateTime.now().toUtc(),
      );
    } catch (_) {
      await _deleteFile(target);
      rethrow;
    } finally {
      await _deleteFile(picked.path);
    }
  }

  /// Deletes the files of drafts that will not be saved.
  Future<void> discardDrafts(List<DraftPhoto> drafts) async {
    for (final draft in drafts) {
      await _deleteFile(draft.path);
    }
  }

  /// Writes a `photo` create for each of [drafts] on the observation, and
  /// queues it. When [firstIsPrimary] is true the first draft is the primary
  /// photo. Call it after the observation's own write: the queue then sends the
  /// observation first. Joins a running transaction.
  Future<void> addDrafts({
    required String projectId,
    required String observationId,
    required List<DraftPhoto> drafts,
    required bool firstIsPrimary,
  }) async {
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final isPrimary = firstIsPrimary && i == 0;
      final createdAt = DateTime.now().toUtc();
      await _sync.write(
        projectId: projectId,
        entityType: _entityType,
        entityId: draft.id,
        operation: SyncOperation.create,
        payload: {
          'observation': observationId,
          'local_path': draft.path,
          'mime_type': 'image/jpeg',
          'file_size': draft.size,
          'sha256': draft.sha256,
          'width': draft.width,
          'height': draft.height,
          'captured_at': draft.capturedAt.toIso8601String(),
          'is_primary': isPrimary,
          'created_at': createdAt.toIso8601String(),
        },
        writeRow: () => _db
            .into(_db.photos)
            .insert(
              PhotosCompanion.insert(
                id: draft.id,
                observationId: Value(observationId),
                localPath: draft.path,
                mimeType: 'image/jpeg',
                fileSize: draft.size,
                sha256: draft.sha256,
                width: Value(draft.width),
                height: Value(draft.height),
                capturedAt: draft.capturedAt,
                isPrimary: Value(isPrimary),
                createdAt: createdAt,
              ),
            ),
      );
    }
  }

  /// Adds [draft] to an observation that is already saved. The photo is
  /// primary when the observation has no live photo yet. The visit may be
  /// completed, but not locked: the server refuses photo changes on a locked
  /// visit (D-072).
  ///
  /// Throws a [StateError] when the visit is gone or locked; the draft's file
  /// is deleted then, and also when the write fails.
  Future<void> addToObservation(
    ButterflyObservation observation,
    DraftPhoto draft,
  ) async {
    try {
      await _db.transaction(() async {
        final visitId = observation.surveyVisitId;
        if (visitId != null) {
          final visit = await (_db.select(
            _db.surveyVisits,
          )..where((v) => v.id.equals(visitId))).getSingleOrNull();
          if (visit == null || visit.deletedAt != null) {
            throw StateError('The visit is no longer on this phone.');
          }
          if (visitIsLocked(visit.status)) {
            throw StateError('The visit is locked.');
          }
        }
        final existing = await _livePhotos(observation.id);
        await addDrafts(
          projectId: observation.projectId,
          observationId: observation.id,
          drafts: [draft],
          firstIsPrimary: existing.isEmpty,
        );
      });
    } catch (_) {
      await discardDrafts([draft]);
      rethrow;
    }
  }

  /// Live photos of an observation, newest first.
  Stream<List<Photo>> watchObservationPhotos(String observationId) {
    final query = _db.select(_db.photos)
      ..where(
        (p) => p.observationId.equals(observationId) & p.deletedAt.isNull(),
      )
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]);
    return query.watch();
  }

  /// Makes [photo] the observation's primary photo. The old primary is unset
  /// first and the new one set second, as two queue items in that order: the
  /// server checks "one primary per observation" on every change (D-072).
  ///
  /// The row is read again inside the transaction: [photo] may be older than
  /// the database (a pull or an upload changed it since the screen got it).
  Future<void> makePrimary(Photo photo) {
    return _db.transaction(() async {
      final fresh = await _liveRow(photo.id);
      if (fresh == null || fresh.isPrimary) return;
      final current =
          await (_db.select(_db.photos)..where(
                (p) =>
                    p.observationId.equals(fresh.observationId!) &
                    p.deletedAt.isNull() &
                    p.isPrimary.equals(true),
              ))
              .get();
      for (final old in current) {
        await _setPrimary(old, false);
      }
      await _setPrimary(fresh, true);
    });
  }

  /// Soft-deletes [photo] (a delete is queued). A photo whose create the
  /// server never saw is removed outright, with its file. When it was the
  /// primary photo, the oldest remaining photo becomes primary.
  Future<void> delete(Photo photo) async {
    final removed = await _db.transaction(() => _queueDelete(photo.id));
    // After the commit, so a rollback never leaves a row without its file.
    await deleteFiles(removed);
  }

  /// Queues the delete of every live photo of an observation, for
  /// `ObservationRepository.undo`, and returns the paths of the files whose
  /// rows were removed outright. The caller deletes them with [deleteFiles]
  /// **after** its own transaction has committed. Call it inside a
  /// transaction.
  Future<List<String>> deleteObservationPhotos(String observationId) async {
    final photos = await _livePhotos(observationId);
    // The primary last, so no other photo is made primary on the way.
    photos.sort((a, b) => (a.isPrimary ? 1 : 0) - (b.isPrimary ? 1 : 0));
    final paths = <String>[];
    for (final photo in photos) {
      paths.addAll(await _queueDelete(photo.id));
    }
    return paths;
  }

  /// Deletes photo files that are no longer used. A missing file is fine.
  Future<void> deleteFiles(List<String> paths) async {
    for (final path in paths) {
      await _deleteFile(path);
    }
  }

  /// Clears the upload error of a photo the server refused, so the next sync
  /// tries it again. Local only: nothing is queued.
  Future<void> retryUpload(Photo photo) {
    return (_db.update(_db.photos)..where((p) => p.id.equals(photo.id))).write(
      const PhotosCompanion(uploadError: Value(null)),
    );
  }

  /// What to show for the photo with [key] (T107), in this order:
  /// 1. the photo's own file, when it is on this phone (no network);
  /// 2. the thumbnail fetched earlier, in `photo_cache/` (no network);
  /// 3. the thumbnail from the server, saved to `photo_cache/` first.
  ///
  /// Never throws for a missing connection or file: it returns a
  /// [PhotoPreview.missing] with a sentence, because a provider that throws is
  /// retried by Riverpod.
  Future<PhotoPreview> preview(PhotoPreviewKey key) async {
    if (await File(key.localPath).exists()) {
      return PhotoPreview.onPhone(key.localPath);
    }
    try {
      final cached = File(await _cachePath(key.id));
      if (await cached.exists()) return PhotoPreview.cached(cached.path);

      final bytes = await _api.thumbnail(key.id);
      // A 200 with no body (a proxy, a captive portal) is not a thumbnail.
      if (bytes.isEmpty) {
        return PhotoPreview.missing(_unavailableText(key, null));
      }
      // Written under a name of its own and renamed, so a killed app never
      // leaves a half-written image that would count as cached, and two
      // downloads of the same photo cannot write to the same file.
      final part = File(
        '${cached.path}.${DateTime.now().microsecondsSinceEpoch}.part',
      );
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(cached.path);
      return PhotoPreview.cached(cached.path);
    } on DioException catch (e) {
      return PhotoPreview.missing(_unavailableText(key, e));
    } on FileSystemException {
      return const PhotoPreview.missing('Photo is on the server');
    }
  }

  /// Deletes the cached thumbnail of [photoId], for a file that cannot be
  /// shown (damaged). The next [preview] fetches it again. A missing file is
  /// fine.
  Future<void> deleteCachedThumbnail(String photoId) async {
    try {
      await _deleteFile(await _cachePath(photoId));
    } on FileSystemException catch (e) {
      debugPrint('Could not delete a cached thumbnail: $e');
    }
  }

  /// The full image of the photo with [key] from the server, for the viewer.
  /// The bytes are kept in memory only, never saved to a file (T107). When they
  /// cannot be fetched, `unavailable` holds the sentence to show.
  Future<FullImage> fullImage(PhotoPreviewKey key) async {
    try {
      final bytes = await _api.content(key.id);
      if (bytes.isEmpty) {
        return (bytes: null, unavailable: _unavailableText(key, null));
      }
      return (bytes: bytes, unavailable: null);
    } on DioException catch (e) {
      return (bytes: null, unavailable: _unavailableText(key, e));
    }
  }

  /// Why a photo could not be fetched. A 404 means the server has no file for
  /// it yet. Anything else (no connection, a server error, an empty answer)
  /// says the photo is on the server, unless this phone's row says it was never
  /// uploaded.
  String _unavailableText(PhotoPreviewKey key, DioException? e) {
    if (e?.response?.statusCode == 404) return 'Not uploaded yet';
    return key.uploadStatus == 'uploaded'
        ? 'Photo is on the server'
        : 'Not uploaded yet';
  }

  /// Size in bytes of all photo files on this phone, thumbnails fetched from
  /// the server included.
  Future<int> storageBytes() async {
    final photos = await _folderBytes(await photosDirectory());
    final cache = await _folderBytes(await _cacheDirectory());
    return photos + cache;
  }

  /// Deletes the thumbnail cache (logout). A problem with the cache must never
  /// stop a logout, so a file error is only logged.
  Future<void> deleteCache() async {
    try {
      final directory = await _cacheDirectory();
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException catch (e) {
      debugPrint('Could not delete the photo cache: $e');
    }
  }

  /// Deletes the whole photos folder ("Remove all local data").
  Future<void> deleteAllFiles() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/photos');
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  /// The folder of fetched thumbnails. It is not created here: [preview]
  /// creates it when it saves a file.
  Future<Directory> _cacheDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/photo_cache');
  }

  /// Where the thumbnail of [photoId] is kept; creates the folder.
  Future<String> _cachePath(String photoId) async {
    final directory = await (await _cacheDirectory()).create(recursive: true);
    return '${directory.path}/${photoId}_thumb.jpg';
  }

  /// Total size of the files directly in [directory]; 0 when it is missing. A
  /// file that disappears while listing (a download renaming its `.part`
  /// file) is skipped.
  Future<int> _folderBytes(Directory directory) async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entry in directory.list()) {
      if (entry is! File) continue;
      try {
        total += await entry.length();
      } on FileSystemException {
        // Gone since it was listed.
      }
    }
    return total;
  }

  /// The photo's row as it is now, or null when it is gone or deleted.
  Future<Photo?> _liveRow(String id) async {
    final row = await (_db.select(
      _db.photos,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return row == null || row.deletedAt != null ? null : row;
  }

  /// Queues the delete of one photo, reading its row again first. Returns the
  /// path of its file when the row was removed outright (a create that was
  /// never sent), otherwise an empty list: a soft-deleted, synced row keeps
  /// its file until "Remove all local data". Call it inside a transaction.
  Future<List<String>> _queueDelete(String id) async {
    final photo = await _liveRow(id);
    if (photo == null) return [];
    await _sync.write(
      projectId: await _projectIdOf(photo),
      entityType: _entityType,
      entityId: photo.id,
      operation: SyncOperation.delete,
      payload: {},
      baseVersion: photo.serverVersion,
    );
    if (photo.isPrimary) {
      final rest = await _livePhotos(photo.observationId!);
      if (rest.isNotEmpty) {
        rest.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        await _setPrimary(rest.first, true);
      }
    }
    final row = await (_db.select(
      _db.photos,
    )..where((p) => p.id.equals(photo.id))).getSingleOrNull();
    return row == null ? [photo.localPath] : [];
  }

  /// Queues an `is_primary` change. Setting it always gets its own queue item
  /// (`mergeUpdate` false): merged into an unsent create, it could be sent
  /// before the old primary's unset.
  Future<void> _setPrimary(Photo photo, bool value) {
    return _db.transaction(() async {
      await _sync.write(
        projectId: await _projectIdOf(photo),
        entityType: _entityType,
        entityId: photo.id,
        operation: SyncOperation.update,
        payload: {'is_primary': value},
        baseVersion: photo.serverVersion,
        mergeUpdate: !value,
        writeRow: () =>
            (_db.update(_db.photos)..where((p) => p.id.equals(photo.id))).write(
              PhotosCompanion(isPrimary: Value(value)),
            ),
      );
    });
  }

  /// The project of the photo's observation.
  Future<String> _projectIdOf(Photo photo) async {
    final observation = await (_db.select(
      _db.butterflyObservations,
    )..where((o) => o.id.equals(photo.observationId ?? ''))).getSingleOrNull();
    if (observation == null) {
      throw StateError('The observation is no longer on this phone.');
    }
    return observation.projectId;
  }

  Future<List<Photo>> _livePhotos(String observationId) {
    return (_db.select(_db.photos)..where(
          (p) => p.observationId.equals(observationId) & p.deletedAt.isNull(),
        ))
        .get();
  }

  /// Width and height of an image file, read from its header (no full decode).
  Future<({int width, int height})> _imageSize(String path) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (width: descriptor.width, height: descriptor.height);
      descriptor.dispose();
      return size;
    } finally {
      buffer.dispose();
    }
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
    ref.watch(photoApiProvider),
  ),
);

/// Live photos of one observation, newest first (T050). `autoDispose`: the
/// query stops when the detail screen closes.
final photosProvider = StreamProvider.autoDispose.family<List<Photo>, String>(
  (ref, observationId) =>
      ref.watch(photoRepositoryProvider).watchObservationPhotos(observationId),
);

/// What to show for one photo (T107). Keyed by [PhotoPreviewKey] (id, file
/// path, upload status), not the whole row: a Make primary does not load the
/// picture again, but `pending` to `uploaded` after a sync does. `autoDispose`:
/// forgotten when no screen shows the photo.
final photoPreviewProvider = FutureProvider.autoDispose
    .family<PhotoPreview, PhotoPreviewKey>(
      (ref, key) => ref.watch(photoRepositoryProvider).preview(key),
    );

/// The full image for the viewer (T107). `autoDispose` drops the bytes when
/// the viewer closes, which is how the full image is "not kept".
final photoFullImageProvider = FutureProvider.autoDispose
    .family<FullImage, PhotoPreviewKey>(
      (ref, key) => ref.watch(photoRepositoryProvider).fullImage(key),
    );
