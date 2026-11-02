import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';

/// The species of the project's observations on this phone, by scientific
/// name (T059). The map view uses it for the popup and the Filters sheet for
/// the Species row, so the query is made once. `autoDispose`: it stops when
/// the map closes.
final projectTaxaProvider = Provider.autoDispose.family<List<Taxon>, String>((
  ref,
  projectId,
) {
  final observations =
      ref.watch(projectObservationsProvider(projectId)).value ?? const [];
  // The argument of taxaByIdsProvider is the sorted ids joined by commas.
  final ids = {for (final o in observations) o.taxonId}.toList()..sort();
  final taxa = ref.watch(taxaByIdsProvider(ids.join(','))).value ?? const [];
  return [...taxa]
    ..sort((a, b) => a.scientificName.compareTo(b.scientificName));
});
