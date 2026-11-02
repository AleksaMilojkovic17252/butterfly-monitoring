import 'dart:math' as math;

/// The compass direction of a point on the dial, in whole degrees clockwise
/// from north (0 to 359). [dx] and [dy] are the offset from the dial's centre
/// in screen pixels, so up is a negative [dy].
int degreesFromOffset(double dx, double dy) {
  final degrees = math.atan2(dx, -dy) * 180 / math.pi;
  // Rounding 359.6 gives 360, which the server refuses; the modulo turns it
  // into 0. Dart's `%` is never negative, so -90 (west) becomes 270.
  return degrees.round() % 360;
}

const _points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

/// The direction as the screens show it: "NE · 45°".
String flightDirectionLabel(int degrees) {
  final point = _points[((degrees + 22.5) ~/ 45) % 8];
  return '$point · $degrees°';
}
