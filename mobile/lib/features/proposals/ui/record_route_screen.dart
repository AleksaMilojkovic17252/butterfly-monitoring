import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/ui/free_observation_entry.dart';
import 'package:mobile/features/proposals/data/proposal_repository.dart';
import 'package:mobile/features/proposals/data/route_recording_repository.dart';
import 'package:mobile/features/proposals/domain/recording_stats.dart';
import 'package:mobile/features/proposals/domain/route_recorder.dart';
import 'package:mobile/features/proposals/ui/widgets/proposal_details_sheet.dart';
import 'package:mobile/features/proposals/ui/widgets/proposal_map.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/visits/domain/walking_time.dart';
import 'package:mobile/features/visits/ui/tracking_permissions.dart';
import 'package:mobile/features/visits/ui/widgets/header_figure.dart';
import 'package:mobile/features/visits/ui/widgets/paused_banner.dart';

/// The screen where a route proposal is recorded (T108), at
/// `/projects/:id/proposals/record?replaces=<transectId>`.
///
/// Opened with no recording, it asks for the GPS permissions and starts one.
/// Opened with a recording already in progress (from another project, or after
/// the app was killed), it shows that recording instead. Leaving the screen
/// does not stop the recording: the `RouteRecorder` keeps the GPS running and
/// the transect list shows a card to come back.
///
/// Everything comes from Drift and the recorder, so it works offline.
class RecordRouteScreen extends ConsumerStatefulWidget {
  const RecordRouteScreen({
    super.key,
    required this.projectId,
    this.replacesTransectId,
  });
  final String projectId;

  /// The transect the route would replace, or null for a new route.
  final String? replacesTransectId;

  @override
  ConsumerState<RecordRouteScreen> createState() => _RecordRouteScreenState();
}

class _RecordRouteScreenState extends ConsumerState<RecordRouteScreen> {
  /// Used when the project protocol is not on the phone: the server's default
  /// `gps_accuracy_warning_m`.
  static const _defaultWarningM = 25.0;

  Timer? _clock;

  /// Why a recording could not be started (a visit in progress), or null.
  String? _startError;

  /// True while a save, pause or discard is running, so a button is not
  /// pressed twice.
  bool _busy = false;

  /// True once the screen is leaving, so it does not flash the "starting"
  /// spinner after the recording has been deleted.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // Makes the time tick.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _openOrStart());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /// Starts a recording unless one is already open.
  Future<void> _openOrStart() async {
    final open = await ref.read(openRecordingProvider.future);
    if (open != null || !mounted) return;
    // Permissions first: Android 14 starts a location service only while the
    // app is in front, not under a system dialog.
    await prepareTracking(context, ref);
    if (!mounted) return;
    try {
      await ref
          .read(routeRecordingRepositoryProvider)
          .start(
            widget.projectId,
            replacesTransectId: widget.replacesTransectId,
          );
    } on StateError catch (error) {
      if (mounted) setState(() => _startError = error.message);
    }
  }

