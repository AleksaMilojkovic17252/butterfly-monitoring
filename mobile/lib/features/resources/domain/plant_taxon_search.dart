import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/search_text.dart';

/// Most plants the Recent list shows.
const maxRecentPlants = 8;

/// What a plant is called in lists: the Serbian name, or the scientific one
/// when there is no Serbian name.
String plantTitle(PlantTaxon plant) {
  return plant.vernacularName.isEmpty
      ? plant.scientificName
      : plant.vernacularName;
}

/// The plants whose names contain [query], ignoring case and diacritics ("cicak"
/// finds "čičak"). Done in memory: the list is about 100 plants, so the table
/// has no search column. An empty query finds nothing.
List<PlantTaxon> searchPlantTaxa(List<PlantTaxon> plants, String query) {
  final text = searchTextOf(query.trim());
  if (text.isEmpty) return [];
  return [
    for (final plant in plants)
      if (searchTextOf(
        '${plant.scientificName} ${plant.vernacularName} '
        '${plant.vernacularNameEn}',
      ).contains(text))
        plant,
  ];
}

/// The plants of the user's own records, newest record first, without repeats,
/// at most [maxRecentPlants]. [records] must be newest first. A plant that is no
/// longer in [plants] (deactivated) is skipped.
List<PlantTaxon> recentPlantTaxa(
  List<PlantTaxon> plants,
  List<PlantResourceObservation> records,
) {
  final byId = {for (final plant in plants) plant.id: plant};
  final result = <PlantTaxon>[];
  for (final record in records) {
    final plant = byId[record.plantTaxonId];
    if (plant == null || result.contains(plant)) continue;
    result.add(plant);
    if (result.length == maxRecentPlants) break;
  }
  return result;
}
