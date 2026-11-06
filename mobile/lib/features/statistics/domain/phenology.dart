import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/features/statistics/domain/indicator_inputs.dart';
import 'package:mobile/features/statistics/domain/iso_week.dart';

/// One bar of the phenology chart: an ISO week with its individuals and records.
class WeekCount {
  const WeekCount({
    required this.week,
    required this.individuals,
    required this.records,
  });

  final int week;
  final int individuals;
  final int records;
}

/// The records that the phenology counts, the same as `_RECORDS` in the
/// server's T061 migration: any source (free records too), not deleted, and a
/// record with a visit only when that visit is on the phone, not deleted and
/// not cancelled. Draft and in-progress visits count. Call it once and pass
/// the result to the functions below.
List<StatRecord> phenologyRecords(
  List<StatVisit> visits,
  List<StatRecord> records,
) {
  final visitsById = {for (final v in visits) v.id: v};
  return [
    for (final r in records)
      if (r.deletedAt == null && _visitAllows(visitsById, r.surveyVisitId)) r,
  ];
}

bool _visitAllows(Map<String, StatVisit> visitsById, String? visitId) {
  if (visitId == null) return true;
  final visit = visitsById[visitId];
  return visit != null &&
      visit.deletedAt == null &&
      visit.status != 'cancelled';
}

/// The ids of the taxa that have a record in [records] (from
/// [phenologyRecords]), in any year.
Set<String> phenologyTaxa(List<StatRecord> records) => {
  for (final r in records) r.taxonId,
};

/// The ISO years that have a record in [records] (from [phenologyRecords]),
/// newest first.
List<int> phenologyYears(List<StatRecord> records, String timeZone) {
  final years = {
    for (final r in records)
      isoWeek(siteTimeIn(timeZone, r.observedAt)).isoYear,
  };
  return years.toList()..sort((a, b) => b.compareTo(a));
}

/// The weeks of [isoYear] that have records of [taxonId] in [records] (from
/// [phenologyRecords]), by week. Weeks
/// without records are not returned; the chart fills them in.
List<WeekCount> phenology({
  required List<StatRecord> records,
  required String taxonId,
  required int isoYear,
  required String timeZone,
}) {
  final individuals = <int, int>{};
  final counts = <int, int>{};
  for (final r in records) {
    if (r.taxonId != taxonId) continue;
    final iso = isoWeek(siteTimeIn(timeZone, r.observedAt));
    if (iso.isoYear != isoYear) continue;
    individuals[iso.week] = (individuals[iso.week] ?? 0) + r.count;
    counts[iso.week] = (counts[iso.week] ?? 0) + 1;
  }
  return [
    for (final week in individuals.keys.toList()..sort())
      WeekCount(
        week: week,
        individuals: individuals[week]!,
        records: counts[week]!,
      ),
  ];
}
