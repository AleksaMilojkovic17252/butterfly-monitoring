import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/core/location/location_message.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/location/walk_positions.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// How a shape is drawn. A polygon can be tapped out or walked.
enum _Method { point, polygonTap, polygonWalk, line }

/// A walked corner is kept only when the fix is at least this accurate (metres).
const _maxWalkAccuracyM = 15.0;

/// A walked corner is kept only when it is at least this far (metres) from the
/// last one. During a tracked visit the tracker's own interval makes the
/// corners further apart (D-087).
const _walkSpacingM = 2.0;

/// A tapped corner closer than this (metres) to the last one is the same tap
/// twice, and is ignored.
const _tapSpacingM = 0.05;

/// Under about this many metres across, a walked shape is too coarse for GPS.
const _coarseBelowM = 10.0;

const _distance = Distance(roundResult: false);

/// Draws a point, a line or a polygon on a map (T052), and reports the finished
/// shape through [onChanged] (null while it is not finished or not valid). Plant
/// entry uses a point or a polygon; habitat entry (T054) reuses it with a line.
///
/// - **Point:** tap the map, drag the pin, or use the phone's position.
/// - **Polygon (tap):** tap the corners, then Close.
/// - **Polygon (walk):** walk the edge; a corner is kept about every 2 m. During
///   a tracked visit the corners come from the tracker's fixes instead, because
///   geolocator shares one position stream (D-087).
/// - **Line:** tap the points; needs 2 or more.
///
/// A polygon whose edges cross cannot be closed. It fills the space it gets, so
/// put it in a full-screen route (`showGeometryCapture`): map gestures lose to
/// scrolling inside a bottom sheet or a list.
class GeometryCaptureWidget extends ConsumerStatefulWidget {
  const GeometryCaptureWidget({
    super.key,
    required this.modes,
    required this.onChanged,
    this.initial,
    this.referenceLines = const [],
  });

  /// The shapes that may be drawn. Each of `point`, `polygon` and `line` that
  /// is in the set gets its method in the selector at the top.
  final Set<GeometryMode> modes;

  /// A shape to start from, for editing; null to start empty.
  final CapturedGeometry? initial;

  /// Gets the finished shape, or null while there is none. Called after every
  /// change.
  final ValueChanged<CapturedGeometry?> onChanged;

  /// Lines drawn dashed as a guide, for example the project's transects.
  final List<List<LatLng>> referenceLines;

  @override
  ConsumerState<GeometryCaptureWidget> createState() =>
      _GeometryCaptureWidgetState();
}

class _GeometryCaptureWidgetState extends ConsumerState<GeometryCaptureWidget> {
  late _Method _method;

  /// The point, or the corners of the polygon or line, in the order drawn. A
  /// closed polygon does not repeat its first corner.
  final _points = <LatLng>[];
  bool _closed = false;

  /// True between Start walking and Stop (or Close).
  bool _walking = false;

  /// Whether the screen was kept on before walking started, so it is put back.
  bool _hadWakelock = false;

  /// True from the moment this widget switched the screen lock on until it
  /// switched it back. [dispose] restores from this, not from [_walking], which
  /// is only set after the awaits of [_startWalking].
  bool _wakelockTaken = false;

  /// The phone's last known position, shown as a blue dot.
  LatLng? _here;

  /// A message under the map: waiting for GPS, a location problem, or similar.
  String? _note;

  /// True while the pin is being dragged; the map's own gestures are off then.
  bool _dragging = false;

  /// True while "Use my position" waits for a fix.
  bool _locating = false;

  /// Set when the user moves the map, so a late position does not pull the
  /// camera away.
  bool _userMovedMap = false;

  final _mapController = MapController();
  final _mapKey = GlobalKey();

  // The starting camera, chosen once in initState (see _chooseStartCamera).
  // When [_startFit] is set it wins over the centre and zoom.
  var _startCenter = const LatLng(44.0, 21.0);
  var _startZoom = 6.0;
  CameraFit? _startFit;

