import 'package:mobile/core/db/app_database.dart';

/// A protocol with the defaults of docs/requirements/protocol.md, for the
/// rule tests. Built directly: no Drift database is needed.
ProjectProtocol makeProtocol({
  bool allowPrecipitation = false,
  double accuracyWarningM = 25,
}) {
  return ProjectProtocol(
    projectId: 'project',
    id: 'protocol',
    protocolVersion: '1.0',
    surveyMethod: 'pollard_walk',
    seasonStart: DateTime(2026, 4, 1),
    seasonEnd: DateTime(2026, 9, 30),
    dayStartTime: '10:00:00',
    dayEndTime: '17:00:00',
    minTemperatureC: 13,
    sunnyTemperatureC: 17,
    maxCloudCoverPctIfCool: 40,
    maxWindBeaufort: 5,
    allowPrecipitation: allowPrecipitation,
    targetVisitsPerSeason: 8,
    maxDistanceFromTransectM: 20,
    observationTimeToleranceMin: 5,
    gpsIntervalS: 5,
    gpsIntervalBatterySaverS: 15,
    gpsAccuracyWarningM: accuracyWarningM,
    gpsGapS: 60,
    highCountThreshold: 50,
    minCoveragePct: 80,
  );
}
