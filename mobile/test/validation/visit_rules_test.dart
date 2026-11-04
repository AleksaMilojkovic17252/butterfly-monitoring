// One group per visit rule (T055). The server has the same cases in
// `backend/apps/surveys/tests.py`.
//
// Run from mobile/: flutter test test/validation

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/core/validation/visit_rules.dart';

import 'protocol_fixture.dart';

VisitRuleContext makeContext({
  int observations = 0,
  bool allowPrecipitation = false,
  String timeZone = 'Europe/Belgrade',
}) {
  return VisitRuleContext(
    protocol: makeProtocol(
      allowPrecipitation: allowPrecipitation,
      timeZone: timeZone,
    ),
    transectObservationCount: observations,
  );
}

/// A completed visit with good weather, started at 10:00 UTC on 1 June (12:00
/// in Belgrade). UTC instants, so the tests do not depend on the machine's zone.
VisitInput makeInput({
  String status = 'completed',
  DateTime? startedAt,
  bool noStartedAt = false,
  double? temperatureStartC = 20,
  double? temperatureEndC = 22,
  int? windBeaufortStart = 2,
  int? windBeaufortEnd = 2,
  int? cloudCoverStartPct = 20,
  int? cloudCoverEndPct = 20,
  String precipitation = 'none',
  String weatherMissingReason = '',
  bool zeroObservationConfirmed = false,
}) {
  return VisitInput(
    status: status,
    startedAt: noStartedAt ? null : startedAt ?? DateTime.utc(2026, 6, 1, 10),
    temperatureStartC: temperatureStartC,
    temperatureEndC: temperatureEndC,
    windBeaufortStart: windBeaufortStart,
    windBeaufortEnd: windBeaufortEnd,
    cloudCoverStartPct: cloudCoverStartPct,
    cloudCoverEndPct: cloudCoverEndPct,
    precipitation: precipitation,
    weatherMissingReason: weatherMissingReason,
    zeroObservationConfirmed: zeroObservationConfirmed,
  );
}

