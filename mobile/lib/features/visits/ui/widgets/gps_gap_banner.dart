import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';

/// "No GPS fix for N s", shown on the active visit screen while GPS is
/// recording and no fix has arrived for more than [gpsGapS] seconds (T038).
///
/// The seconds count from when the newest fix was received (not its own
/// timestamp, which can be old: a cached first fix, a replay), or from when
/// GPS started if none has come yet. The banner goes away by itself with the next fix, and stays
/// quiet while the visit is paused (GPS is off then, on purpose).
///
/// This is live feedback only. The gaps are listed later by the Finish
/// screen's warnings (T040) and flagged by the server (T056).
class GpsGapBanner extends ConsumerStatefulWidget {
  const GpsGapBanner({super.key, required this.gpsGapS});

  /// The protocol's `gps_gap_s`.
  final int gpsGapS;

  @override
  ConsumerState<GpsGapBanner> createState() => _GpsGapBannerState();
}

class _GpsGapBannerState extends ConsumerState<GpsGapBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Rebuilds every second, so the number counts up between fixes.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingControllerProvider);
    if (!tracking.recording || tracking.paused) return const SizedBox.shrink();

    final since = tracking.fixReceivedAt ?? tracking.recordingSince;
    if (since == null) return const SizedBox.shrink();
    final seconds = DateTime.now().toUtc().difference(since).inSeconds;
    if (seconds <= widget.gpsGapS) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.gps_not_fixed, color: scheme.error),
      title: Text('No GPS fix for $seconds s'),
    );
  }
}
