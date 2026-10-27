import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/ui/login_screen.dart';
import 'package:mobile/features/auth/ui/splash_screen.dart';
import 'package:mobile/features/projects/domain/last_project.dart';
import 'package:mobile/features/projects/ui/project_home_screen.dart';
import 'package:mobile/features/projects/ui/project_list_screen.dart';
import 'package:mobile/features/settings/ui/settings_screen.dart';
import 'package:mobile/features/skeleton/ui/skeleton_screen.dart';
import 'package:mobile/features/sync/ui/sync_status_screen.dart';
import 'package:mobile/features/transects/ui/transect_detail_screen.dart';
import 'package:mobile/features/transects/ui/transect_list_screen.dart';
import 'package:mobile/features/visits/ui/start_visit_screen.dart';

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
        Authenticated() || OfflineSession() =>
          (at == '/login' || at == '/splash') ? _startLocation(ref) : null,
      };
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ProjectListScreen(),
        routes: [
          // Nested under '/', so the back button on project home returns to
          // the project list.
          GoRoute(
            path: 'projects/:id',
            builder: (_, state) =>
                ProjectHomeScreen(projectId: state.pathParameters['id']!),
            routes: [
              // Nested again, so back returns to project home.
              GoRoute(
                path: 'sync',
                builder: (_, state) =>
                    SyncStatusScreen(projectId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'transects',
                builder: (_, state) =>
                    TransectListScreen(projectId: state.pathParameters['id']!),
                routes: [
                  // Back returns to the transect list.
                  GoRoute(
                    path: ':transectId',
                    builder: (_, state) => TransectDetailScreen(
                      projectId: state.pathParameters['id']!,
                      transectId: state.pathParameters['transectId']!,
                    ),
                    routes: [
                      // The start-visit form (T035); back returns to the
                      // transect detail.
                      GoRoute(
                        path: 'start',
                        builder: (_, state) => StartVisitScreen(
                          projectId: state.pathParameters['id']!,
                          transectId: state.pathParameters['transectId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      // T044: delete with the skeleton.
      if (kDebugMode)
        GoRoute(path: '/skeleton', builder: (_, _) => const SkeletonScreen()),
    ],
  );
});

/// After login or app start: the last opened project, else the project list.
String _startLocation(Ref ref) {
  final last = ref.read(lastProjectProvider);
  return last == null ? '/' : '/projects/$last';
}
