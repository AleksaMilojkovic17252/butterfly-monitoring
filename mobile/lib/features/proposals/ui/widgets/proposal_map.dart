import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/features/map/data/mbtiles_provider.dart';
import 'package:mobile/features/map/ui/widgets/basemap_layers.dart';

/// A transect drawn behind the recorded line on the record screen.
class ProposalMapTransect {
  const ProposalMapTransect({required this.line, this.replaced = false});

  /// The transect line.
  final List<LatLng> line;

  /// True for the transect the route would replace: drawn dashed.
  final bool replaced;
}

/// The map of the record screen (T108): the project's transects as thin grey
/// lines (the replaced one dashed), the route recorded so far, and the
/// current position. Same tile layer as `TransectMap`.
///
/// `TransectMap` fits only its own line and sections, so this map is separate.
/// The camera starts on the transects, or on the position, and fits the
/// recorded line once the first time it has two points. After that the user
/// moves the map.
class ProposalMap extends ConsumerStatefulWidget {
  const ProposalMap({
    super.key,
    required this.projectId,
    required this.transects,
    required this.line,
    this.position,
    this.accuracyM,
  });

  /// The project being walked; its offline basemap is drawn (T060).
  final String projectId;

  final List<ProposalMapTransect> transects;

  /// The recorded line in walking order. Drawn from two points on:
  /// flutter_map asserts on a line with fewer.
  final List<LatLng> line;

  /// The newest fix, or null before the first one.
  final LatLng? position;
  final double? accuracyM;

  @override
  ConsumerState<ProposalMap> createState() => _ProposalMapState();
}

class _ProposalMapState extends ConsumerState<ProposalMap> {
  final _controller = MapController();

  /// True once the camera has been fitted to the recorded line.
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    // A line that is already long enough (the screen opened on a recording in
    // progress) is fitted by the starting camera.
    _fitted = widget.line.length >= 2;
  }

  @override
  void didUpdateWidget(ProposalMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_fitted && widget.line.length >= 2) {
      _fitted = true;
      _controller.fitCamera(_fit(widget.line));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CameraFit _fit(List<LatLng> points) => CameraFit.coordinates(
    coordinates: points,
    padding: const EdgeInsets.all(40),
    maxZoom: 19,
  );

  @override
  Widget build(BuildContext context) {
    final transectPoints = [
      for (final t in widget.transects)
        if (t.line.length >= 2) ...t.line,
    ];
    final here = widget.position;

    // Where the camera starts: the recorded line, else the transects, else the
    // position, else Serbia.
    MapOptions options() {
      const interaction = InteractionOptions(
        // No rotation: north stays up, which is easier to read in the field.
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      );
      if (widget.line.length >= 2) {
        return MapOptions(
          initialCameraFit: _fit(widget.line),
          interactionOptions: interaction,
        );
      }
      if (transectPoints.length >= 2) {
        return MapOptions(
          initialCameraFit: _fit(transectPoints),
          interactionOptions: interaction,
        );
      }
      return MapOptions(
        initialCenter: here ?? const LatLng(44.0, 21.0),
        initialZoom: here == null ? 7 : 17,
        interactionOptions: interaction,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return FlutterMap(
      mapController: _controller,
      options: options(),
      children: [
        ...basemapLayers(ref.watch(mbtilesProvider(widget.projectId)).value),
        PolylineLayer(
          polylines: [
            for (final t in widget.transects)
              if (t.line.length >= 2)
                Polyline(
                  points: t.line,
                  strokeWidth: t.replaced ? 4 : 2,
                  color: t.replaced
                      ? Colors.grey.shade700
                      : Colors.grey.withValues(alpha: 0.7),
                  pattern: t.replaced
                      ? StrokePattern.dashed(segments: const [10, 8])
                      : const StrokePattern.solid(),
                ),
            if (widget.line.length >= 2)
              Polyline(
                points: widget.line,
                strokeWidth: 5,
                color: scheme.primary,
                borderStrokeWidth: 1.5,
                borderColor: Colors.white,
              ),
          ],
        ),
        if (here != null) ...[
          CircleLayer(
            circles: [
              CircleMarker(
                point: here,
                radius: widget.accuracyM ?? 0,
                useRadiusInMeter: true,
                color: scheme.primary.withValues(alpha: 0.15),
                borderColor: scheme.primary,
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
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
