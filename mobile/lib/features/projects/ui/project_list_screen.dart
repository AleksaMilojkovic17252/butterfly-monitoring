import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/features/projects/data/project_repository.dart';
import 'package:mobile/features/projects/domain/last_project.dart';
import 'package:mobile/features/projects/ui/widgets/project_card.dart';

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
                ProjectCard(project: list[i], onTap: () => _open(list[i])),
          ),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
