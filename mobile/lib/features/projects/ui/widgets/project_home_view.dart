import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/ui/free_observation_entry.dart';
import 'package:mobile/features/projects/domain/project_closed.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/projects/ui/project_period.dart';
import 'package:mobile/features/projects/ui/widgets/project_home_tile.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/ui/start_visit_entry.dart';
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

    // A closed project takes no new or changed data (T099). A visit in progress
    // can still be reached, to cancel it on this phone, so the tile stays on
    // while one runs.
    final closed = ref.watch(projectClosedProvider(project.id));
    final visitRunning = ref.watch(visitInProgressProvider).value != null;
    final startDisabled = closed && !visitRunning;

    // A tile without onTap is drawn disabled ("Coming later"); the ticket
    // that builds its screen gives it an onTap.
    final tiles = [
      ProjectHomeTile(
        icon: Icons.play_arrow_rounded,
        label: 'Start visit',
        disabledText: '',
        onTap: startDisabled
            ? null
            : () => openStartVisit(context, ref, project.id),
      ),
      ProjectHomeTile(
        icon: Icons.route_outlined,
        label: 'Transects',
        onTap: () => context.push('/projects/${project.id}/transects'),
      ),
      ProjectHomeTile(
        icon: Icons.add_location_alt_outlined,
        label: 'Free observation',
        disabledText: '',
        onTap: closed
            ? null
            : () => openFreeObservation(context, ref, project.id),
      ),
      ProjectHomeTile(
        icon: Icons.local_florist_outlined,
        label: 'Plants & habitat',
        onTap: () => context.push('/projects/${project.id}/plants'),
      ),
      ProjectHomeTile(
        icon: Icons.map_outlined,
        label: 'Map',
        onTap: () => context.push('/projects/${project.id}/map'),
      ),
      ProjectHomeTile(
        icon: Icons.sync_outlined,
        label: 'Unsynced data',
        badge: pending,
        onTap: () => context.push('/projects/${project.id}/sync'),
      ),
      ProjectHomeTile(
        icon: Icons.bar_chart_outlined,
        label: 'Statistics',
        onTap: () => context.push('/projects/${project.id}/statistics'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.periodLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (closed)
                  Text(
                    'Closed',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
              ],
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