void main() {
  test('a good visit has no errors or warnings', () {
    // Completed with no observations needs the tick (V06), so it has 1.
    final context = makeContext(observations: 1);
    expect(validateVisit(makeInput(), context), isEmpty);
    expect(visitWarnings(makeInput(), context), isEmpty);
  });

  group('V05', () {
    test('a finished visit needs the weather or a reason', () {
      final context = makeContext(observations: 1);
      for (final status in ['completed', 'synced', 'reviewed', 'locked']) {
        final input = makeInput(
          status: status,
          temperatureEndC: null,
          windBeaufortEnd: null,
        );
        expect(validateVisit(input, context), {
          'temperature_end_c': ['V05'],
          'wind_beaufort_end': ['V05'],
        }, reason: status);
      }
      final withReason = makeInput(
        temperatureEndC: null,
        windBeaufortEnd: null,
        weatherMissingReason: 'Thermometer broke',
      );
      expect(validateVisit(withReason, context), isEmpty);
    });
    test('an unfinished visit may miss weather', () {
      for (final status in ['draft', 'in_progress', 'cancelled']) {
        final input = makeInput(
          status: status,
          temperatureEndC: null,
          cloudCoverStartPct: null,
        );
        expect(validateVisit(input, makeContext()), isEmpty, reason: status);
      }
    });
    test('a blank reason does not count', () {
      final input = makeInput(
        cloudCoverEndPct: null,
        weatherMissingReason: '  ',
      );
      expect(validateVisit(input, makeContext(observations: 1)), {
        'cloud_cover_end_pct': ['V05'],
      });
    });
  });

  group('V06', () {
    test('confirmed zero with observations is refused', () {
      final input = makeInput(zeroObservationConfirmed: true);
      expect(validateVisit(input, makeContext()), isEmpty);
      expect(validateVisit(input, makeContext(observations: 2)), {
        'zero_observation_confirmed': ['V06'],
      });
    });
    test('completed with no observations needs the tick', () {
      expect(validateVisit(makeInput(), makeContext()), {
        'zero_observation_confirmed': ['V06'],
      });
      expect(
        validateVisit(makeInput(zeroObservationConfirmed: true), makeContext()),
        isEmpty,
      );
    });
    test('a visit in progress needs no tick', () {
      final input = makeInput(status: 'in_progress');
      expect(validateVisit(input, makeContext()), isEmpty);
    });
  });

  group('V07', () {
    test('unknown status and precipitation are refused', () {
      final errors = validateVisit(
        makeInput(status: 'x', precipitation: 'x'),
        makeContext(),
      );
      expect(errors['status'], ['V07']);
      expect(errors['precipitation'], ['V07']);
    });
  });

  group('W06', () {
    final context = makeContext(observations: 1);
    test('start weather outside the protocol', () {
      final cases = [
        makeInput(temperatureStartC: 10),
        makeInput(temperatureStartC: 15, cloudCoverStartPct: 80),
        makeInput(windBeaufortStart: 6),
        makeInput(precipitation: 'rain'),
      ];
      for (final input in cases) {
        expect(visitWarnings(input, context), ['W06']);
      }
    });
    test('cool and clear, or warm and cloudy, is fine', () {
      final coolAndClear = makeInput(
        temperatureStartC: 15,
        cloudCoverStartPct: 40,
      );
      expect(visitWarnings(coolAndClear, context), isEmpty);
      final warmAndCloudy = makeInput(
        temperatureStartC: 17,
        cloudCoverStartPct: 100,
      );
      expect(visitWarnings(warmAndCloudy, context), isEmpty);
    });
    test('rain is fine when the protocol allows it', () {
      final allowed = makeContext(observations: 1, allowPrecipitation: true);
      expect(visitWarnings(makeInput(precipitation: 'rain'), allowed), isEmpty);
    });
    test('end weather outside the protocol', () {
      expect(visitWarnings(makeInput(temperatureEndC: 9), context), ['W06']);
    });
    test('end weather that is not recorded is skipped', () {
      final input = makeInput(
        temperatureEndC: null,
        windBeaufortEnd: null,
        cloudCoverEndPct: null,
      );
      expect(visitWarnings(input, context), isEmpty);
    });
  });

  group('W07', () {
    final context = makeContext(observations: 1);
    // Belgrade is UTC+2 on all these dates (summer time).
    test('season, both end days inside', () {
      for (final day in [
        DateTime.utc(2026, 4, 1, 10),
        DateTime.utc(2026, 9, 30, 10),
      ]) {
        expect(visitWarnings(makeInput(startedAt: day), context), isEmpty);
      }
      for (final day in [
        DateTime.utc(2026, 3, 31, 10),
        DateTime.utc(2026, 10, 1, 10),
      ]) {
        expect(visitWarnings(makeInput(startedAt: day), context), ['W07']);
      }
    });
    test('daily window, both ends inside', () {
      for (final at in [
        DateTime.utc(2026, 6, 1, 8),
        DateTime.utc(2026, 6, 1, 10),
        DateTime.utc(2026, 6, 1, 15),
      ]) {
        expect(visitWarnings(makeInput(startedAt: at), context), isEmpty);
      }
      for (final at in [
        DateTime.utc(2026, 6, 1, 7, 59),
        DateTime.utc(2026, 6, 1, 15, 1),
      ]) {
        expect(visitWarnings(makeInput(startedAt: at), context), ['W07']);
      }
    });
    test('a visit that has not started has no warning', () {
      expect(visitWarnings(makeInput(noStartedAt: true), context), isEmpty);
    });
    test("the window follows the protocol's zone, not the phone's", () {
      final belgrade = makeContext(observations: 1);
      final newYork = makeContext(
        observations: 1,
        timeZone: 'America/New_York',
      );
      // 12:00 UTC: 14:00 in Belgrade, 08:00 in New York.
      final noon = makeInput(startedAt: DateTime.utc(2026, 6, 1, 12));
      expect(visitWarnings(noon, belgrade), isEmpty);
      expect(visitWarnings(noon, newYork), ['W07']);
      // 18:00 UTC: 20:00 in Belgrade, 14:00 in New York.
      final evening = makeInput(startedAt: DateTime.utc(2026, 6, 1, 18));
      expect(visitWarnings(evening, belgrade), ['W07']);
      expect(visitWarnings(evening, newYork), isEmpty);
    });
    test("the season uses the site's calendar date", () {
      final belgrade = makeProtocol();
      final newYork = makeProtocol(timeZone: 'America/New_York');
      // 22:30 UTC on 31 March: already 1 April in Belgrade, still 31 March
      // in New York.
      final start = DateTime.utc(2026, 3, 31, 22, 30);
      expect(seasonWarning(belgrade, start), isNull);
      expect(seasonWarning(newYork, start), isNotNull);
      // 22:30 UTC on 30 September: 1 October in Belgrade.
      final end = DateTime.utc(2026, 9, 30, 22, 30);
      expect(seasonWarning(belgrade, end), isNotNull);
      expect(seasonWarning(newYork, end), isNull);
    });
    test('winter time: Belgrade is UTC+1 in January', () {
      final protocol = makeProtocol();
      expect(timeWindowWarning(protocol, DateTime.utc(2026, 1, 15, 9)), isNull);
      expect(
        timeWindowWarning(protocol, DateTime.utc(2026, 1, 15, 8, 59)),
        isNotNull,
      );
    });
    test("an unknown zone falls back to the phone's zone", () {
      final unknown = makeContext(observations: 1, timeZone: 'Not/AZone');
      // Local DateTimes: the fallback reads the instant in the machine's zone.
      expect(
        visitWarnings(makeInput(startedAt: DateTime(2026, 6, 1, 12)), unknown),
        isEmpty,
      );
      expect(
        visitWarnings(
          makeInput(startedAt: DateTime(2026, 6, 1, 9, 59)),
          unknown,
        ),
        ['W07'],
      );
    });
    test('the season label does not depend on the machine zone', () {
      expect(seasonLabel(makeProtocol()), '1.4.2026. - 30.9.2026.');
    });
  });
}
