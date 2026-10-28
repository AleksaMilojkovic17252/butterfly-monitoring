import 'package:mobile/core/db/app_database.dart';

/// What the Finish screen counts from a visit's transect observations
/// (T040): how many were recorded, how many species and individuals, and how
/// many observations each section has. Only `source = transect` rows are
/// counted, as in rule V06; the caller passes the visit's live rows.
class VisitSummary {
  const VisitSummary({
    required this.observationCount,
    required this.speciesCount,
    required this.individuals,
    required this.perSection,
  });

  /// Counts [observations], the visit's live rows; rows of another source are
  /// left out.
  factory VisitSummary.fromObservations(
    List<ButterflyObservation> observations,
  ) {
    final transect = [
      for (final row in observations)
        if (row.source == 'transect') row,
    ];
    final perSection = <String?, int>{};
    for (final row in transect) {
      perSection[row.transectSectionId] =
          (perSection[row.transectSectionId] ?? 0) + 1;
    }
    return VisitSummary(
      observationCount: transect.length,
      speciesCount: {for (final row in transect) row.taxonId}.length,
      individuals: transect.fold(0, (sum, row) => sum + row.count),
      perSection: perSection,
    );
  }

  final int observationCount;

  /// Distinct taxa.
  final int speciesCount;

  /// The sum of the observations' counts.
  final int individuals;

  /// Section id to number of observations; the key is null for observations
  /// without a section.
  final Map<String?, int> perSection;
}
