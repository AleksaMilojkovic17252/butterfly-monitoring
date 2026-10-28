import 'package:flutter/services.dart';

/// Allows a temperature like "-3", "17" or "17,5": an optional minus, up to
/// two digits and one decimal. Any other edit is ignored. Shared by the start
/// form (T035) and the Finish screen (T040).
final temperatureFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) =>
      RegExp(r'^-?\d{0,2}([.,]\d?)?$').hasMatch(newValue.text)
      ? newValue
      : oldValue,
);

/// The temperature in [text] with one decimal, or null when empty or not a
/// number. A comma counts as the decimal point.
double? parseTemperature(String text) {
  final value = double.tryParse(text.replaceAll(',', '.'));
  if (value == null) return null;
  return (value * 10).round() / 10;
}
