import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/ui/login_screen.dart';
import 'package:mobile/features/auth/ui/splash_screen.dart';
import 'package:mobile/features/settings/ui/settings_screen.dart';
import 'package:mobile/features/skeleton/ui/skeleton_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final at = state.matchedLocation;
      return switch (auth) {
        AuthLoading() => at == '/splash' ? null : '/splash',
        Unauthenticated() =>
          (at == '/login' || at == '/settings') ? null : '/login',
        Authenticated() ||
        OfflineSession() => (at == '/login' || at == '/splash') ? '/' : null,
      };
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      // T044: delete with the skeleton.
      if (kDebugMode)
        GoRoute(path: '/skeleton', builder: (_, _) => const SkeletonScreen()),
    ],
  );
});
