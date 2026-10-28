import 'package:flutter/material.dart';
import 'package:mobile/core/sync/sync_runner.dart';

/// The Sync now button; while a run is going it shows its progress.
class SyncNowCard extends StatelessWidget {
  const SyncNowCard({super.key, required this.run, required this.onPressed});
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
