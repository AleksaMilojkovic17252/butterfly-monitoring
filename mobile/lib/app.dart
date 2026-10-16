import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router.dart';
import 'package:mobile/core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Butterfly Monitoring',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
