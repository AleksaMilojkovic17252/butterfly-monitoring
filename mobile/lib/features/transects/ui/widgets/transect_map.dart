import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Colours of the sections, by walking order. Neighbouring sections always
/// differ; after eight the colours repeat.
const _sectionColors = [
  Color(0xFFE6194B), // red
  Color(0xFF3CB44B), // green
  Color(0xFF4363D8), // blue
  Color(0xFFF58231), // orange
  Color(0xFF911EB4), // purple
  Color(0xFF42D4F4), // cyan
  Color(0xFFF032E6), // magenta
  Color(0xFF9A6324), // brown
];

/// Colour of the section at [index] in walking order. The section list uses
/// the same colour for its dot, so the two can be matched.
Color sectionColor(int index) => _sectionColors[index % _sectionColors.length];

/// A map of one transect: the whole line as a wide grey band, and each section
/// on top of it in its own colour. Opens zoomed to fit the line.
///
/// The basemap is OpenStreetMap tiles, which need a connection. flutter_map
/// keeps the tiles it has shown in a cache, so an area seen online usually
/// still shows offline; otherwise the lines are drawn on a plain background.
///
/// The active visit screen (T039) also passes [currentSection], drawn wider
/// than the others, and [overlays] (the walked route and the position), drawn
/// on top of the sections.
class TransectMap extends StatelessWidget {
  const TransectMap({
    super.key,
    required this.line,
    required this.sections,
    this.currentSection,
    this.overlays = const [],
  });

  /// The transect line.
  final List<LatLng> line;

  /// The section lines, in walking order.
  final List<List<LatLng>> sections;

  /// Index in [sections] of the section the observer is in, or null.
  final int? currentSection;

  /// More map layers, drawn above the sections and below the attribution.
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    final points = [...line, for (final s in sections) ...s];
    if (points.isEmpty) {
      return const Center(child: Text('No route on this phone'));
    }
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(24),
          maxZoom: 18,
        ),
        // No rotation: north stays up, which is easier to read in the field.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OSM's tile policy asks every app to identify itself.
          userAgentPackageName: 'rs.amilojkovic.butterfly',
        ),
        PolylineLayer(
          // flutter_map cannot draw a line without points (it asserts), and
          // the transect or a section can still be loading.
          polylines: [
            if (line.isNotEmpty)
              Polyline(
                points: line,
                strokeWidth: 10,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            for (var i = 0; i < sections.length; i++)
              if (sections[i].isNotEmpty)
                Polyline(
                  points: sections[i],
                  strokeWidth: i == currentSection ? 9 : 4,
                  color: sectionColor(i),
                  borderStrokeWidth: i == currentSection ? 2 : 0,
                  borderColor: Colors.white,
                ),
          ],
        ),
        ...overlays,
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
