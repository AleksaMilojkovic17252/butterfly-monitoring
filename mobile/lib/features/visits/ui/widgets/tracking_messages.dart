import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';

/// The tracker's messages, one row each when there is one: "Tracking
/// interrupted" after a resume, a location problem (with Try again when GPS
/// is not running) and points that could not be saved. Shared by the
/// tracking card and the active visit screen (T039).
class TrackingMessages extends ConsumerWidget {
  const TrackingMessages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingControllerProvider);
    final controller = ref.read(trackingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final interruption = tracking.interruption;
    final problem = tracking.problem;
    final saveProblem = tracking.saveProblem;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (interruption != null)
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: Text(
              'Tracking interrupted '
              '${trackingTime(interruption.from)}–'
              '${trackingTime(interruption.to)}',
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
    );
  }
}

/// [utc] as local `HH:mm`. Also used by `TrackingStatusCard`.
String trackingTime(DateTime utc) {
  final local = utc.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
