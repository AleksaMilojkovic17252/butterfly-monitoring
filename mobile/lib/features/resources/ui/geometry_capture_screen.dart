import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/ui/widgets/geometry_capture_widget.dart';

/// Opens the geometry capture as its own full-screen page and returns the shape
/// the user finished with Done, or null when the user goes back (T052).
///
/// A page of its own, not a bottom sheet: a drag on a map inside a sheet or a
/// list loses the gesture to the scrolling (the same reason the flight
/// direction dial is a dialog, D-082). T054 uses it for habitat features too,
/// with a line in [modes].
Future<CapturedGeometry?> showGeometryCapture(
  BuildContext context, {
  required Set<GeometryMode> modes,
  CapturedGeometry? initial,
  List<List<LatLng>> referenceLines = const [],
}) {
  return Navigator.of(context).push<CapturedGeometry>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _GeometryCaptureScreen(
        modes: modes,
        initial: initial,
        referenceLines: referenceLines,
      ),
    ),
  );
}

/// The page around [GeometryCaptureWidget]: a back arrow (leaves without
/// saving) and a save icon in the app bar. Save stays disabled until the shape
/// is finished and valid.
class _GeometryCaptureScreen extends StatefulWidget {
  const _GeometryCaptureScreen({
    required this.modes,
    required this.initial,
    required this.referenceLines,
  });
  final Set<GeometryMode> modes;
  final CapturedGeometry? initial;
  final List<List<LatLng>> referenceLines;

  @override
  State<_GeometryCaptureScreen> createState() => _GeometryCaptureScreenState();
}

class _GeometryCaptureScreenState extends State<_GeometryCaptureScreen> {
  /// The finished shape, or null. It starts as the shape being edited.
  late CapturedGeometry? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The back arrow, not the close cross a full-screen page would get.
        leading: const BackButton(),
        title: const Text('Location'),
        actions: [
          // Done: hands the finished shape back. Disabled until it is valid.
          IconButton(
            tooltip: 'Save location',
            icon: const Icon(Icons.check),
            onPressed: _value == null
                ? null
                : () => Navigator.pop(context, _value),
          ),
        ],
      ),
      body: SafeArea(
        child: GeometryCaptureWidget(
          modes: widget.modes,
          initial: widget.initial,
          referenceLines: widget.referenceLines,
          onChanged: (shape) => setState(() => _value = shape),
        ),
      ),
    );
  }
}
