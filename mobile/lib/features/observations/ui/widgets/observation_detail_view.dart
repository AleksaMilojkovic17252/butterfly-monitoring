import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/observation_values.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/transects/ui/widgets/detail_section_title.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/local_time.dart';

/// The page of one observation that is on this phone, shown by
/// `ObservationDetailScreen` (T106). The extended fields (sex, life stage,
/// behaviour, notes) show only when they differ from what a quick entry leaves.
class ObservationDetailView extends ConsumerWidget {
  const ObservationDetailView({super.key, required this.observation});
  final ButterflyObservation observation;

  /// The behaviour labels from the JSON text (`["flying","resting"]`). Bad
  /// JSON counts as no behaviour.
  List<String> _behaviours() {
    try {
      final decoded = jsonDecode(observation.behaviour);
      if (decoded is! List) return [];
      return [for (final b in decoded) observationValueLabel('$b')];
    } on FormatException {
      return [];
    }
  }

  /// "± 5 m" or "accuracy unknown".
  String _accuracy() {
    final accuracy = observation.locationAccuracyM;
    return accuracy == null ? 'accuracy unknown' : '± ${accuracy.round()} m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = observation;
    final taxon = ref.watch(taxaByIdsProvider(o.taxonId)).value?.firstOrNull;

    // The section code: through the visit to its transect's sections.
    final visitId = o.surveyVisitId;
    final visit = visitId == null
        ? null
        : ref.watch(visitProvider(visitId)).value;
    final sections = visit == null
        ? null
        : ref.watch(transectSectionsProvider(visit.transectId)).value;
    String sectionCode = '–';
    for (final entry in sections ?? <SectionWithHabitat>[]) {
      if (entry.section.id == o.transectSectionId) {
        sectionCode = entry.section.sectionCode;
      }
    }

    // Local names: Serbian, and English when it is different.
    final localNames = [
      if (taxon != null && taxon.vernacularNameSr.isNotEmpty)
        taxon.vernacularNameSr,
      if (taxon != null &&
          taxon.vernacularNameEn.isNotEmpty &&
          taxon.vernacularNameEn != taxon.vernacularNameSr)
        taxon.vernacularNameEn,
    ];
    final behaviours = _behaviours();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observation'),
        // TODO(T046): an Edit button in `actions`, hidden when the visit is
        // locked (T042).
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(taxon?.scientificName ?? '…'),
                  subtitle: localNames.isEmpty
                      ? null
                      : Text(localNames.join(' · ')),
                ),
                ListTile(
                  leading: const Icon(Icons.numbers),
                  title: const Text('Count'),
                  trailing: Text('${o.count}'),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(formatLocalDateTime(o.observedAt)),
                ),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    '${o.lat.toStringAsFixed(5)}, ${o.lon.toStringAsFixed(5)}',
                  ),
                  subtitle: Text(_accuracy()),
                ),
                ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: const Text('Section'),
                  trailing: Text(sectionCode),
                ),
                ListTile(
                  title: const Text('Source'),
                  trailing: Text(observationValueLabel(o.source)),
                ),
                ListTile(
                  title: const Text('Confidence'),
                  trailing: Text(
                    observationValueLabel(o.identificationConfidence),
                  ),
                ),
              ],
            ),
          ),
          if (o.sex != 'unknown' ||
              o.lifeStage != 'adult' ||
              behaviours.isNotEmpty ||
              o.notes.isNotEmpty) ...[
            const DetailSectionTitle('Details'),
            Card(
              child: Column(
                children: [
                  if (o.sex != 'unknown')
                    ListTile(
                      title: const Text('Sex'),
                      trailing: Text(observationValueLabel(o.sex)),
                    ),
                  if (o.lifeStage != 'adult')
                    ListTile(
                      title: const Text('Life stage'),
                      trailing: Text(observationValueLabel(o.lifeStage)),
                    ),
                  if (behaviours.isNotEmpty)
                    ListTile(
                      title: const Text('Behaviour'),
                      subtitle: Text(behaviours.join(', ')),
                    ),
                  if (o.notes.isNotEmpty)
                    ListTile(
                      title: const Text('Notes'),
                      subtitle: Text(o.notes),
                    ),
                ],
              ),
            ),
          ],
          const DetailSectionTitle('Photos'),
          // TODO(T050): show the observation's thumbnails here.
          const Card(child: ListTile(title: Text('No photos'))),
        ],
      ),
    );
  }
}
