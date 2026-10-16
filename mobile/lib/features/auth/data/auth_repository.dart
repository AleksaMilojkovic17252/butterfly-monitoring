import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/server_url_notifier.dart';
import 'package:mobile/core/http/dio_provider.dart';
import 'package:mobile/features/auth/data/token_storage.dart';
import 'package:mobile/features/auth/domain/user_profile.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.network = false});
  final String message;

  final bool network;

  @override
  String toString() => message;
}

final _plainDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(serverUrlProvider),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

class AuthRepository {
  AuthRepository(this._dio, this._authedDio, this._storage);
  final Dio _dio;

  /// Dio with the auth interceptor, for calls made with the access token.
  final Dio _authedDio;
  final TokenStorage _storage;

  Future<UserProfile> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final data = response.data!;
      final profile = UserProfile.fromJson(
        data['user'] as Map<String, dynamic>,
      );
      await _storage.saveTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      await _storage.saveProfile(profile);
      return profile;
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Fetches the current profile with the access token (refreshed on 401 by
  /// the interceptor) and caches it. Throws [AuthException]; `network` is true
  /// when the server could not be reached.
  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _authedDio.get<Map<String, dynamic>>(
        '/api/v1/auth/me',
      );
      final profile = UserProfile.fromJson(response.data!);
      await _storage.saveProfile(profile);
      return profile;
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Exchanges the refresh token for new tokens (the server rotates them).
  /// Returns the new access token. Throws [AuthException]; `network` is false
  /// when the server rejected the refresh token.
  Future<String> refresh() async {
    final refresh = await _storage.readRefresh();
    if (refresh == null) throw const AuthException('No session');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh': refresh},
      );
      final data = response.data!;
      final access = data['access'] as String;
      await _storage.saveTokens(
        access: access,
        refresh: data['refresh'] as String?,
      );
      return access;
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Revokes the refresh token on the server (best effort) and clears the
  /// stored session. Never touches the local database.
  Future<void> logout() async {
    final refresh = await _storage.readRefresh();
    if (refresh != null) {
      try {
        await _dio.post<void>(
          '/api/v1/auth/logout',
          data: {'refresh': refresh},
        );
      } on DioException catch (_) {
        // Offline logout is fine; the token expires on its own.
      }
    }
    await _storage.clear();
  }

  AuthException _toAuthException(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) {
      return AuthException(switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
          'The server took too long to answer.',
        _ => "Can't reach the server. Check your connection.",
      }, network: true);
    }
    final body = e.response?.data;
    final detail = body is Map ? body['detail'] as String? : null;
    return AuthException(switch (status) {
      401 => 'Wrong email or password.',
      429 => detail ?? 'Too many attempts. Try again later.',
      _ => detail ?? 'Server error ($status).',
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(_plainDioProvider),
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  ),
);
