import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/photo_wifi_only.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/sync/domain/sync_error_message.dart';
import 'package:mobile/features/sync/domain/sync_status_providers.dart';
import 'package:mobile/features/sync/ui/widgets/conflict_card.dart';
import 'package:mobile/features/sync/ui/widgets/failed_photo_card.dart';
import 'package:mobile/features/sync/ui/widgets/rejected_card.dart';
import 'package:mobile/features/sync/ui/widgets/sync_now_card.dart';
import 'package:mobile/features/sync/ui/widgets/sync_section_title.dart';

/// What is waiting to sync in one project, what the server rejected (with
/// Retry and Discard), the conflicts, and a Sync now button with live
/// progress (T032).
class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  /// Runs a sync and tells the result in a snackbar, as Settings does.
  Future<void> _syncNow() async {
    final ok = await ref.read(syncNowProvider)();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Sync finished'
              : 'Sync did not finish. Changes stay on this phone.',
        ),
      ),
    );
  }

  /// Queues the rejected item again under a new id and syncs at once.
  Future<void> _retry(SyncQueueItem item) async {
    await ref.read(syncRepositoryProvider).retry(item);
    await _syncNow();
  }

  /// Lets the uploader try a photo the server refused again, and syncs at
  /// once.
  Future<void> _retryPhoto(Photo photo) async {
    await ref.read(photoRepositoryProvider).retryUpload(photo);
    await _syncNow();
  }

  /// Asks first, then deletes a photo the server refused. The delete syncs
  /// like any other.
  Future<void> _deletePhoto(Photo photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text(
          'The photo is removed from the observation. The observation stays.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(photoRepositoryProvider).delete(photo);
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  /// Asks first, then removes the local change. The server version comes back
  /// on the next sync.
  Future<void> _discard(SyncQueueItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Discard local change?'),
        content: const Text(
          'Your change is removed from this phone; the server version comes '
          'back on the next sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // A sync may have started while the dialog was open. Its pull saves the
    // cursor again and would undo the reset that discard makes.
    if (ref.read(syncRunnerProvider).running) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A sync is running. Try again when it finishes.'),
        ),
      );
      return;
    }
    await ref.read(syncRepositoryProvider).discard(item);
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final run = ref.watch(syncRunnerProvider);
    final total =
        ref.watch(projectPendingChangesProvider(projectId)).value ?? 0;
    final byType = ref.watch(pendingByTypeProvider(projectId)).value ?? {};
    final rejected = ref.watch(rejectedItemsProvider(projectId)).value ?? [];
    final conflicts = ref.watch(conflictsProvider(projectId)).value ?? [];
    final lockedVisits =
        ref.watch(lockedVisitIdsProvider(projectId)).value ?? {};
    final lastSync = ref.watch(lastSyncProvider);
    final lastBytes = ref.watch(lastSyncBytesProvider).value;
    final photos =
        ref.watch(pendingPhotosProvider).value ?? (count: 0, bytes: 0);
    final photoStorage = ref.watch(photoStorageProvider).value;
    final failedPhotos = ref.watch(failedPhotosProvider).value ?? [];
    final photoWifiOnly = ref.watch(photoWifiOnlyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Unsynced data')),
      // The app bar covers the top; SafeArea keeps the list above the system
      // navigation buttons.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            SyncNowCard(run: run, onPressed: _syncNow),
            const SizedBox(height: 16),
            const SyncSectionTitle('Waiting to sync'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Changes'),
                    trailing: Text('$total'),
                  ),
                  for (final entry in byType.entries)
                    ListTile(
                      dense: true,
                      title: Text(entityTypeLabel(entry.key)),
                      trailing: Text('${entry.value}'),
                    ),
                  ListTile(
                    title: const Text('Photos'),
                    trailing: Text(
                      '${photos.count} waiting · ${_formatBytes(photos.bytes)}',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: const Text('Photos on this phone'),
                    trailing: Text(
                      photoStorage == null ? '-' : _formatBytes(photoStorage),
                    ),
                  ),
                  if (photos.count > 0 && photoWifiOnly)
                    const ListTile(
                      dense: true,
                      leading: Icon(Icons.wifi),
                      title: Text(
                        'Wi-Fi only is on: photos upload when Wi-Fi is '
                        'connected.',
                      ),
                    ),
                  if (photos.count > 0)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.warning_amber_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: const Text(
                        'Photos that are not uploaded are lost if you clear '
                        "the app's data.",
                      ),
                    ),
                  ListTile(
                    title: const Text('Last successful sync'),
                    trailing: Text(
                      lastSync == null ? 'Never' : _timeAgo(lastSync),
                    ),
                  ),
                  ListTile(
                    title: const Text('Data of the last sync'),
                    trailing: Text(
                      lastBytes == null ? '-' : _formatBytes(lastBytes),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SyncSectionTitle('Errors'),
            if (rejected.isEmpty && failedPhotos.isEmpty)
              const Card(child: ListTile(title: Text('No errors')))
            else ...[
              for (final photo in failedPhotos)
                FailedPhotoCard(
                  photo: photo,
                  busy: run.running,
                  onRetry: () => _retryPhoto(photo),
                  onDelete: () => _deletePhoto(photo),
                ),
              for (final item in rejected)
                RejectedCard(
                  item: item,
                  busy: run.running,
                  // A change to a locked visit (the visit's own update or a
                  // batch of its track points, both with the visit's id)
                  // can't succeed until an admin unlocks it (T042).
                  canRetry: !lockedVisits.contains(item.entityId),
                  onRetry: () => _retry(item),
                  onDiscard: () => _discard(item),
                ),
            ],
            const SizedBox(height: 16),
            const SyncSectionTitle('Conflicts'),
            if (conflicts.isEmpty)
              const Card(child: ListTile(title: Text('No conflicts')))
            else
              for (final conflict in conflicts)
                ConflictCard(conflict: conflict),
          ],
        ),
      ),
    );
  }
}

/// "Just now", "5 minutes ago", "2 days ago", "3 months ago": the unit gets
/// coarser as time passes. A time slightly in the future counts as just now.
String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return _ago(diff.inMinutes, 'minute');
  if (diff.inDays < 1) return _ago(diff.inHours, 'hour');
  if (diff.inDays < 30) return _ago(diff.inDays, 'day');
  if (diff.inDays < 365) return _ago(diff.inDays ~/ 30, 'month');
  return _ago(diff.inDays ~/ 365, 'year');
}

/// "1 hour ago", "2 hours ago".
String _ago(int count, String unit) =>
    '$count $unit${count == 1 ? '' : 's'} ago';

/// 1536 becomes "1.5 KB".
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
