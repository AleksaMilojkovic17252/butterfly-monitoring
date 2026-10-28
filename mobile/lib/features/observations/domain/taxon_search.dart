import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/search_text.dart';

/// Most taxa the Recent list shows.
const maxRecentTaxa = 8;

/// What a taxon is called in lists: the Serbian name, or the scientific one
/// when there is no Serbian name.
String taxonTitle(Taxon taxon) {
  return taxon.vernacularNameSr.isEmpty
      ? taxon.scientificName
      : taxon.vernacularNameSr;
}

/// The taxa whose names contain [query], ignoring case and diacritics (the
/// stored `searchText` is built the same way). An empty query finds nothing.
List<Taxon> searchTaxa(List<Taxon> taxa, String query) {
  final text = searchTextOf(query.trim());
  if (text.isEmpty) return [];
  return [
    for (final taxon in taxa)
      if (taxon.searchText.contains(text)) taxon,
  ];
}

/// The taxa used most recently, newest first, at most [maxRecentTaxa].
List<Taxon> recentTaxa(List<Taxon> taxa, List<TaxonUsage> usage) {
  final used = [
    for (final u in usage)
      if (u.lastUsedAt != null) u,
  ]..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
  return _inOrderOf(taxa, used.take(maxRecentTaxa));
}

/// The starred taxa, in the order of [taxa] (by name).
List<Taxon> favouriteTaxa(List<Taxon> taxa, List<TaxonUsage> usage) {
  final starred = {
    for (final u in usage)
      if (u.isFavourite) u.taxonId,
  };
  return [
    for (final taxon in taxa)
      if (starred.contains(taxon.id)) taxon,
  ];
}

/// The taxon of each usage row, in the order of the rows. A row whose taxon
/// is not in [taxa] (retired meanwhile) is skipped.
List<Taxon> _inOrderOf(List<Taxon> taxa, Iterable<TaxonUsage> rows) {
  final byId = {for (final taxon in taxa) taxon.id: taxon};
  return [
    for (final row in rows)
      if (byId[row.taxonId] != null) byId[row.taxonId]!,
  ];
}
