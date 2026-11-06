import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/features/statistics/domain/indicator_inputs.dart';

/// One species in the top list: its individuals and how many records.
class SpeciesTotal {
  const SpeciesTotal({
    required this.taxonId,
    required this.individuals,
    required this.records,
  });

  final String taxonId;
  final int individuals;
  final int records;
}

/// The figures of one transect in one year (T062). The same definitions as the
/// server's `report_transect_indicators` view (D-099).
class TransectIndicators {
  const TransectIndicators({
    required this.visits,
    required this.trueZeroVisits,
    required this.hours,
    required this.km,
    required this.speciesCount,
    required this.individuals,
    required this.perKm,
    required this.perHour,
    required this.top,
  });

  final int visits;
  final int trueZeroVisits;
  final double hours;
  final double km;
  final int speciesCount;
  final int individuals;

  /// Null when [km] is 0.
  final double? perKm;

  /// Null when [hours] is 0.
  final double? perHour;

  /// Up to 10 species, most individuals first.
  final List<SpeciesTotal> top;
}

/// The years that have a finished visit, newest first, with the year taken
/// from the visit's start in the study site's [timeZone].
List<int> indicatorYears(List<StatVisit> visits, String timeZone) {
  final years = {
    for (final v in visits)
      if (v.isFinished) siteTimeIn(timeZone, v.startedAt!).year,
  };
  return years.toList()..sort((a, b) => b.compareTo(a));
}

/// The ids of the transects that have a finished visit in [year].
Set<String> indicatorTransects(
  List<StatVisit> visits,
  int year,
  String timeZone,
) => {
  for (final v in visits)
    if (v.isFinished && siteTimeIn(timeZone, v.startedAt!).year == year)
      v.transectId,
};

/// The figures of [transectId] in [year]. Only finished visits count, and only
/// records with source `transect` that are not deleted. Hours and km are summed
/// per visit, so a visit with many records is not counted many times.
/// [scientificNames] (taxon id to name) only breaks ties in the top list.
TransectIndicators transectIndicators({
  required List<StatVisit> visits,
  required List<StatRecord> records,
  required String transectId,
  required int year,
  required String timeZone,
  required Map<String, String> scientificNames,
}) {
  final chosen = {
    for (final v in visits)
      if (v.isFinished &&
          v.transectId == transectId &&
          siteTimeIn(timeZone, v.startedAt!).year == year)
        v.id: v,
  };

  var seconds = 0;
  var metres = 0.0;
  var zeros = 0;
  for (final v in chosen.values) {
    seconds += v.durationSeconds ?? 0;
    metres += v.distanceWalkedM ?? 0;
    if (v.zeroObservationConfirmed) zeros++;
  }

  final individualsByTaxon = <String, int>{};
  final recordsByTaxon = <String, int>{};
  var individuals = 0;
  for (final r in records) {
    if (r.deletedAt != null || r.source != 'transect') continue;
    if (!chosen.containsKey(r.surveyVisitId)) continue;
    individuals += r.count;
    individualsByTaxon[r.taxonId] =
        (individualsByTaxon[r.taxonId] ?? 0) + r.count;
    recordsByTaxon[r.taxonId] = (recordsByTaxon[r.taxonId] ?? 0) + 1;
  }

  final totals = [
    for (final e in individualsByTaxon.entries)
      SpeciesTotal(
        taxonId: e.key,
        individuals: e.value,
        records: recordsByTaxon[e.key]!,
      ),
  ];
  // Most individuals, then most records, then scientific name.
  totals.sort((a, b) {
    final byIndividuals = b.individuals.compareTo(a.individuals);
    if (byIndividuals != 0) return byIndividuals;
    final byRecords = b.records.compareTo(a.records);
    if (byRecords != 0) return byRecords;
    return (scientificNames[a.taxonId] ?? a.taxonId).compareTo(
      scientificNames[b.taxonId] ?? b.taxonId,
    );
  });

  final hours = seconds / 3600.0;
  final km = metres / 1000.0;
  return TransectIndicators(
    visits: chosen.length,
    trueZeroVisits: zeros,
    hours: hours,
    km: km,
    speciesCount: totals.length,
    individuals: individuals,
    perKm: km > 0 ? individuals / km : null,
    perHour: hours > 0 ? individuals / hours : null,
    top: totals.take(10).toList(),
  );
}
