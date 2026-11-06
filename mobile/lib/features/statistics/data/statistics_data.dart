import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/statistics/domain/indicator_inputs.dart';
import 'package:mobile/features/statistics/domain/phenology.dart' as phenology;
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';

/// Everything the statistics screen reads (T062): the user's visits and
/// observations of the project, the protocol's time zone and the taxa of those
/// observations. No repository of its own: the existing providers already read
/// Drift, so the screen works offline.
class StatisticsData {
  StatisticsData({
    required this.visits,
    required this.records,
    required this.timeZone,
    required this.protocol,
    required this.taxa,
  });

  final List<StatVisit> visits;
  final List<StatRecord> records;
  final String timeZone;
  final ProjectProtocol? protocol;

  /// Taxon id to taxon, for names.
  final Map<String, Taxon> taxa;

  /// The name shown for a taxon: Serbian, else English, else scientific.
  String displayName(String taxonId) {
    final taxon = taxa[taxonId];
    if (taxon == null) return taxonId;
    if (taxon.vernacularNameSr.isNotEmpty) return taxon.vernacularNameSr;
    if (taxon.vernacularNameEn.isNotEmpty) return taxon.vernacularNameEn;
    return taxon.scientificName;
  }

  /// Taxon id to scientific name, for the top list's tie-break. Built once.
  late final Map<String, String> scientificNames = {
    for (final t in taxa.values) t.id: t.scientificName,
  };

  /// The records the phenology counts, filtered once.
  late final List<StatRecord> phenologyRecords = phenology.phenologyRecords(
    visits,
    records,
  );
}

/// The statistics data of a project, or null while the first load runs.
/// `autoDispose`: the queries stop when the screen closes.
final statisticsDataProvider = Provider.autoDispose
    .family<StatisticsData?, String>((ref, projectId) {
      final visits = ref.watch(projectVisitsProvider(projectId)).value;
      final observations = ref
          .watch(projectObservationsProvider(projectId))
          .value;
      final protocolAsync = ref.watch(projectProtocolProvider(projectId));
      if (visits == null || observations == null) return null;
      // The argument of taxaByIdsProvider is the sorted ids joined by commas.
      final ids = {for (final o in observations) o.taxonId}.toList()..sort();
      final taxaAsync = ref.watch(taxaByIdsProvider(ids.join(',')));
      // Wait for the protocol (its time zone decides the year) and the taxa
      // (names). An error is not waited for: names fall back to ids and the
      // zone to UTC.
      if (protocolAsync.isLoading && !protocolAsync.hasValue) return null;
      if (taxaAsync.isLoading && !taxaAsync.hasValue) return null;
      final protocol = protocolAsync.value;
      final taxa = taxaAsync.value ?? const <Taxon>[];
      return StatisticsData(
        visits: [for (final v in visits) StatVisit.fromRow(v)],
        records: [for (final o in observations) StatRecord.fromRow(o)],
        // Without a protocol the phone's own zone name is not known; UTC keeps
        // the figures stable until the protocol is pulled.
        timeZone: protocol?.timeZone ?? 'UTC',
        protocol: protocol,
        taxa: {for (final t in taxa) t.id: t},
      );
    });
