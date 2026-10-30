import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/domain/local_time.dart';

/// The observations of a visit (T106), grouped by section in walking order and
/// then "No section". A row shows the species, the count and the time, and
/// opens the observation detail.
class VisitObservationList extends ConsumerWidget {
  const VisitObservationList({
    super.key,
    required this.visit,
    required this.observations,
  });
  final SurveyVisit visit;

  /// The visit's live observations, by the time they were seen.
  final List<ButterflyObservation> observations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (observations.isEmpty) {
      return const Card(
        child: ListTile(title: Text('No butterflies recorded')),
      );
    }
    final sections =
        ref.watch(transectSectionsProvider(visit.transectId)).value ?? [];
    // The taxon ids joined with commas, sorted (see taxaByIdsProvider).
    final taxonIds = ({for (final o in observations) o.taxonId}.toList()
      ..sort());
    final taxa = ref.watch(taxaByIdsProvider(taxonIds.join(','))).value ?? [];
    final names = {for (final t in taxa) t.id: t.scientificName};

    // A heading and the rows under it; sections with no rows are left out.
    final groups = <(String, List<ButterflyObservation>)>[
      for (final entry in sections)
        (
          'Section ${entry.section.sectionCode}',
          [
            for (final o in observations)
              if (o.transectSectionId == entry.section.id) o,
          ],
        ),
    ];
    final sectionIds = {for (final entry in sections) entry.section.id};
    groups.add((
      'No section',
      [
        for (final o in observations)
          if (!sectionIds.contains(o.transectSectionId)) o,
      ],
    ));

    return Card(
      child: Column(
        children: [
          for (final (heading, rows) in groups)
            if (rows.isNotEmpty) ...[
              ListTile(
                dense: true,
                title: Text(
                  heading,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final o in rows)
                ListTile(
                  title: Text(names[o.taxonId] ?? '…'),
                  subtitle: Text(formatLocalTime(o.observedAt)),
                  trailing: Text('× ${o.count}'),
                  onTap: () => context.push(
                    '/projects/${visit.projectId}/observations/${o.id}',
                  ),
                ),
            ],
        ],
      ),
    );
  }
}
