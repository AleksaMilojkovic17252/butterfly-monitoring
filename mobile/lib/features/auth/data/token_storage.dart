import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/auth/domain/user_profile.dart';

class TokenStorage {
  TokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _profile = 'profile';

  Future<String?> readAccess() => _storage.read(key: _access);
  Future<String?> readRefresh() => _storage.read(key: _refresh);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: _access, value: access);
    if (refresh != null) await _storage.write(key: _refresh, value: refresh);
  }

  Future<UserProfile?> readProfile() async {
    final raw = await _storage.read(key: _profile);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) =>
      _storage.write(key: _profile, value: jsonEncode(profile.toJson()));

  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _profile);
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);
