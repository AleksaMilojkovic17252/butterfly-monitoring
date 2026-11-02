import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/location/compass_heading.dart';
import 'package:mobile/features/observations/domain/flight_direction.dart';

/// A compass dial for the flight direction (T046): a circle with N, E, S, W and
/// a needle. Tapping or dragging calls [onChanged] with whole degrees clockwise
/// from north (0 to 359). [degrees] null draws no needle.
///
/// [facingDeg] is the way the user faces. It is drawn as a thinner line under
/// the needle, with an arrow, so a butterfly flying away from the user is not
/// marked as north by mistake: it flies along that line. Null draws nothing.
class FlightDirectionDial extends StatelessWidget {
  const FlightDirectionDial({
    super.key,
    required this.degrees,
    required this.onChanged,
    this.facingDeg,
    this.size = 220,
  });
  final int? degrees;
  final ValueChanged<int> onChanged;
  final int? facingDeg;
  final double size;

  /// Turns a touch at [position] into degrees from the dial's centre. A touch
  /// in the middle has no direction, so it is ignored.
  void _touch(Offset position) {
    final centre = Offset(size / 2, size / 2);
    final offset = position - centre;
    if (offset.distance < size * 0.1) return;
    onChanged(degreesFromOffset(offset.dx, offset.dy));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (details) => _touch(details.localPosition),
      onPanUpdate: (details) => _touch(details.localPosition),
      child: CustomPaint(
        size: Size(size, size),
        painter: _DialPainter(
          degrees: degrees,
          facingDeg: facingDeg,
          lineColor: scheme.outline,
          needleColor: scheme.primary,
          facingColor: scheme.tertiary,
          textColor: scheme.onSurface,
        ),
      ),
    );
  }
}

/// Draws the dial: the circle, the four letters and the needle.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.degrees,
    required this.facingDeg,
    required this.lineColor,
    required this.needleColor,
    required this.facingColor,
    required this.textColor,
  });
  final int? degrees;
  final int? facingDeg;
  final Color lineColor;
  final Color needleColor;
  final Color facingColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // The letters sit just inside the circle: N up, E right, S down, W left.
    const letters = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < letters.length; i++) {
      final angle = i * math.pi / 2;
      final painter = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final spot =
          centre + Offset(math.sin(angle), -math.cos(angle)) * (radius - 18);
      painter.paint(
        canvas,
        spot - Offset(painter.width / 2, painter.height / 2),
      );
    }

    // The facing line first, so the needle is drawn over it.
    final facing = facingDeg;
    if (facing != null) _paintFacing(canvas, centre, radius, facing);

    final value = degrees;
    if (value == null) return;
    final angle = value * math.pi / 180;
    final tip =
        centre + Offset(math.sin(angle), -math.cos(angle)) * (radius - 36);
    final needle = Paint()
      ..color = needleColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(centre, tip, needle);
    canvas.drawCircle(tip, 7, needle);
    canvas.drawCircle(centre, 5, needle);
  }

  /// A thin line from the centre to the edge in the way the user faces, with
  /// an arrow head at the edge.
  void _paintFacing(Canvas canvas, Offset centre, double radius, int facing) {
    final angle = facing * math.pi / 180;
    final direction = Offset(math.sin(angle), -math.cos(angle));
    final tip = centre + direction * (radius - 4);
    final paint = Paint()
      ..color = facingColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(centre, tip, paint);

    // The arrow head: two short strokes back from the tip, 25 degrees apart
    // from the line.
    for (final side in [-1, 1]) {
      final back = angle + math.pi + side * 25 * math.pi / 180;
      final end = tip + Offset(math.sin(back), -math.cos(back)) * 14;
      canvas.drawLine(tip, end, paint);
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.degrees != degrees ||
      old.facingDeg != facingDeg ||
      old.lineColor != lineColor ||
      old.needleColor != needleColor ||
      old.facingColor != facingColor ||
      old.textColor != textColor;
}

/// Opens the dial in a dialog with Cancel, Clear and OK. Returns null when
/// cancelled, `(degrees: null)` when cleared, or the chosen degrees.
///
/// With [showFacing] the dial also draws the way the user faces, from the
/// phone's compass (`compassHeadingProvider`). Use it only when the user is
/// at the observation, not when editing one later.
///
/// It is a dialog on purpose: inside the form's scrolling list a vertical drag
/// on the dial would be taken by the scroll.
Future<({int? degrees})?> showFlightDirectionDialog(
  BuildContext context,
  int? initial, {
  bool showFacing = false,
}) {
  return showDialog<({int? degrees})>(
    context: context,
    builder: (context) =>
        _FlightDirectionDialog(initial: initial, showFacing: showFacing),
  );
}

class _FlightDirectionDialog extends ConsumerStatefulWidget {
  const _FlightDirectionDialog({
    required this.initial,
    required this.showFacing,
  });
  final int? initial;
  final bool showFacing;

  @override
  ConsumerState<_FlightDirectionDialog> createState() =>
      _FlightDirectionDialogState();
}

class _FlightDirectionDialogState
    extends ConsumerState<_FlightDirectionDialog> {
  late int? _degrees = widget.initial;

  @override
  Widget build(BuildContext context) {
    final degrees = _degrees;
    // Watched only when asked for, so the sensor is not started otherwise.
    final facing = widget.showFacing
        ? ref.watch(compassHeadingProvider).value
        : null;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Flight direction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlightDirectionDial(
            degrees: degrees,
            facingDeg: facing,
            onChanged: (value) => setState(() => _degrees = value),
          ),
          const SizedBox(height: 12),
          Text(
            degrees == null
                ? 'Tap or drag the dial'
                : flightDirectionLabel(degrees),
            style: textTheme.titleMedium,
          ),
          if (widget.showFacing) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 3,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  facing == null
                      ? 'You face: no compass reading'
                      : 'You face ${flightDirectionLabel(facing)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              'A butterfly flying away from you flies along this line.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (degrees: null)),
          child: const Text('Clear'),
        ),
        TextButton(
          // Without a touch, OK keeps the direction the dial opened with.
          onPressed: () => Navigator.pop(context, (degrees: degrees)),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
