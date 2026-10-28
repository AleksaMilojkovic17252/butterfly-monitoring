import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/observation_rules.dart';
import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/core/validation/visit_rules.dart';
import 'package:mobile/core/validation/weather_check.dart';
import 'package:mobile/features/visits/domain/gps_gaps.dart';
import 'package:mobile/features/visits/domain/route_stats.dart';
import 'package:mobile/features/visits/domain/visit_pauses.dart';
import 'package:mobile/features/visits/ui/widgets/form_section_title.dart';

/// At most this many GPS gaps are listed; the rest are counted.
const _maxGapLines = 5;

/// The warnings of the Finish screen (T040), one tile each. None of them
/// blocks Finish; they tell the observer what is missing or odd before the
/// visit is saved. Shows nothing when there is no warning.
///
/// The end weather values are the ones typed so far, so the tiles update as
/// the observer types. Coverage and gaps come from the stored track points,
/// which lag the live position by up to 30 s (D-061); [routeStats] is worked
/// out by the caller once per route, because it is slow.
class FinishWarnings extends StatelessWidget {
  const FinishWarnings({
    super.key,
    required this.visit,
    required this.protocol,
    required this.routeStats,
    required this.lastPointAt,
    required this.pauses,
    required this.observations,
    required this.taxonNames,
    required this.temperatureEndC,
    required this.windBeaufortEnd,
    required this.cloudCoverEndPct,
    required this.weatherMissingReason,
    required this.now,
  });
  final SurveyVisit visit;
  final ProjectProtocol protocol;

  /// Coverage and gaps of the stored route, or null when another phone
  /// recorded it (its points are not here).
  final RouteStats? routeStats;

  /// When the newest stored point was recorded, or null when there is none.
  final DateTime? lastPointAt;

  /// The visit's pauses, plus the one still running (ended at [now]).
  final List<VisitPause> pauses;
  final List<ButterflyObservation> observations;

  /// Taxon id to the name shown in the observation lines.
  final Map<String, String> taxonNames;
  final double? temperatureEndC;
  final int? windBeaufortEnd;
  final int cloudCoverEndPct;
  final String weatherMissingReason;

  /// The time the visit would end, for the observation time rule (V04).
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final warnings = [
      ..._weatherWarnings(),
      ..._routeWarnings(),
      ..._windowWarnings(),
      ..._observationWarnings(),
    ];
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionTitle('Warnings'),
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Column(
            children: [
              for (final warning in warnings)
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(warning),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The end weather: missing (V05) or outside the protocol (W06).
  List<String> _weatherWarnings() {
    final input = VisitInput(
      status: 'completed',
      // The start weather and time were checked when the visit started.
      startedAt: null,
      temperatureEndC: temperatureEndC,
      windBeaufortEnd: windBeaufortEnd,
      cloudCoverEndPct: cloudCoverEndPct,
      precipitation: visit.precipitation,
      weatherMissingReason: weatherMissingReason,
    );
    final context = VisitRuleContext(
      protocol: protocol,
      transectObservationCount: 0,
    );
    final warnings = <String>[];
    final temperature = temperatureEndC;
    final wind = windBeaufortEnd;
    if (temperature == null || wind == null) {
      if (weatherMissingReason.trim().isEmpty) {
        final missing = [
          if (temperature == null) 'temperature',
          if (wind == null) 'wind',
        ];
        warnings.add(
          'The end weather is missing (${missing.join(', ')}). '
          'Fill it in or say why you could not.',
        );
      }
    } else if (visitWarnings(input, context).contains('W06')) {
      final failed = failedWeatherThresholds(
        protocol: protocol,
        temperatureC: temperature,
        windBeaufort: wind,
        cloudCoverPct: cloudCoverEndPct,
        precipitation: visit.precipitation,
      );
      warnings.add(
        'The end weather is outside the protocol: ${failed.join('; ')}.',
      );
    }
    return warnings;
  }

  /// Coverage below the protocol's minimum, and GPS gaps.
  List<String> _routeWarnings() {
    final stats = routeStats;
    if (stats == null) return ['The route was recorded on another phone.'];
    final warnings = <String>[];

    final coverage = stats.coveragePct;
    if (coverage == null) {
      warnings.add('Too few GPS points to work out the coverage.');
    } else if (coverage < protocol.minCoveragePct) {
      warnings.add(
        'The route covers ${coverage.floor()} % of the transect '
        '(protocol: at least ${protocol.minCoveragePct} %).',
      );
    }

    // The stretch after the last point depends on the clock, so it is worked
    // out here and not in the stats.
    final trailing = trailingGpsGap(lastPointAt, pauses, now, protocol.gpsGapS);
    final gaps = [...stats.gaps, ?trailing];
    for (final gap in gaps.take(_maxGapLines)) {
      final minutes = (gap.outsidePauses.inSeconds / 60).round();
      warnings.add(
        'No GPS ${_hhmm(gap.from)}–${_hhmm(gap.to)} '
        '(${minutes < 1 ? 1 : minutes} min)',
      );
    }
    if (gaps.length > _maxGapLines) {
      warnings.add('and ${gaps.length - _maxGapLines} more GPS gaps');
    }
    return warnings;
  }

  /// The start of the visit outside the season or the daily window (W07).
  List<String> _windowWarnings() {
    final startedAt = visit.startedAt;
    if (startedAt == null) return [];
    return [
      seasonWarning(protocol, startedAt),
      timeWindowWarning(protocol, startedAt),
    ].nonNulls.toList();
  }

  /// Observations a hard rule would refuse today, one line each.
  List<String> _observationWarnings() {
    final context = ObservationRuleContext(
      visitStatus: 'completed',
      visitStartedAt: visit.startedAt,
      visitEndedAt: now,
      visitZeroConfirmed: false,
      toleranceMin: protocol.observationTimeToleranceMin,
      accuracyWarningM: protocol.gpsAccuracyWarningM,
      taxonPhotoRequired: false,
      photoCount: 0,
    );
    final warnings = <String>[];
    for (final row in observations) {
      final errors = validateObservation(
        ObservationInput.fromObservation(row),
        context,
      );
      if (errors.isEmpty) continue;
      final name = taxonNames[row.taxonId] ?? 'A butterfly';
      warnings.add(
        '$name at ${_hhmm(row.observedAt)}: ${ruleErrorText(errors)}',
      );
    }
    return warnings;
  }
}

/// Local time, "10:42"
String _hhmm(DateTime time) {
  final local = time.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.hour.toString().padLeft(2, '0')}:$minute';
}
