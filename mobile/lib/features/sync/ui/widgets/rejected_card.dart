import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/sync/domain/sync_error_message.dart';

/// One item the server rejected, with the reason and the two ways out.
class RejectedCard extends StatelessWidget {
  const RejectedCard({
    super.key,
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
              '${operationLabel(item.operation)}',
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
