import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The way the top of the phone points, in whole degrees clockwise from north
/// (0 to 359), live from the magnetometer. Null while there is no reading (no
/// sensor, or it has not reported yet). It only emits when the whole-degree
/// value changes, so a listener is not rebuilt for sensor noise.
///
/// Used by the flight direction dial (T046) to show which way the user faces.
/// `autoDispose`: the sensor stops when nobody listens (the dial is closed).
final compassHeadingProvider = StreamProvider.autoDispose<int?>((ref) {
  final events = FlutterCompass.events;
  if (events == null) return Stream.value(null);
  return events.map((event) {
    final heading = event.heading;
    // The plugin reports -180 to 180 on some phones; `%` is never negative.
    return heading == null ? null : heading.round() % 360;
  }).distinct();
});
