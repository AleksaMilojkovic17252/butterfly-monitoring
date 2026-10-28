import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/features/projects/domain/offline_package_status.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/projects/ui/project_period.dart';
import 'package:mobile/features/projects/ui/widgets/project_stat.dart';

/// One project in the project list: name, period, transect and unsynced
/// counts, the offline package status, and Download/Update with progress.
class ProjectCard extends ConsumerWidget {
  const ProjectCard({super.key, required this.project, required this.onTap});
  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transects =
        ref.watch(downloadedTransectCountProvider(project.id)).value ?? 0;
    final pending =
        ref.watch(projectPendingChangesProvider(project.id)).value ?? 0;
    final status = ref.watch(offlinePackageStatusProvider(project.id)).value;
    final runState = ref.watch(syncRunnerProvider);
    final downloading = runState.downloadingProjectId == project.id;
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
                spacing: 8,
                runSpacing: 8,
                children: [
                  ProjectStat(
                    icon: Icons.route_outlined,
                    text: '$transects transects',
                  ),
                  ProjectStat(
                    icon: Icons.sync_outlined,
                    text: '$pending unsynced',
                  ),
                  if (status != null)
                    ProjectStat(
                      icon: status == OfflinePackageStatus.ready
                          ? Icons.offline_pin_outlined
                          : Icons.cloud_download_outlined,
                      text: status.label,
                    ),
                ],
              ),
              if (downloading) ...[
                const SizedBox(height: 6),
                const LinearProgressIndicator(),
                Row(
                  children: [
                    Expanded(
                      child: Text('${runState.received} records received'),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(syncRunnerProvider.notifier)
                          .cancelDownload(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ] else if (status == OfflinePackageStatus.notDownloaded ||
                  status == OfflinePackageStatus.updateAvailable) ...[
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                      // One download at a time.
                      onPressed: runState.downloadingProjectId != null
                          ? null
                          : () => _download(context, ref),
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: Text(
                        status == OfflinePackageStatus.notDownloaded
                            ? 'Download'
                            : 'Update',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Runs the download and tells the user how it ended.
  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(syncRunnerProvider.notifier)
        .download(project.id);
    if (!context.mounted) return;
    final message = result.ok
        ? 'Project downloaded.'
        : result.cancelled
        ? 'Download paused. Tap Download to continue.'
        : 'Download did not finish: ${result.error}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
