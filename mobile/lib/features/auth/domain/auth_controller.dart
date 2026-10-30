import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/local_data_repository.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/data/token_storage.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/projects/domain/last_project.dart';

/// Holds `loading | unauthenticated | authenticated | offline`; go_router
/// redirects on it.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthLoading();
  }

  /// Offline start: a stored refresh token and profile are enough to open the
  /// app. The server is asked in the background to confirm the session.
  Future<void> _restore() async {
    final storage = ref.read(tokenStorageProvider);
    final refresh = await storage.readRefresh();
    final profile = await storage.readProfile();
    if (refresh == null || profile == null) {
      state = const Unauthenticated();
      return;
    }
    state = OfflineSession(profile);
    await checkSession();
  }

  /// Confirms the session with `/auth/me`. Network failure leaves the app in
  /// offline mode; a rejected session goes to the login screen.
  Future<void> checkSession() async {
    final current = state.profile;
    if (current == null) return;
    try {
      final fresh = await ref.read(authRepositoryProvider).fetchProfile();
      if (state.profile != null) state = Authenticated(fresh);
    } on AuthException catch (_) {
      // Unreachable server: stay as we are. A rejected refresh already
      // called sessionExpired().
    }
  }

  Future<void> login(String email, String password) async {
    final profile = await ref
        .read(authRepositoryProvider)
        .login(email, password);
    state = Authenticated(profile);
  }

  /// Refresh token rejected: back to login. Local data is kept.
  Future<void> sessionExpired() async {
    if (state is Unauthenticated) return;
    await ref.read(tokenStorageProvider).clear();
    state = const Unauthenticated();
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const Unauthenticated();
  }

  /// Deletes every row in the local database, the photo files and the stored
  /// session.
  Future<void> removeAllLocalData() async {
    await ref.read(localDataRepositoryProvider).clearAll();
    await ref.read(photoRepositoryProvider).deleteAllFiles();
    await ref.read(lastSyncProvider.notifier).clear();
    await ref.read(lastProjectProvider.notifier).clear();
    await logout();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
