import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/sync/domain/sync_error_message.dart';
import 'package:mobile/features/sync/domain/sync_status_providers.dart';

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
    final photos = ref.watch(pendingPhotosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Unsynced data')),
      // The app bar covers the top; SafeArea keeps the list above the system
      // navigation buttons.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _SyncNowCard(run: run, onPressed: _syncNow),
            const SizedBox(height: 16),
            const _SectionTitle('Waiting to sync'),
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
                      '${photos.count} · ${_formatBytes(photos.bytes)}',
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
            const _SectionTitle('Errors'),
            if (rejected.isEmpty)
              const Card(child: ListTile(title: Text('No errors')))
            else
              for (final item in rejected)
                _RejectedCard(
                  item: item,
                  busy: run.running,
                  // A change to a locked visit (the visit's own update or a
                  // batch of its track points, both with the visit's id)
                  // can't succeed until an admin unlocks it (T042).
                  canRetry: !lockedVisits.contains(item.entityId),
                  onRetry: () => _retry(item),
                  onDiscard: () => _discard(item),
                ),
            const SizedBox(height: 16),
            const _SectionTitle('Conflicts'),
            if (conflicts.isEmpty)
              const Card(child: ListTile(title: Text('No conflicts')))
            else
              for (final conflict in conflicts)
                _ConflictCard(conflict: conflict),
          ],
        ),
      ),
    );
  }
}

/// A section heading. A Card has a 4 px margin of its own, so the heading
/// gets the same, and its text starts where the cards do.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// The Sync now button; while a run is going it shows its progress.
class _SyncNowCard extends StatelessWidget {
  const _SyncNowCard({required this.run, required this.onPressed});
  final SyncRunState run;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final progress = switch (run.phase) {
      SyncPhase.pushing => 'Sending changes… ${run.sent} sent',
      SyncPhase.pulling => 'Receiving… ${run.received} rows',
      null => 'Working…',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: run.running ? null : onPressed,
              icon: const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
            if (run.running) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(progress),
            ],
          ],
        ),
      ),
    );
  }
}

/// One item the server rejected, with the reason and the two ways out.
class _RejectedCard extends StatelessWidget {
  const _RejectedCard({
    required this.item,
    required this.busy,
    required this.canRetry,
    required this.onRetry,
    required this.onDiscard,
  });
  final SyncQueueItem item;

  /// A sync is running: the buttons wait.
  final bool busy;

  /// False hides Retry: it could only be rejected again.
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entityTypeLabel(item.entityType)} · '
              '${_operationLabel(item.operation)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(syncErrorMessage(item.lastError)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onDiscard,
                  child: const Text('Discard local change'),
                ),
                if (canRetry) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: busy ? null : onRetry,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A conflict, read only: an admin settles it in Django admin.
class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.conflict});
  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
    final resolvedAt = conflict.resolvedAt;
    final String text;
    if (conflict.status == 'open') {
      text = 'An admin will resolve this. Your change is kept on the server.';
    } else {
      final winner = conflict.status == 'resolved_server'
          ? 'Server version kept'
          : 'Your change applied';
      final when = resolvedAt == null
          ? ''
          : ' · ${_formatTime(context, resolvedAt)}';
      final note = conflict.resolutionNote.isEmpty
          ? ''
          : '\n${conflict.resolutionNote}';
      text = '$winner$when$note';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entityTypeLabel(conflict.entityType)} · '
              '${_operationLabel(conflict.operation)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text('Fields: ${_fieldsText(conflict.conflictingFields)}'),
            const SizedBox(height: 4),
            Text(text),
          ],
        ),
      ),
    );
  }
}

/// `create` becomes "Create" and so on; an unknown value shows as it is.
String _operationLabel(String operation) => switch (operation) {
  'create' => 'Create',
  'update' => 'Update',
  'delete' => 'Delete',
  'create_batch' => 'Create (batch)',
  _ => operation,
};

/// The conflicting field names, stored as a JSON list.
String _fieldsText(String json) {
  try {
    return (jsonDecode(json) as List).join(', ');
  } catch (_) {
    return json;
  }
}

/// Local date and time, like the Settings sync tile.
String _formatTime(BuildContext context, DateTime time) {
  final localizations = MaterialLocalizations.of(context);
  final local = time.toLocal();
  return '${localizations.formatShortDate(local)}, '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
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
