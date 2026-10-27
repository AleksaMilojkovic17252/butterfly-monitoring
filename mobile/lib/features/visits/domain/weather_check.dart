import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/visits/domain/beaufort.dart';

// Weather suitability against the project protocol (protocol.md §3, T035).
// Suitable = no precipitation (unless the protocol allows it), wind ≤ max,
// and either temperature ≥ `sunnyTemperatureC`, or temperature ≥
// `minTemperatureC` with cloud ≤ `maxCloudCoverPctIfCool`.

/// The thresholds the given weather fails, as sentences for the form. An
/// empty list means the weather is suitable. Every value must be set; the form
/// checks only once all of them are.
List<String> failedWeatherThresholds({
  required ProjectProtocol protocol,
  required double temperatureC,
  required int windBeaufort,
  required int cloudCoverPct,
  required String precipitation,
}) {
  final p = protocol;
  final failed = <String>[];

  if (precipitation != 'none' && !p.allowPrecipitation) {
    failed.add(
      '${precipitationLabel(precipitation)}: the protocol needs no rain',
    );
  }
  if (windBeaufort > p.maxWindBeaufort) {
    failed.add('Wind $windBeaufort Bft is above ${p.maxWindBeaufort} Bft');
  }

  // Warm enough for any cloud: nothing more to check.
  if (temperatureC >= p.sunnyTemperatureC) return failed;

  if (temperatureC < p.minTemperatureC) {
    failed.add(
      'Temperature ${_number(temperatureC)} °C is below '
      '${_number(p.minTemperatureC)} °C',
    );
  } else if (cloudCoverPct > p.maxCloudCoverPctIfCool) {
    failed.add(
      'Cloud $cloudCoverPct % is above ${p.maxCloudCoverPctIfCool} % '
      'at under ${_number(p.sunnyTemperatureC)} °C',
    );
  }
  return failed;
}

/// 13.0 → "13", 13.5 → "13.5"
String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
