import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/ui/widgets/quick_butterfly_sheet.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/ui/widgets/transect_map.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/current_section.dart';
import 'package:mobile/features/visits/domain/keep_screen_on.dart';
import 'package:mobile/features/visits/domain/route_length.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';
import 'package:mobile/features/visits/ui/widgets/gps_gap_banner.dart';
import 'package:mobile/features/visits/ui/widgets/paused_banner.dart';
import 'package:mobile/features/visits/ui/widgets/tracking_messages.dart';
import 'package:mobile/features/visits/ui/widgets/visit_buttons.dart';
import 'package:mobile/features/visits/ui/widgets/visit_header.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Used when the project protocol is not on the phone: the server's default
/// `gps_accuracy_warning_m`.
const _defaultAccuracyWarningM = 25.0;

/// Used when the project protocol is not on the phone: the server's default
/// `gps_gap_s`.
const _defaultGpsGapS = 60;

/// Used for the battery-saver snackbar when the protocol is not on the phone:
/// the server's defaults for `gps_interval_s` and
/// `gps_interval_battery_saver_s` (the tracker uses the same).
const _defaultIntervalS = 5;
const _defaultBatterySaverIntervalS = 15;

/// The screen of a visit in progress, shown by `ActiveVisitScreen` once the
/// visit is loaded.
class ActiveVisitView extends ConsumerStatefulWidget {
  const ActiveVisitView({super.key, required this.visit});
  final SurveyVisit visit;

  @override
  ConsumerState<ActiveVisitView> createState() => _ActiveVisitViewState();
}

