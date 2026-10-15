import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/settings/ui/settings_screen.dart';
import 'package:mobile/features/skeleton/ui/skeleton_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
      // T044: delete with the skeleton.
      if (kDebugMode)
        GoRoute(path: '/skeleton', builder: (_, _) => const SkeletonScreen()),
    ],
  );
});