  /// Leaves the screen: back if there is somewhere to go back to, else to the
  /// transect list.
  void _leave() {
    _leaving = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/projects/${widget.projectId}/transects');
    }
  }

  Future<void> _pauseOrResume(RouteRecording recording) async {
    setState(() => _busy = true);
    final repository = ref.read(routeRecordingRepositoryProvider);
    try {
      if (recording.pausedAt == null) {
        await repository.pause(recording.id);
      } else {
        await repository.resume(recording.id);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard(RouteRecording recording) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this recording?'),
        content: const Text('The route recorded so far will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep recording'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    _leaving = true;
    await ref.read(routeRecordingRepositoryProvider).discard(recording.id);
    if (mounted) _leave();
  }

  /// Finish: stores the buffered fixes, asks for the details and saves the
  /// proposal.
  Future<void> _finish(RouteRecording recording, double warningM) async {
    final userId = ref.read(authControllerProvider).profile?.id;
    if (userId == null) return;
    setState(() => _busy = true);
    try {
      // The line is made from the stored fixes, so write the buffer first.
      await ref.read(routeRecorderProvider.notifier).flush();
      final stored = await ref
          .read(routeRecordingRepositoryProvider)
          .watchPoints(recording.id)
          .first;
      final fixes = usableLineFixes(stored, warningM);
      if (!mounted) return;
      final details = await ProposalDetailsSheet.show(
        context,
        lengthM: recordingLengthM(stored, warningM),
        fixCount: fixes.length,
      );
      if (details == null || !mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref
            .read(proposalRepositoryProvider)
            .createFromRecording(
              recording: recording,
              name: details.name,
              reason: details.reason,
              notes: details.notes,
              warningM: warningM,
              userId: userId,
              // The line the sheet showed, not fixes that came in since.
              throughSequence: stored.isEmpty
                  ? null
                  : stored.last.sequenceNumber,
            );
      } on StateError catch (error) {
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
      _leaving = true;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Route proposal saved. It will be sent at the next sync.',
          ),
        ),
      );
      if (mounted) context.go('/projects/${widget.projectId}/transects');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(openRecordingProvider);
    final recording = open.value;

    if (recording == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record a route')),
        body: Center(
          child: _startError != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_startError!, textAlign: TextAlign.center),
                )
              : _leaving
              ? const SizedBox.shrink()
              : const CircularProgressIndicator(),
        ),
      );
    }
    return _view(recording);
  }

  Widget _view(RouteRecording recording) {
    final scheme = Theme.of(context).colorScheme;
    final paused = recording.pausedAt != null;
    final recorder = ref.watch(routeRecorderProvider);
    final protocol = ref
        .watch(projectProtocolProvider(recording.projectId))
        .value;
    final warningM = protocol?.gpsAccuracyWarningM ?? _defaultWarningM;
    final stored = ref.watch(recordingPointsProvider(recording.id)).value ?? [];
    final transects =
        ref.watch(projectTransectsProvider(recording.projectId)).value ?? [];
    final replacedId = recording.replacesTransectId;
    final replaced = replacedId == null
        ? null
        : ref.watch(transectProvider(replacedId)).value;

    final line = [
      for (final fix in usableLineFixes(stored, warningM))
        LatLng(fix.lat, fix.lon),
    ];
    final position = recorder.lastPosition;
    final gps = recorder.problem != null
        ? 'No GPS'
        : position == null
        ? 'Waiting for GPS…'
        : '± ${position.accuracy.round()} m';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record a route'),
        actions: [
          IconButton(
            tooltip: 'Discard',
            onPressed: _busy ? null : () => _discard(recording),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (replaced != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Replaces ${replaced.code} · ${replaced.name}'),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                HeaderFigure(
                  label: 'Length',
                  value: formatLength(recordingLengthM(stored, warningM)),
                ),
                HeaderFigure(
                  label: 'Time',
                  value: formatWalkingTime(
                    recordingTime(recording, DateTime.now().toUtc()),
                  ),
                ),
                HeaderFigure(label: 'GPS', value: gps),
              ],
            ),
          ),
          if (paused) const PausedBanner(),
          if (recorder.problem != null)
            Material(
              color: scheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.gps_off, color: scheme.onErrorContainer),
                title: Text(
                  recorder.problem!,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
                trailing: TextButton(
                  onPressed: ref.read(routeRecorderProvider.notifier).retry,
                  child: const Text('Try again'),
                ),
              ),
            ),
          Expanded(
            child: ProposalMap(
              transects: [
                for (final t in transects)
                  ProposalMapTransect(
                    line: parseLineString(t.geometry),
                    replaced: t.id == replacedId,
                  ),
              ],
              line: line,
              // While paused there is no new fix, so the dot stays where the
              // pause began.
              position: position == null
                  ? null
                  : LatLng(position.latitude, position.longitude),
              accuracyM: position?.accuracy,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pauseOrResume(recording),
                      icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                      label: Text(paused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // An icon only, so it never gets cut off. Opens the free
                  // observation entry (source incidental).
                  IconButton.filledTonal(
                    tooltip: 'Add a sighting',
                    onPressed: () =>
                        openFreeObservation(context, ref, recording.projectId),
                    iconSize: 28,
                    icon: const Icon(Icons.bug_report_outlined),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _finish(recording, warningM),
                      icon: const Icon(Icons.flag),
                      label: const Text('Finish'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
