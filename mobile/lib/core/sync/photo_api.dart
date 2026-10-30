import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/http/dio_provider.dart';

/// The server's answer to the first upload step.
class PhotoInitResult {
  PhotoInitResult({
    required this.exists,
    required this.serverVersion,
    this.uploadUrl,
  });

  /// True when the server already stores a file with the same SHA-256 and has
  /// linked the photo to it: there is nothing to send.
  final bool exists;

  /// The photo row's new version on the server.
  final int serverVersion;

  /// Where to `PUT` the file when [exists] is false. It is relative to the
  /// server and already starts with `/api/v1` (D-072).
  final String? uploadUrl;
}

/// The server's answer to the last upload step.
class PhotoCompleteResult {
  PhotoCompleteResult({required this.serverVersion, required this.uploadedAt});

  final int serverVersion;
  final DateTime uploadedAt;
}

/// The three photo upload endpoints (D-072). It only builds requests and maps
/// replies; the uploader decides what a failure means, so a [DioException] is
/// not caught here.
class PhotoApi {
  PhotoApi(this._dio);
  final Dio _dio;

  /// Step 1: `POST /api/v1/attachments/init`. The values must equal the photo
  /// record the server already has, or it answers 422.
  Future<PhotoInitResult> init({
    required String photoId,
    required String sha256,
    required int fileSize,
    required String mimeType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/attachments/init',
      data: {
        'photo_id': photoId,
        'sha256': sha256,
        'file_size': fileSize,
        'mime_type': mimeType,
      },
    );
    final body = response.data!;
    return PhotoInitResult(
      exists: body['status'] == 'exists',
      serverVersion: body['server_version'] as int,
      uploadUrl: body['upload_url'] as String?,
    );
  }

  /// Step 2: sends the bytes of [file] to [uploadUrl], streamed from disk. The
  /// server needs the `Content-Length`, so [size] is set by hand.
  ///
  /// [uploadUrl] is resolved against the server's address, not appended to
  /// the base URL: it already starts with `/api/v1` (D-072).
  Future<void> put(String uploadUrl, File file, int size) async {
    final url = Uri.parse(_dio.options.baseUrl).resolve(uploadUrl);
    await _dio.putUri<void>(
      url,
      data: file.openRead(),
      options: Options(
        contentType: 'image/jpeg',
        headers: {Headers.contentLengthHeader: size},
        // A photo can take longer than the 20 s of the other requests.
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
  }

  /// Step 3: `POST /api/v1/attachments/<id>/complete`. The server makes the
  /// thumbnail and marks the photo uploaded. Safe to repeat.
  Future<PhotoCompleteResult> complete(String photoId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/attachments/$photoId/complete',
    );
    final body = response.data!;
    return PhotoCompleteResult(
      serverVersion: body['server_version'] as int,
      uploadedAt: DateTime.parse(body['uploaded_at'] as String),
    );
  }
}

/// The [PhotoApi] on the shared [Dio].
final photoApiProvider = Provider<PhotoApi>(
  (ref) => PhotoApi(ref.watch(dioProvider)),
);
