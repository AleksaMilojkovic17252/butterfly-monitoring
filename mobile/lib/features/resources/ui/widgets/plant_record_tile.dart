import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/core/validation/plant_values.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/plant_taxon_search.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/local_time.dart';

/// One plant record in a list (T052): the plant (or "Unidentified plant"), its
/// relation to butterflies, the date, and the date of the visit it was
/// recorded on. Used by the Plants & habitat screen and the link picker.
class PlantRecordTile extends ConsumerWidget {
  const PlantRecordTile({
    super.key,
    required this.record,
    required this.onTap,
    this.selected = false,
  });
  final PlantResourceObservation record;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxonId = record.plantTaxonId;
    // By id, so a deactivated plant still shows its name.
    final plant = taxonId == null
        ? null
        : ref.watch(plantTaxaByIdsProvider(taxonId)).value?.firstOrNull;
    final visitId = record.surveyVisitId;
    final visit = visitId == null
        ? null
        : ref.watch(visitProvider(visitId)).value;
    final visitDate = visit == null
        ? null
        : (visit.startedAt ?? visit.createdAt);

    final isPolygon = record.geometryGeojson.contains('"Polygon"');
    final area = record.patchAreaM2;
    final parts = [
      plantValueLabel(record.resourceType),
      formatLocalDateTime(record.observedAt),
      if (isPolygon && area != null) formatArea(area),
      if (visitDate != null) 'visit ${formatLocalDateTime(visitDate)}',
    ];
    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      leading: Icon(isPolygon ? Icons.pentagon_outlined : Icons.place_outlined),
      title: Text(plant == null ? 'Unidentified plant' : plantTitle(plant)),
      subtitle: Text(parts.join(' · ')),
      onTap: onTap,
    );
  }
}
