import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/ui/login_screen.dart';
import 'package:mobile/features/auth/ui/splash_screen.dart';
import 'package:mobile/features/map/ui/project_map_screen.dart';
import 'package:mobile/features/observations/ui/observation_detail_screen.dart';
import 'package:mobile/features/projects/domain/last_project.dart';
import 'package:mobile/features/projects/ui/project_home_screen.dart';
import 'package:mobile/features/projects/ui/project_list_screen.dart';
import 'package:mobile/features/resources/ui/plant_entry_screen.dart';
import 'package:mobile/features/resources/ui/plants_habitat_screen.dart';
import 'package:mobile/features/settings/ui/settings_screen.dart';
import 'package:mobile/features/sync/ui/sync_status_screen.dart';
import 'package:mobile/features/transects/ui/transect_detail_screen.dart';
import 'package:mobile/features/transects/ui/transect_list_screen.dart';
import 'package:mobile/features/visits/ui/active_visit_screen.dart';
import 'package:mobile/features/visits/ui/finish_visit_screen.dart';
import 'package:mobile/features/visits/ui/start_visit_screen.dart';
import 'package:mobile/features/visits/ui/visit_detail_screen.dart';

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
              // The project map (T059); back returns to project home.
              GoRoute(
                path: 'map',
                builder: (_, state) =>
                    ProjectMapScreen(projectId: state.pathParameters['id']!),
              ),
              // The active visit screen (T039); back returns to the screen
              // it was opened from.
              GoRoute(
                path: 'visits/:visitId',
                builder: (_, state) => ActiveVisitScreen(
                  visitId: state.pathParameters['visitId']!,
                ),
                routes: [
                  // The Finish screen (T040); back returns to the active
                  // visit screen.
                  GoRoute(
                    path: 'finish',
                    builder: (_, state) => FinishVisitScreen(
                      visitId: state.pathParameters['visitId']!,
                    ),
                  ),
                ],
              ),
              // One observation, read-only (T106). Under the project and not
              // the visit, so the map popup (T059) and observations without a
              // visit can open it; back returns to where it was opened from.
              GoRoute(
                path: 'observations/:observationId',
                builder: (_, state) => ObservationDetailScreen(
                  observationId: state.pathParameters['observationId']!,
                ),
              ),
              // The Plants & habitat screen (T052). `new` comes before
              // `:plantId`, or "new" would be read as a plant id.
              GoRoute(
                path: 'plants',
                builder: (_, state) =>
                    PlantsHabitatScreen(projectId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, state) => PlantEntryScreen(
                      projectId: state.pathParameters['id']!,
                      visitId: state.uri.queryParameters['visit'],
                    ),
                  ),
                  GoRoute(
                    path: ':plantId',
                    builder: (_, state) => PlantEntryScreen(
                      projectId: state.pathParameters['id']!,
                      plantId: state.pathParameters['plantId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'transects',
                builder: (_, state) => TransectListScreen(
                  projectId: state.pathParameters['id']!,
                  // The Start visit tile asks for the nearest transect first
                  // (T105).
                  sortByDistance:
                      state.uri.queryParameters['sort'] == 'distance',
                ),
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
                      // The detail of a finished or cancelled visit (T106).
                      // Not under the active visit route, so back returns to
                      // the transect detail.
                      GoRoute(
                        path: 'visits/:visitId',
                        builder: (_, state) => VisitDetailScreen(
                          visitId: state.pathParameters['visitId']!,
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
    ],
  );
});

/// After login or app start: the last opened project, else the project list.
String _startLocation(Ref ref) {
  final last = ref.read(lastProjectProvider);
  return last == null ? '/' : '/projects/$last';
}
