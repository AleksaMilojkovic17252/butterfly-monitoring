import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';

/// The state of the GPS tracker (T037): which visit is being recorded, the
/// interval, the number of stored points and the last fix, a "Tracking
/// interrupted" message after a resume, and any problem. Nothing is shown
/// when no visit is being tracked. T039's active visit screen takes this
/// over.
class TrackingStatusCard extends ConsumerWidget {
  const TrackingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingControllerProvider);
    final visitId = tracking.visitId;
    if (visitId == null) return const SizedBox.shrink();

    final controller = ref.read(trackingControllerProvider.notifier);
    final count = ref.watch(trackPointCountProvider(visitId)).value ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final lastFix = tracking.lastFixAt;
    final details = [
      if (tracking.intervalS != null) 'every ${tracking.intervalS} s',
      '$count points',
      if (lastFix != null) 'last fix ${_time(lastFix)}',
    ].join(' · ');
    final interruption = tracking.interruption;
    final problem = tracking.problem;
    final saveProblem = tracking.saveProblem;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              tracking.recording ? Icons.gps_fixed : Icons.gps_off,
              color: tracking.recording ? scheme.primary : scheme.error,
            ),
            title: Text('Visit in progress: ${tracking.transectCode}'),
            subtitle: Text(details),
          ),
          if (interruption != null)
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: Text(
                'Tracking interrupted '
                '${_time(interruption.from)}–${_time(interruption.to)}',
              ),
              trailing: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: controller.dismissInterruption,
              ),
            ),
          if (problem != null)
            ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: scheme.error),
              title: Text(problem),
              // While GPS runs, fixes clear the problem by themselves;
              // restarting it then would only lose the running stream.
              trailing: tracking.recording
                  ? null
                  : TextButton(
                      onPressed: controller.retry,
                      child: const Text('Try again'),
                    ),
            ),
          if (saveProblem != null)
            ListTile(
              leading: Icon(Icons.error_outline, color: scheme.error),
              title: Text(saveProblem),
            ),
        ],
      ),
    );
  }

  /// [utc] as local `HH:mm`.
  static String _time(DateTime utc) {
    final local = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }
}
