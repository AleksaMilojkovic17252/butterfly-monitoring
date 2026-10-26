import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/projects/data/project_repository.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/projects/ui/project_period.dart';

/// The hub for field work in one project (outline §11.2 C). There is no
/// validation tile: validation happens in Django admin only.
class ProjectHomeScreen extends ConsumerWidget {
  const ProjectHomeScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId));
    return switch (project) {
      AsyncData(value: final p?) => _Home(project: p),
      AsyncData() => const _Missing(),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Home extends ConsumerWidget {
  const _Home({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref.watch(projectPendingChangesProvider(project.id)).value ?? 0;

    // Each tile opens its screen once the ticket that builds it lands.
    final tiles = [
      const _Tile(icon: Icons.play_arrow_rounded, label: 'Start visit'),
      const _Tile(icon: Icons.route_outlined, label: 'Transects'),
      const _Tile(
        icon: Icons.add_location_alt_outlined,
        label: 'Free observation',
      ),
      const _Tile(
        icon: Icons.local_florist_outlined,
        label: 'Plants & habitat',
      ),
      const _Tile(icon: Icons.map_outlined, label: 'Map'),
      _Tile(
        icon: Icons.sync_outlined,
        label: 'Unsynced data',
        badge: pending,
        onTap: () => context.push('/projects/${project.id}/sync'),
      ),
      const _Tile(icon: Icons.bar_chart_outlined, label: 'Statistics'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Text(
              project.periodLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
            // The grid sits inside the ListView, which does the scrolling.
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: tiles,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.badge = 0,
    this.onTap,
  });
  final IconData icon;
  final String label;

  /// Number shown on the icon; hidden when 0.
  final int badge;

  /// Opens the tile's screen; null keeps the "coming later" snackbar.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            onTap ??
            () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('$label is coming in a later version')),
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Icon(icon, size: 36, color: scheme.primary),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// The remembered project is no longer on this phone (for example after
/// "Remove data").
class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This project is not on this phone.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('All projects'),
            ),
          ],
        ),
      ),
    );
  }
}
