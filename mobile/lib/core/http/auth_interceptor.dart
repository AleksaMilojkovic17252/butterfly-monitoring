import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/data/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.storage,
    required this.refresh,
    required this.onSessionExpired,
  });

  final Dio dio;
  final TokenStorage storage;
  final Future<String> Function() refresh;
  final void Function() onSessionExpired;

  static const _retriedKey = 'auth_retried';
  Future<String>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.readAccess();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final sentAuth = request.headers['Authorization'] as String?;
    if (err.response?.statusCode != 401 ||
        request.extra[_retriedKey] == true ||
        sentAuth == null) {
      return handler.next(err);
    }

    try {
      final current = await storage.readAccess();
      final String token;
      if (current != null && 'Bearer $current' != sentAuth) {
        token = current;
      } else {
        token = await (_refreshing ??= refresh().whenComplete(
          () => _refreshing = null,
        ));
      }
      request.headers['Authorization'] = 'Bearer $token';
      request.extra[_retriedKey] = true;
      handler.resolve(await dio.fetch<dynamic>(request));
    } on AuthException catch (e) {
      if (!e.network) onSessionExpired();
      handler.next(err);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