class _ActiveVisitViewState extends ConsumerState<ActiveVisitView> {
  /// True while a pause or resume is being saved.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Keeps the screen on while this screen is open and the toggle is on.
    ref.listenManual(
      keepScreenOnProvider,
      (_, on) => WakelockPlus.toggle(enable: on),
      fireImmediately: true,
    );
    // The low battery can switch the battery saver on while this screen is
    // open, or before it was opened. The flag stays until it was shown.
    ref.listenManual(
      trackingControllerProvider.select((t) => t.batterySaverAuto),
      (_, auto) {
        if (auto) _showBatterySaverAuto();
      },
    );
    // A snackbar cannot be shown while the screen is still being built, so
    // the flag set before the screen opened is handled after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(trackingControllerProvider).batterySaverAuto) {
        _showBatterySaverAuto();
      }
    });
  }

  /// Tells the observer that the low battery turned the battery saver on,
  /// then clears the flag so it is shown once.
  void _showBatterySaverAuto() {
    _showMessage('Battery below 20 %: battery saver is on');
    ref.read(trackingControllerProvider.notifier).acknowledgeBatterySaverAuto();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  bool get _paused => widget.visit.pausedAt != null;

  /// Pauses or resumes the visit. The tracker follows the row: it stops GPS
  /// on a pause and starts it again on resume.
  Future<void> _togglePause() async {
    setState(() => _saving = true);
    final repository = ref.read(visitRepositoryProvider);
    try {
      if (_paused) {
        await repository.resume(widget.visit.id);
      } else {
        await repository.pause(widget.visit.id);
      }
    } catch (error) {
      _showMessage('Could not ${_paused ? 'resume' : 'pause'}: $error');
    }
    if (mounted) setState(() => _saving = false);
  }

  /// Asks first while the visit is paused: an observation then is outside
  /// the standardised walk. True when the observer goes on.
  Future<bool> _confirmIfPaused() async {
    if (!_paused) return true;
    final goOn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.pause_circle_outline),
        title: const Text('The visit is paused'),
        content: const Text(
          'An observation made during a pause is not part of the walk. '
          'Record it anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Record anyway'),
          ),
        ],
      ),
    );
    return goOn == true && mounted;
  }

  /// Opens the quick butterfly entry (T045) and offers Undo for what it saved.
  Future<void> _addButterfly() async {
    if (!await _confirmIfPaused()) return;
    if (!mounted) return;
    // Taken now: the Undo button may be pressed after this screen is gone.
    final repository = ref.read(observationRepositoryProvider);
    final protocol = ref.read(projectProtocolProvider(widget.visit.projectId));
    final saved = await QuickButterflySheet.show(
      context,
      visit: widget.visit,
      accuracyWarningM:
          protocol.value?.gpsAccuracyWarningM ?? _defaultAccuracyWarningM,
    );
    if (saved == null || !mounted) return;
    // Stays 10 s, then goes by itself. A snackbar with an action would
    // otherwise stay until it is closed (`persist` defaults to true).
    _showMessage(
      'Saved: ${saved.label}',
      duration: const Duration(seconds: 10),
      persist: false,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => repository.undo(saved.id),
      ),
    );
  }

  Future<void> _addPlant() async {
    if (!await _confirmIfPaused()) return;
    // TODO(T052): open the plant entry.
    _showMessage('Plant entry is coming in a later version');
  }

  Future<void> _addHabitat() async {
    if (!await _confirmIfPaused()) return;
    // TODO(T054): open the habitat feature entry.
    _showMessage('Habitat entry is coming in a later version');
  }

  /// Opens the Finish screen (T040). Backing out of it changes nothing.
  void _finish() {
    context.push(
      '/projects/${widget.visit.projectId}/visits/${widget.visit.id}/finish',
    );
  }

  /// Turns keep-screen-on on or off and says which, since a tooltip only
  /// shows on a long press.
  void _toggleKeepScreenOn(bool keepScreenOn) {
    ref.read(keepScreenOnProvider.notifier).save(!keepScreenOn);
    _showMessage(
      keepScreenOn
          ? 'The screen can turn off again'
          : 'The screen stays on during the visit',
      // Short: the snackbar covers Pause and Finish while it shows.
      duration: const Duration(seconds: 2),
    );
  }

  /// Turns battery-saver mode off when it [wasOn], otherwise on, and says
  /// which, with the interval GPS now uses. Says so too when the mode could
  /// not be changed (the tracker then shows why).
  Future<void> _toggleBatterySaver(bool wasOn) async {
    final controller = ref.read(trackingControllerProvider.notifier);
    await controller.setBatterySaver(!wasOn);
    if (!mounted) return;

    final tracking = ref.read(trackingControllerProvider);
    if (tracking.batterySaver == wasOn) {
      _showMessage('Could not change the battery saver');
      return;
    }
    // No interval while the visit is paused: GPS is off until Resume.
    final protocol = ref
        .read(projectProtocolProvider(widget.visit.projectId))
        .value;
    final intervalS =
        tracking.intervalS ??
        (tracking.batterySaver
            ? protocol?.gpsIntervalBatterySaverS ??
                  _defaultBatterySaverIntervalS
            : protocol?.gpsIntervalS ?? _defaultIntervalS);
    _showMessage(
      tracking.batterySaver
          ? 'Battery saver on: a point every $intervalS s, lower accuracy'
          : 'Battery saver off: a point every $intervalS s',
      duration: const Duration(seconds: 2),
    );
  }

  void _showMessage(
    String text, {
    Duration duration = const Duration(seconds: 4),
    bool? persist,
    SnackBarAction? action,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: duration,
          persist: persist,
          action: action,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final transect = ref.watch(transectProvider(visit.transectId)).value;
    final sections =
        ref.watch(transectSectionsProvider(visit.transectId)).value ?? [];
    final protocol = ref.watch(projectProtocolProvider(visit.projectId)).value;
    final route = ref.watch(visitRouteProvider(visit.id)).value ?? [];
    final tracking = ref.watch(trackingControllerProvider);
    final currentSection = ref.watch(currentSectionProvider(visit.id));
    final observations =
        ref.watch(visitObservationCountProvider(visit.id)).value ?? 0;
    final keepScreenOn = ref.watch(keepScreenOnProvider);

    final tracked = tracking.visitId == visit.id;
    final position = tracked ? tracking.lastPosition : null;
    // GPS delivers fixes now, so the position on the map is current.
    final live = tracked && tracking.recording && !_paused;
    final distanceM = routeLengthM(
      route,
      protocol?.gpsAccuracyWarningM ?? _defaultAccuracyWarningM,
    );
    final sectionIndex = currentSection == null
        ? null
        : sections.indexWhere((s) => s.section.id == currentSection.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Visit · ${transect?.code ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Battery saver',
            isSelected: tracking.batterySaver,
            // Off: a plain battery. On: the saver battery on a tinted
            // background, so the two states are easy to tell apart.
            icon: const Icon(Icons.battery_std),
            selectedIcon: const Icon(Icons.battery_saver),
            onPressed: tracked
                ? () => _toggleBatterySaver(tracking.batterySaver)
                : null,
          ),
          IconButton(
            // Kept for TalkBack, which reads the tooltip as the label.
            tooltip: 'Keep the screen on',
            isSelected: keepScreenOn,
            icon: const Icon(Icons.light_mode_outlined),
            selectedIcon: const Icon(Icons.light_mode),
            onPressed: () => _toggleKeepScreenOn(keepScreenOn),
          ),
        ],
      ),
      body: Column(
        children: [
          VisitHeader(
            visit: visit,
            distanceM: distanceM,
            sectionCode: currentSection?.sectionCode,
            observations: observations,
          ),
          if (_paused) const PausedBanner(),
          if (!tracked)
            const ListTile(
              leading: Icon(Icons.gps_off),
              title: Text('The route of this visit is not recorded here.'),
            ),
          const TrackingMessages(),
          if (tracked)
            GpsGapBanner(gpsGapS: protocol?.gpsGapS ?? _defaultGpsGapS),
          Expanded(
            // The buttons below keep clear of the system navigation bar.
            // Without this the map's attribution leaves room for it too, and
            // floats above the bottom edge of the map.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: TransectMap(
                line: transect == null
                    ? const []
                    : parseLineString(transect.geometry),
                sections: [
                  for (final s in sections) parseLineString(s.section.geometry),
                ],
                currentSection: sectionIndex,
                overlays: _overlays(context, route, position, live: live),
              ),
            ),
          ),
          VisitButtons(
            paused: _paused,
            // Only the phone that records the route pauses it: another
            // phone's pause would send its own `paused_seconds`.
            canPause: tracked && !_saving,
            onAddButterfly: _addButterfly,
            onAddPlant: _addPlant,
            onAddHabitat: _addHabitat,
            onPause: _togglePause,
            onFinish: _finish,
          ),
        ],
      ),
    );
  }

  /// The map layers of the walk: the route so far, and the newest [position]
  /// with a circle as wide as its accuracy. The position is grey unless
  /// [live], since it may be old then (paused, or GPS not running).
  List<Widget> _overlays(
    BuildContext context,
    List<SurveyTrackPoint> route,
    Position? position, {
    required bool live,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final here = position == null
        ? null
        : LatLng(position.latitude, position.longitude);
    final accuracyM = position?.accuracy ?? 0;
    final dotColor = live ? scheme.primary : Colors.grey;
    final routePoints = [
      for (final p in route) LatLng(p.lat, p.lon),
      // Stored points lag up to 30 s behind (T037's buffer), so the line
      // runs on to the newest fix.
      if (here != null && live) here,
    ];
    return [
      // Right after Start there are no points yet, and flutter_map cannot
      // draw a line without points (it asserts).
      if (routePoints.length >= 2)
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              strokeWidth: 3,
              color: Colors.black87,
            ),
          ],
        ),
      if (here != null) ...[
        CircleLayer(
          circles: [
            CircleMarker(
              point: here,
              radius: accuracyM,
              useRadiusInMeter: true,
              color: dotColor.withValues(alpha: 0.15),
              borderColor: dotColor,
              borderStrokeWidth: 1,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: here,
              width: 20,
              height: 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
      ],
    ];
  }
}
