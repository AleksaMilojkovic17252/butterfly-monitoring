import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/features/projects/data/project_repository.dart';
import 'package:mobile/features/projects/domain/last_project.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/projects/ui/project_period.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    // Quiet refresh on open: offline, the saved list is shown as it is.
    _refreshQuietly();
  }

  /// Downloads the project list without telling the user if it fails.
  Future<void> _refreshQuietly() async {
    try {
      await ref.read(projectRepositoryProvider).refreshFromServer();
    } on DioException catch (_) {
      // Offline: the saved list stays on screen.
    }
  }

  /// Pull-to-refresh: a full sync, not only the project list. The snackbar
  /// appears when the sync did not finish.
  Future<void> _pullToRefresh() async {
    final ok = await ref.read(syncNowProvider)();
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync did not finish. Changes stay on this phone.'),
      ),
    );
  }

  Future<void> _open(Project project) async {
    await ref.read(lastProjectProvider.notifier).select(project.id);
    if (!mounted) return;
    context.go('/projects/${project.id}');
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);
    final running = ref.watch(syncRunnerProvider).running;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        // The bar always takes its 3 px, so the list does not jump when a sync
        // starts or ends.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: running
              ? LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  color: Theme.of(context).colorScheme.onPrimary,
                )
              : const SizedBox(height: 3),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _pullToRefresh,
        child: switch (projects) {
          AsyncData(value: final list) when list.isEmpty => ListView(
            // A scrollable child, so pull-to-refresh works on an empty list.
            padding: const EdgeInsets.all(24),
            children: const [
              Text(
                'No projects on this phone yet. Pull down to refresh. '
                'If none appear, ask an admin to add you to a project.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          AsyncData(value: final list) => ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (context, i) =>
                _ProjectCard(project: list[i], onTap: () => _open(list[i])),
          ),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project, required this.onTap});
  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transects =
        ref.watch(downloadedTransectCountProvider(project.id)).value ?? 0;
    final pending =
        ref.watch(projectPendingChangesProvider(project.id)).value ?? 0;
    final status = ref.watch(offlinePackageStatusProvider(project.id)).value;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(project.periodLabel, style: textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Stat(
                    icon: Icons.route_outlined,
                    text: '$transects transects',
                  ),
                  _Stat(icon: Icons.sync_outlined, text: '$pending unsynced'),
                  if (status != null)
                    _Stat(
                      icon: status == OfflinePackageStatus.ready
                          ? Icons.offline_pin_outlined
                          : Icons.cloud_download_outlined,
                      text: status.label,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small icon and label, one per number on the project card.
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(text)],
    );
  }
}
