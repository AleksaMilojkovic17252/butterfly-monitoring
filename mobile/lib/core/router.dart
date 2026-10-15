import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/settings/ui/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const SettingsScreen())],
  );
});
