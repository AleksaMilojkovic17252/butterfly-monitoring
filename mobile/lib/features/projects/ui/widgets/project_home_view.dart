import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/projects/ui/project_period.dart';
import 'package:mobile/features/projects/ui/widgets/project_home_tile.dart';
import 'package:mobile/features/visits/ui/widgets/tracking_status_card.dart';

/// Project home of a project that is on this phone, shown by
/// `ProjectHomeScreen`: the tracking card, the project period and a grid of
/// tiles, one per field-work screen.
class ProjectHomeView extends ConsumerWidget {
  const ProjectHomeView({super.key, required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref.watch(projectPendingChangesProvider(project.id)).value ?? 0;

    // Each tile opens its screen once the ticket that builds it lands.
    final tiles = [
      const ProjectHomeTile(
        icon: Icons.play_arrow_rounded,
        label: 'Start visit',
      ),
      ProjectHomeTile(
        icon: Icons.route_outlined,
        label: 'Transects',
        onTap: () => context.push('/projects/${project.id}/transects'),
      ),
      const ProjectHomeTile(
        icon: Icons.add_location_alt_outlined,
        label: 'Free observation',
      ),
      const ProjectHomeTile(
        icon: Icons.local_florist_outlined,
        label: 'Plants & habitat',
      ),
      const ProjectHomeTile(icon: Icons.map_outlined, label: 'Map'),
      ProjectHomeTile(
        icon: Icons.sync_outlined,
        label: 'Unsynced data',
        badge: pending,
        onTap: () => context.push('/projects/${project.id}/sync'),
      ),
      const ProjectHomeTile(
        icon: Icons.bar_chart_outlined,
        label: 'Statistics',
      ),
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
          const TrackingStatusCard(),
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
