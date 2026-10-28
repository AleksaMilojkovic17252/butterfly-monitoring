import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/core/validation/visit_values.dart';
import 'package:mobile/core/validation/weather_check.dart';

// Input rules of a visit (T055): V05, V06 and V07 block a save, W06 and W07
// only warn. The rules are in docs/requirements/validation-rules.md; the
// server repeats them in `backend/apps/surveys/rules.py` and is the one that
// decides. The Finish screen (T040/T041) calls [validateVisit] and
// [visitWarnings] before it completes a visit.

/// The values of a visit that the rules read.
class VisitInput {
  const VisitInput({
    required this.status,
    required this.startedAt,
    this.temperatureStartC,
    this.temperatureEndC,
    this.windBeaufortStart,
    this.windBeaufortEnd,
    this.cloudCoverStartPct,
    this.cloudCoverEndPct,
    this.precipitation = 'none',
    this.weatherMissingReason = '',
    this.zeroObservationConfirmed = false,
  });

  /// The values of a visit row.
  factory VisitInput.fromVisit(SurveyVisit visit) => VisitInput(
    status: visit.status,
    startedAt: visit.startedAt,
    temperatureStartC: visit.temperatureStartC,
    temperatureEndC: visit.temperatureEndC,
    windBeaufortStart: visit.windBeaufortStart,
    windBeaufortEnd: visit.windBeaufortEnd,
    cloudCoverStartPct: visit.cloudCoverStartPct,
    cloudCoverEndPct: visit.cloudCoverEndPct,
    precipitation: visit.precipitation,
    weatherMissingReason: visit.weatherMissingReason,
    zeroObservationConfirmed: visit.zeroObservationConfirmed,
  );

  final String status;
  final DateTime? startedAt;
  final double? temperatureStartC;
  final double? temperatureEndC;
  final int? windBeaufortStart;
  final int? windBeaufortEnd;
  final int? cloudCoverStartPct;
  final int? cloudCoverEndPct;
  final String precipitation;
  final String weatherMissingReason;
  final bool zeroObservationConfirmed;
}

/// What the rules need to know besides the visit: the protocol and how many
/// live transect observations the visit has on this phone.
class VisitRuleContext {
  const VisitRuleContext({
    required this.protocol,
    required this.transectObservationCount,
  });
  final ProjectProtocol protocol;
  final int transectObservationCount;
}

/// Statuses in which the visit's weather must be complete (V05).
const _weatherRequiredStatuses = ['completed', 'synced', 'reviewed', 'locked'];

/// The hard errors of [input] as field to rule IDs (the server's field
/// names); an empty map means valid.
Map<String, List<String>> validateVisit(
  VisitInput input,
  VisitRuleContext context,
) {
  final errors = <String, List<String>>{};
  _v05Weather(input, errors);
  _v06Visit(input, context, errors);
  _v07Choices(input, errors);
  return errors;
}

/// The warnings that apply to [input], as rule IDs (W06, W07). They never
/// block a save.
List<String> visitWarnings(VisitInput input, VisitRuleContext context) {
  return [
    if (_w06Weather(input, context.protocol)) 'W06',
    if (_w07OutsideWindow(input, context.protocol)) 'W07',
  ];
}

void _add(Map<String, List<String>> errors, String field, String ruleId) {
  errors.putIfAbsent(field, () => []).add(ruleId);
}

void _v05Weather(VisitInput input, Map<String, List<String>> errors) {
  // V05
  if (!_weatherRequiredStatuses.contains(input.status)) return;
  if (input.weatherMissingReason.trim().isNotEmpty) return;
  final values = {
    'temperature_start_c': input.temperatureStartC,
    'temperature_end_c': input.temperatureEndC,
    'wind_beaufort_start': input.windBeaufortStart,
    'wind_beaufort_end': input.windBeaufortEnd,
    'cloud_cover_start_pct': input.cloudCoverStartPct,
    'cloud_cover_end_pct': input.cloudCoverEndPct,
  };
  for (final entry in values.entries) {
    if (entry.value == null) _add(errors, entry.key, 'V05');
  }
}

void _v06Visit(
  VisitInput input,
  VisitRuleContext context,
  Map<String, List<String>> errors,
) {
  // V06, both directions. The server checks only the first one (a visit
  // finished offline reaches it before its observations, D-051).
  final count = context.transectObservationCount;
  if (input.zeroObservationConfirmed && count > 0) {
    _add(errors, 'zero_observation_confirmed', 'V06');
  }
  if (input.status == 'completed' &&
      count == 0 &&
      !input.zeroObservationConfirmed) {
    _add(errors, 'zero_observation_confirmed', 'V06');
  }
}

void _v07Choices(VisitInput input, Map<String, List<String>> errors) {
  // V07
  if (!visitStatuses.contains(input.status)) _add(errors, 'status', 'V07');
  if (!precipitationValues.contains(input.precipitation)) {
    _add(errors, 'precipitation', 'V07');
  }
}

bool _w06Weather(VisitInput input, ProjectProtocol protocol) {
  // W06: the start weather, and the end weather when it is recorded.
  return _weatherFails(
        protocol,
        input.temperatureStartC,
        input.windBeaufortStart,
        input.cloudCoverStartPct,
        input.precipitation,
      ) ||
      _weatherFails(
        protocol,
        input.temperatureEndC,
        input.windBeaufortEnd,
        input.cloudCoverEndPct,
        input.precipitation,
      );
}

/// True when one set of weather values is outside the protocol. A set with a
/// missing value is not checked.
bool _weatherFails(
  ProjectProtocol protocol,
  double? temperatureC,
  int? windBeaufort,
  int? cloudCoverPct,
  String precipitation,
) {
  if (temperatureC == null || windBeaufort == null || cloudCoverPct == null) {
    return false;
  }
  return failedWeatherThresholds(
    protocol: protocol,
    temperatureC: temperatureC,
    windBeaufort: windBeaufort,
    cloudCoverPct: cloudCoverPct,
    precipitation: precipitation,
  ).isNotEmpty;
}

bool _w07OutsideWindow(VisitInput input, ProjectProtocol protocol) {
  // W07: outside the season, or outside the daily window (phone's time zone).
  final startedAt = input.startedAt;
  if (startedAt == null) return false;
  return seasonWarning(protocol, startedAt) != null ||
      timeWindowWarning(protocol, startedAt) != null;
}
