/// What the Finish screen asks for (T040): the weather at the end, the
/// reason when it is missing, and the true-zero confirmation. Passed to
/// `VisitRepository.finish`.
class FinishValues {
  const FinishValues({
    required this.temperatureEndC,
    required this.windBeaufortEnd,
    required this.cloudCoverEndPct,
    required this.weatherMissingReason,
    required this.zeroObservationConfirmed,
  });
  final double? temperatureEndC;
  final int? windBeaufortEnd;
  final int? cloudCoverEndPct;

  /// Empty when the end weather is filled in.
  final String weatherMissingReason;
  final bool zeroObservationConfirmed;
}
