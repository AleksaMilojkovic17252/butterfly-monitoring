import 'package:mobile/features/auth/domain/user_profile.dart';

sealed class AuthState {
  const AuthState();
}

/// Reading stored credentials at startup.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Session confirmed by the server.
class Authenticated extends AuthState {
  const Authenticated(this.profile);
  final UserProfile profile;
}

/// Stored session, server unreachable: the app works from local data.
class OfflineSession extends AuthState {
  const OfflineSession(this.profile);
  final UserProfile profile;
}

extension AuthStateX on AuthState {
  UserProfile? get profile => switch (this) {
    Authenticated(:final profile) || OfflineSession(:final profile) => profile,
    _ => null,
  };
}
