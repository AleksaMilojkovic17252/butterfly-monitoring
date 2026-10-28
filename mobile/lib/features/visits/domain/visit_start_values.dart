import 'package:mobile/core/db/app_database.dart';

/// What the start-visit form (T035) edits: the conditions at the start of the
/// walk. A draft may leave the weather empty; Start needs all of it.
class VisitStartValues {
  const VisitStartValues({
    required this.observerCount,
    required this.observerNames,
    required this.temperatureC,
    required this.windBeaufort,
    required this.cloudCoverPct,
    required this.precipitation,
    required this.notes,
    required this.weatherSuitable,
  });

  /// The values of a saved draft, so the form can carry on with it.
  factory VisitStartValues.fromVisit(SurveyVisit visit) => VisitStartValues(
    observerCount: visit.observerCount,
    observerNames: visit.observerNames,
    temperatureC: visit.temperatureStartC,
    windBeaufort: visit.windBeaufortStart,
    cloudCoverPct: visit.cloudCoverStartPct,
    precipitation: visit.precipitation,
    notes: visit.notes,
    weatherSuitable: visit.weatherSuitable,
  );

  final int observerCount;
  final String observerNames;
  final double? temperatureC;
  final int? windBeaufort;
  final int? cloudCoverPct;
  final String precipitation;
  final String notes;

  /// True or false once the weather has been checked against the protocol,
  /// null while some of it is missing.
  final bool? weatherSuitable;

  /// These values with the given fields replaced. A null argument keeps the
  /// current value, so it cannot clear a weather value.
  VisitStartValues copyWith({
    int? observerCount,
    String? observerNames,
    double? temperatureC,
    int? windBeaufort,
    int? cloudCoverPct,
    String? precipitation,
    String? notes,
    bool? weatherSuitable,
  }) => VisitStartValues(
    observerCount: observerCount ?? this.observerCount,
    observerNames: observerNames ?? this.observerNames,
    temperatureC: temperatureC ?? this.temperatureC,
    windBeaufort: windBeaufort ?? this.windBeaufort,
    cloudCoverPct: cloudCoverPct ?? this.cloudCoverPct,
    precipitation: precipitation ?? this.precipitation,
    notes: notes ?? this.notes,
    weatherSuitable: weatherSuitable ?? this.weatherSuitable,
  );

  /// The same values with the server's field names, as a push payload holds
  /// them.
  Map<String, Object?> toPayload() => {
    'observer_count': observerCount,
    'observer_names': observerNames,
    'temperature_start_c': temperatureC,
    'wind_beaufort_start': windBeaufort,
    'cloud_cover_start_pct': cloudCoverPct,
    'precipitation': precipitation,
    'notes': notes,
    'weather_suitable': weatherSuitable,
  };
}
