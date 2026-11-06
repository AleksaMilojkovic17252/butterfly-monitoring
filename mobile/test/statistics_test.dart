import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/statistics/domain/indicator_inputs.dart';
import 'package:mobile/features/statistics/domain/iso_week.dart';
import 'package:mobile/features/statistics/domain/phenology.dart';
import 'package:mobile/features/statistics/domain/transect_indicators.dart';

// T061's fixture (tmp/t061/smoke.py), project in Europe/Belgrade. The phone has
// no validated taxon (D-100): O2 "B, validated as C" stays B here, where the
// server view shows C. Species and individual counts are the same.

const zone = 'Europe/Belgrade';

StatVisit visit(
  String id,
  String transect,
  String status,
  String started, {
  int? seconds,
  double? metres,
  bool zero = false,
}) => StatVisit(
  id: id,
  transectId: transect,
  status: status,
  startedAt: DateTime.parse('${started}Z'),
  durationSeconds: seconds,
  distanceWalkedM: metres,
  zeroObservationConfirmed: zero,
  deletedAt: null,
);

StatRecord record(
  String id,
  String? visitId,
  String taxon,
  int count,
  String when, {
  String source = 'transect',
  bool deleted = false,
}) => StatRecord(
  id: id,
  surveyVisitId: visitId,
  taxonId: taxon,
  count: count,
  source: source,
  observedAt: DateTime.parse('${when}Z'),
  deletedAt: deleted ? DateTime.utc(2026, 7, 1) : null,
);

void main() {
  final visits = [
    visit(
      'V1',
      'T1',
      'completed',
      '2026-06-01T09:00:00',
      seconds: 3600,
      metres: 1000,
    ),
    visit(
      'V2',
      'T1',
      'completed',
      '2026-06-08T09:00:00',
      seconds: 1800,
      metres: 500,
      zero: true,
    ),
    visit('V3', 'T1', 'cancelled', '2026-06-15T09:00:00'),
    visit('V4', 'T1', 'in_progress', '2026-06-20T09:00:00'),
    visit(
      'V5',
      'T2',
      'completed',
      '2025-12-31T23:30:00',
      seconds: 600,
      metres: 0,
    ),
  ];
  final records = [
    record('O1', 'V1', 'A', 3, '2026-06-01T09:30:00'),
    record('O2', 'V1', 'B', 2, '2026-06-01T09:40:00'),
    record('O3', 'V1', 'A', 1, '2026-06-01T09:50:00', deleted: true),
    record('O4', 'V3', 'A', 4, '2026-06-15T09:10:00'),
    record('F', null, 'D', 1, '2026-06-03T10:00:00', source: 'incidental'),
  ];
  const names = {'A': 'A', 'B': 'B', 'C': 'C', 'D': 'D'};

  TransectIndicators indicators(String transect) => transectIndicators(
    visits: visits,
    records: records,
    transectId: transect,
    year: 2026,
    timeZone: zone,
    scientificNames: names,
  );

  test('years: V5 starts on 1 January at the site, so T2 is 2026', () {
    expect(indicatorYears(visits, zone), [2026]);
    expect(indicatorTransects(visits, 2026, zone), {'T1', 'T2'});
    expect(indicatorTransects(visits, 2025, zone), isEmpty);
  });

  test('T1 / 2026', () {
    final i = indicators('T1');
    expect(i.visits, 2);
    expect(i.trueZeroVisits, 1);
    expect(i.hours.toStringAsFixed(2), '1.50');
    expect(i.km.toStringAsFixed(2), '1.50');
    expect(i.speciesCount, 2);
    expect(i.individuals, 5);
    expect(i.perKm!.toStringAsFixed(2), '3.33');
    expect(i.perHour!.toStringAsFixed(2), '3.33');
    expect(
      [for (final s in i.top) (s.taxonId, s.individuals, s.records)],
      [('A', 3, 1), ('B', 2, 1)],
    );
  });

  test('T2 / 2026', () {
    final i = indicators('T2');
    expect(i.visits, 1);
    expect(i.km.toStringAsFixed(2), '0.00');
    expect(i.perKm, isNull);
    expect(i.perHour!.toStringAsFixed(2), '0.00');
    expect(i.individuals, 0);
    expect(i.speciesCount, 0);
    expect(i.top, isEmpty);
  });

  group('phenology 2026', () {
    List<(int, int, int)> weeks(String taxon) => [
      for (final w in phenology(
        records: phenologyRecords(visits, records),
        taxonId: taxon,
        isoYear: 2026,
        timeZone: zone,
      ))
        (w.week, w.individuals, w.records),
    ];

    test('weeks', () {
      // O4 (cancelled visit) and the deleted O3 are left out.
      expect(weeks('A'), [(23, 3, 1)]);
      expect(weeks('B'), [(23, 2, 1)]);
      // The free record counts.
      expect(weeks('D'), [(23, 1, 1)]);
      expect(weeks('C'), isEmpty);
    });

    test('taxa', () {
      expect(phenologyTaxa(phenologyRecords(visits, records)), {'A', 'B', 'D'});
    });
  });

  test('isoWeek edge cases', () {
    expect(isoWeek(DateTime(2026, 1, 1)), (isoYear: 2026, week: 1));
    expect(isoWeek(DateTime(2025, 12, 29)), (isoYear: 2026, week: 1));
    expect(isoWeek(DateTime(2027, 1, 1)), (isoYear: 2026, week: 53));
    expect(isoWeek(DateTime(2026, 6, 3)), (isoYear: 2026, week: 23));
  });
}
