import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts the bytes a [Dio] instance sends and receives, for the "data used by
/// the last sync" figure (T030).
///
/// Request bodies are counted at their JSON-encoded size. A response is counted
/// by its `content-length` header, or by its JSON-encoded body when the header
/// is missing. Error responses (4xx, 5xx) are counted too. Headers and URLs are
/// not. The sync runner calls [reset] at the start of a run and reads [bytes]
/// at the end.
class TransferCounter extends Interceptor {
  int bytes = 0;

  /// Sets the counter back to zero.
  void reset() => bytes = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    bytes += _size(options.data);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _countResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      _countResponse(response);
    }
    handler.next(err);
  }

  void _countResponse(Response<dynamic> response) {
    final headerValue = int.tryParse(
      response.headers.value(Headers.contentLengthHeader).toString(),
    );
    bytes += headerValue ?? _size(response.data);
  }

  /// The UTF-8 size of a body. Only text and JSON bodies are measured: anything
  /// else (a `FormData` upload, bytes, null) counts as zero instead of failing.
  int _size(Object? data) {
    if (data is String) return utf8.encode(data).length;
    if (data is Map || data is List) {
      return utf8.encode(jsonEncode(data)).length;
    }
    return 0;
  }
}

final transferCounterProvider = Provider<TransferCounter>(
  (ref) => TransferCounter(),
);