  /// True when nothing is known to start from, so the last known position is
  /// asked for once the map exists.
  var _needsLastKnown = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _method = _firstMethod();
    if (initial != null) {
      _points.addAll(initial.points);
      switch (initial.mode) {
        case GeometryMode.point:
          _method = _Method.point;
        case GeometryMode.line:
          _method = _Method.line;
        case GeometryMode.polygon:
          _method = _Method.polygonTap;
          _closed = true;
      }
    }
    _chooseStartCamera();
  }

  @override
  void dispose() {
    _releaseWakelock();
    _mapController.dispose();
    super.dispose();
  }

  /// The methods the selector offers, in order.
  List<_Method> get _methods => [
    if (widget.modes.contains(GeometryMode.point)) _Method.point,
    if (widget.modes.contains(GeometryMode.polygon)) ...[
      _Method.polygonTap,
      _Method.polygonWalk,
    ],
    if (widget.modes.contains(GeometryMode.line)) _Method.line,
  ];

  _Method _firstMethod() => _methods.isEmpty ? _Method.point : _methods.first;

  bool get _isPolygon =>
      _method == _Method.polygonTap || _method == _Method.polygonWalk;

  /// The finished shape, or null.
  CapturedGeometry? get _value {
    switch (_method) {
      case _Method.point:
        return _points.length == 1
            ? CapturedGeometry.point(_points.first)
            : null;
      case _Method.line:
        return _points.length >= 2
            ? CapturedGeometry(mode: GeometryMode.line, points: [..._points])
            : null;
      case _Method.polygonTap:
      case _Method.polygonWalk:
        final valid =
            _closed && _points.length >= 3 && !polygonSelfIntersects(_points);
        return valid
            ? CapturedGeometry(mode: GeometryMode.polygon, points: [..._points])
            : null;
    }
  }

  void _publish() => widget.onChanged(_value);

  // --- Choosing the method ---------------------------------------------------

  /// Switches to [method]. With something drawn it asks first, because the
  /// drawing is cleared.
  Future<void> _selectMethod(_Method method) async {
    if (method == _method) return;
    if (_points.isNotEmpty) {
      final change = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start again?'),
          content: const Text('Changing the method clears what you drew.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Change'),
            ),
          ],
        ),
      );
      if (change != true || !mounted) return;
    }
    _releaseWakelock();
    setState(() {
      _method = method;
      _points.clear();
      _closed = false;
      _walking = false;
      _note = null;
    });
    _publish();
  }

  // --- Point ---------------------------------------------------------------

  /// The newest fix: the visit tracker's while it records (it owns the one GPS
  /// stream, D-087), otherwise a fresh reading. Null with a [_note] when there
  /// is none.
  Future<LatLng?> _currentFix() async {
    final tracking = ref.read(trackingControllerProvider);
    final live = tracking.recording && !tracking.paused
        ? tracking.lastPosition
        : null;
    if (live != null) return LatLng(live.latitude, live.longitude);
    try {
      final position = await ref.read(currentPositionProvider)();
      return LatLng(position.latitude, position.longitude);
    } on LocationException catch (error) {
      if (mounted) setState(() => _note = locationMessage(error.failure));
      return null;
    } catch (error) {
      // Anything else (a platform error): say so, so "Use my position" is not
      // left disabled with no explanation.
      if (mounted) setState(() => _note = 'Could not get the position: $error');
      return null;
    }
  }

  /// Puts the pin on the phone's position and moves the map there.
  Future<void> _useMyPosition() async {
    setState(() {
      _locating = true;
      _note = null;
    });
    final fix = await _currentFix();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (fix != null) {
        _here = fix;
        _points
          ..clear()
          ..add(fix);
      }
    });
    if (fix != null) {
      _mapController.move(
        fix,
        _mapController.camera.zoom.clamp(17.0, 20.0).toDouble(),
      );
      _publish();
    }
  }

  /// Moves the pin to the finger while it is dragged. The finger's position is
  /// turned into a place with the map's camera.
  void _dragPin(DragUpdateDetails details) {
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final place = _mapController.camera.screenOffsetToLatLng(local);
    setState(() {
      _points
        ..clear()
        ..add(place);
    });
    _publish();
  }

  void _endDrag() {
    if (_dragging) setState(() => _dragging = false);
  }

  // --- Tapping -----------------------------------------------------------------

  void _onMapTap(LatLng place) {
    switch (_method) {
      case _Method.point:
        setState(() {
          _points
            ..clear()
            ..add(place);
        });
      case _Method.polygonTap:
      case _Method.line:
        if (_closed) return;
        if (_points.isNotEmpty &&
            _distance.as(LengthUnit.Meter, _points.last, place) <
                _tapSpacingM) {
          return;
        }
        setState(() => _points.add(place));
      case _Method.polygonWalk:
        return; // corners come from the GPS
    }
    _publish();
  }

  // --- Walking -----------------------------------------------------------------

  /// Keeps the screen on while walking, because without a foreground service
  /// the GPS stops when the screen turns off. What was set before is put back.
  Future<void> _startWalking() async {
    // A second tap while the first is still waiting must not overwrite
    // [_hadWakelock] with the value this widget set itself.
    if (_wakelockTaken) return;
    _wakelockTaken = true;
    _hadWakelock = await WakelockPlus.enabled;
    await WakelockPlus.enable();
    if (!mounted) {
      // Left the screen while starting. [dispose] may already have run, before
      // the lock was on, so put it back here, to what it was before.
      _wakelockTaken = false;
      if (!_hadWakelock) WakelockPlus.disable();
      return;
    }
    setState(() {
      _walking = true;
      _note = 'Waiting for the first GPS fix…';
    });
  }

  void _stopWalking() {
    if (!_walking) return;
    _releaseWakelock();
    setState(() => _walking = false);
  }

  /// Turns the screen lock back to what it was before walking. Safe to call
  /// when not walking, and from [dispose].
  void _releaseWakelock() {
    if (!_wakelockTaken) return;
    _wakelockTaken = false;
    if (!_hadWakelock) WakelockPlus.disable();
  }

  /// A fix arrived while walking (from the tracker during a visit, or from our
  /// own stream). Keeps it as a corner when it is accurate and far enough from
  /// the last corner.
  void _onFix(Position position) {
    if (!_walking || _closed) return;
    final here = LatLng(position.latitude, position.longitude);
    if (position.accuracy > _maxWalkAccuracyM) {
      setState(() {
        _here = here;
        _note = 'Waiting for better GPS, ± ${position.accuracy.round()} m';
      });
      return;
    }
    final far =
        _points.isEmpty ||
        _distance.as(LengthUnit.Meter, _points.last, here) >= _walkSpacingM;
    setState(() {
      _here = here;
      _note = null;
      if (far) _points.add(here);
    });
    if (_points.length == 1 && far && !_userMovedMap) {
      _mapController.move(
        here,
        _mapController.camera.zoom.clamp(18.0, 20.0).toDouble(),
      );
    }
    if (far) _publish();
  }

  void _onWalkError(Object error) {
    if (!mounted) return;
    setState(() {
      _note = error is LocationException
          ? locationMessage(error.failure)
          : 'GPS problem: $error';
    });
  }

  // --- Undo, clear, close ------------------------------------------------------

  /// Takes back the last corner; after Close it reopens the polygon instead.
  void _undo() {
    setState(() {
      if (_closed) {
        _closed = false;
      } else if (_points.isNotEmpty) {
        _points.removeLast();
      }
    });
    _publish();
  }

  void _clear() {
    setState(() {
      _points.clear();
      _closed = false;
    });
    _publish();
  }

  void _close() {
    _stopWalking();
    setState(() => _closed = true);
    _publish();
  }

  // --- Camera ------------------------------------------------------------------

  /// Where the camera starts: on the shape being edited, else on the visit
  /// tracker's newest fix, else on the reference lines, else on Serbia. It is
  /// given to the map as its starting camera. It is not moved from code after
  /// the first frame: a camera move made in `onMapReady` left the tiles of the
  /// new place unrequested until the user touched the map (found on the phone,
  /// T052).
  void _chooseStartCamera() {
    final tracker = ref.read(trackingControllerProvider).lastPosition;
    final lines = [for (final line in widget.referenceLines) ...line];
    if (_points.length == 1) {
      _startCenter = _points.first;
      _startZoom = 18;
    } else if (_points.length > 1) {
      _startFit = _fitFor(_points);
    } else if (tracker != null) {
      _startCenter = LatLng(tracker.latitude, tracker.longitude);
      _startZoom = 18;
    } else if (lines.length > 1) {
      _startFit = _fitFor(lines);
    } else {
      _needsLastKnown = true;
    }
  }

  CameraFit _fitFor(List<LatLng> places) => CameraFit.coordinates(
    coordinates: places,
    padding: const EdgeInsets.all(48),
    maxZoom: 19,
  );

  /// With nothing to start from, waits for the phone's last known position and
  /// moves the map there, unless the user has already moved it or drawn.
  Future<void> _moveToLastKnown() async {
    if (!_needsLastKnown) return;
    final last = await ref.read(lastKnownPositionProvider.future);
    if (last == null || !mounted || _userMovedMap || _points.isNotEmpty) return;
    _mapController.move(LatLng(last.latitude, last.longitude), 18);
  }

  // --- Reading the state for the screen -----------------------------------------

  /// How wide the drawing is, diagonally, in metres.
  double _extentM() {
    var minLat = _points.first.latitude;
    var maxLat = minLat;
    var minLon = _points.first.longitude;
    var maxLon = minLon;
    for (final p in _points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return _distance.as(
      LengthUnit.Meter,
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Whether the visit tracker owns the GPS, and how often it reports.
    final tracker = ref.watch(
      trackingControllerProvider.select(
        (t) => (running: t.recording && !t.paused, intervalS: t.intervalS),
      ),
    );

    // Only while walking, and from only one source: geolocator keeps one
    // stream for the app, so during a visit the tracker's fixes are used and
    // our own stream is never started (D-087). Not listening lets the provider
    // dispose, which releases the GPS.
    if (_walking) {
      if (tracker.running) {
        ref.listen(trackingControllerProvider.select((t) => t.lastPosition), (
          _,
          position,
        ) {
          if (position != null) _onFix(position);
        });
      } else {
        ref.listen(walkPositionsProvider, (_, next) {
          final position = next.value;
          if (position != null) _onFix(position);
          if (next.hasError) _onWalkError(next.error!);
        });
      }
    }

    final crossing =
        _isPolygon &&
        !_closed &&
        _points.length >= 3 &&
        (chainSelfIntersects(_points) ||
            (polygonAreaM2(_points) >= 0.01 && polygonSelfIntersects(_points)));
    final canClose =
        _isPolygon &&
        !_closed &&
        _points.length >= 3 &&
        !polygonSelfIntersects(_points);
    final tooFlat =
        _isPolygon && !_closed && _points.length >= 3 && !crossing && !canClose;
    final coarse =
        _method == _Method.polygonWalk &&
        _points.length >= 3 &&
        _extentM() < _coarseBelowM;

    return Column(
      // Stretch, so the map and the selector use the full width; the texts and
      // buttons under the map are centred on their own below.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selector(),
        Expanded(child: _map(scheme, crossing)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _summary(),
              if (_method == _Method.polygonWalk && !_closed)
                _message(
                  tracker.running
                      ? 'A fix every ${tracker.intervalS ?? '?'} s during a '
                            'visit. Walk slowly, or use tap for small patches.'
                      : 'Walk along the edge of the patch. A corner is kept '
                            'about every 2 m.',
                  scheme.onSurfaceVariant,
                ),
              if (_note != null) _message(_note!, scheme.error),
              if (crossing)
                _message(
                  'The edges cross. Undo the last points or start again.',
                  scheme.error,
                ),
              if (tooFlat)
                _message(
                  'The corners are on one line. Add a corner to the side.',
                  scheme.error,
                ),
              if (coarse)
                _message(
                  'This patch is only about ${_extentM().round()} m across, '
                  'which is too small for GPS. Tap mode gives a better shape.',
                  scheme.onSurfaceVariant,
                ),
              const SizedBox(height: 8),
              _buttons(canClose),
            ],
          ),
        ),
      ],
    );
  }

  /// The method selector across the top.
  Widget _selector() {
    final methods = _methods;
    if (methods.length < 2) return const SizedBox.shrink();
    String label(_Method m) => switch (m) {
      _Method.point => 'Point',
      _Method.polygonTap => 'Polygon (tap)',
      _Method.polygonWalk => 'Polygon (walk)',
      _Method.line => 'Line',
    };
    // No scrolling: the segments share the full width equally, and a label that
    // is too long for its segment shrinks (FittedBox) instead of overflowing.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SegmentedButton<_Method>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
        ),
        segments: [
          for (final m in methods)
            ButtonSegment(
              value: m,
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label(m), maxLines: 1),
              ),
            ),
        ],
        selected: {_method},
        onSelectionChanged: (selected) => _selectMethod(selected.first),
      ),
    );
  }

  /// The map with the guide lines, the drawing, the corners and the pin.
  Widget _map(ColorScheme scheme, bool crossing) {
    final drawColor = crossing ? scheme.error : Colors.green.shade700;
    return FlutterMap(
      key: _mapKey,
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _startCenter,
        initialZoom: _startZoom,
        initialCameraFit: _startFit,
        onMapReady: _moveToLastKnown,
        onTap: (_, place) => _onMapTap(place),
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) _userMovedMap = true;
        },
        // No rotation: north stays up. All gestures are off while the pin is
        // dragged, or the map would pan under the finger.
        interactionOptions: InteractionOptions(
          flags: _dragging
              ? InteractiveFlag.none
              : InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'rs.amilojkovic.butterfly',
        ),
        PolylineLayer(
          polylines: [
            for (final line in widget.referenceLines)
              // flutter_map asserts on a line with fewer than 2 points.
              if (line.length >= 2)
                Polyline(
                  points: line,
                  strokeWidth: 3,
                  color: Colors.grey.shade700,
                  pattern: StrokePattern.dashed(segments: const [8, 6]),
                ),
            if (_method == _Method.line && _points.length >= 2)
              Polyline(points: _points, strokeWidth: 4, color: drawColor),
            if (_isPolygon && _points.length == 2)
              Polyline(points: _points, strokeWidth: 4, color: drawColor),
          ],
        ),
        PolygonLayer(
          polygons: [
            // flutter_map asserts on a polygon with fewer than 3 points. Before
            // Close it is a preview, with the closing edge drawn too.
            if (_isPolygon && _points.length >= 3)
              Polygon(
                points: _points,
                color: drawColor.withValues(alpha: _closed ? 0.3 : 0.15),
                borderColor: drawColor,
                borderStrokeWidth: 3,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (_here != null)
              Marker(
                point: _here!,
                width: 18,
                height: 18,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            if (_method != _Method.point)
              for (var i = 0; i < _points.length; i++)
                Marker(
                  point: _points[i],
                  width: i == 0 ? 18 : 12,
                  height: i == 0 ? 18 : 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: i == 0 ? Colors.white : drawColor,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: drawColor, width: i == 0 ? 3 : 1),
                      ),
                    ),
                  ),
                ),
            if (_method == _Method.point && _points.isNotEmpty)
              Marker(
                point: _points.first,
                width: 56,
                height: 56,
                // The tip of the pin is at the bottom of the icon, so the
                // marker sits above the point.
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (_) => setState(() => _dragging = true),
                  onPanUpdate: _dragPin,
                  onPanEnd: (_) => _endDrag(),
                  onPanCancel: _endDrag,
                  child: const Icon(
                    Icons.location_on,
                    size: 56,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }

  /// The size of what is drawn: coordinates, corners and area, or length.
  Widget _summary() {
    final style = Theme.of(context).textTheme.titleSmall;
    final text = switch (_method) {
      _Method.point =>
        _points.isEmpty
            ? 'Tap the map to place the point'
            : 'Point ${_points.first.latitude.toStringAsFixed(5)}, '
                  '${_points.first.longitude.toStringAsFixed(5)}',
      _Method.line =>
        _points.length < 2
            ? 'Tap the map to add points (${_points.length} so far)'
            : '${_points.length} points · ${formatLength(lineLengthM(_points))}',
      _Method.polygonTap || _Method.polygonWalk =>
        _points.length < 3
            ? '${_points.length} corners so far. A polygon needs 3.'
            : '${_points.length} corners · '
                  '${formatArea(polygonAreaM2(_points))}'
                  '${_closed ? ' · closed' : ''}',
    };
    return Text(text, style: style, textAlign: TextAlign.center);
  }

  Widget _message(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// The buttons under the map for the current method.
  Widget _buttons(bool canClose) {
    final hasShape = _points.isNotEmpty || _closed;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_method == _Method.point)
          FilledButton.icon(
            onPressed: _locating ? null : _useMyPosition,
            icon: const Icon(Icons.my_location),
            label: const Text('Use my position'),
          ),
        if (_method == _Method.polygonWalk && !_closed)
          _walking
              ? FilledButton.tonalIcon(
                  onPressed: _stopWalking,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop walking'),
                )
              : FilledButton.tonalIcon(
                  onPressed: _startWalking,
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Start walking'),
                ),
        if (_method != _Method.point) ...[
          OutlinedButton(
            onPressed: hasShape ? _undo : null,
            child: const Text('Undo'),
          ),
          OutlinedButton(
            onPressed: hasShape ? _clear : null,
            child: const Text('Clear'),
          ),
        ],
        if (_isPolygon)
          FilledButton(
            onPressed: canClose ? _close : null,
            child: const Text('Close'),
          ),
        if (_locating || (_walking && _points.isEmpty))
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}
