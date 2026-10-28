import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';
import 'package:mobile/features/visits/ui/widgets/tracking_messages.dart';

/// The state of the GPS tracker (T037) on project home and the transect
/// detail: which visit is being recorded, the interval, the number of stored
/// points and the last fix, plus [TrackingMessages]. Tapping it opens the
/// active visit screen (T039). Nothing is shown when no visit is being
/// tracked.
class TrackingStatusCard extends ConsumerWidget {
  const TrackingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingControllerProvider);
    final visitId = tracking.visitId;
    if (visitId == null) return const SizedBox.shrink();

    final projectId = ref.watch(visitProvider(visitId)).value?.projectId;
    final count = ref.watch(trackPointCountProvider(visitId)).value ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final lastFix = tracking.lastFixAt;
    final details = [
      if (tracking.paused)
        'paused'
      else if (tracking.intervalS != null)
        'every ${tracking.intervalS} s',
      '$count points',
      if (lastFix != null) 'last fix ${trackingTime(lastFix)}',
    ].join(' · ');

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              tracking.paused
                  ? Icons.pause_circle_outline
                  : tracking.recording
                  ? Icons.gps_fixed
                  : Icons.gps_off,
              color: tracking.recording || tracking.paused
                  ? scheme.primary
                  : scheme.error,
            ),
            title: Text('Visit in progress: ${tracking.transectCode}'),
            subtitle: Text(details),
            trailing: projectId == null
                ? null
                : const Icon(Icons.chevron_right),
            onTap: projectId == null
                ? null
                : () => context.push('/projects/$projectId/visits/$visitId'),
          ),
          const TrackingMessages(),
        ],
      ),
    );
  }
}
