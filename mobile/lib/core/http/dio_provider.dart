import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/config/server_url_notifier.dart';
import 'package:mobile/core/http/auth_interceptor.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/data/token_storage.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(serverUrlProvider),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      storage: ref.read(tokenStorageProvider),
      refresh: () => ref.read(authRepositoryProvider).refresh(),
      onSessionExpired: () =>
          ref.read(authControllerProvider.notifier).sessionExpired(),
    ),
  );

  if (kDebugMode) {
    final logger = Logger();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.d('${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.d('${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) {
          logger.e('${error.requestOptions.uri}', error: error);
          handler.next(error);
        },
      ),
    );
  }

  ref.onDispose(dio.close);
  return dio;
});
