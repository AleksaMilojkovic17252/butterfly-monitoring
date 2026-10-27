import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router.dart';
import 'package:mobile/core/sync/sync_triggers.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncTriggersProvider);
    // Records the route of the visit in progress, also after a restart.
    ref.watch(trackingControllerProvider);
    return MaterialApp.router(
      title: 'Butterfly Monitoring',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
