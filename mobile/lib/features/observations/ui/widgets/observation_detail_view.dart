import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/db/sync_status.dart';
import 'package:mobile/core/validation/observation_values.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/observations/domain/behaviour_json.dart';
import 'package:mobile/features/observations/domain/flight_direction.dart';
import 'package:mobile/features/observations/ui/widgets/edit_observation_sheet.dart';
import 'package:mobile/features/observations/domain/photo_parent.dart';
import 'package:mobile/features/observations/ui/widgets/record_photo_section.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/plant_links.dart';
import 'package:mobile/features/resources/domain/plant_taxon_search.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/transects/ui/widgets/detail_section_title.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/local_time.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// The page of one observation that is on this phone, shown by
/// `ObservationDetailScreen` (T106). The extended fields (sex, life stage,
/// behaviour, microhabitat, flight direction, notes) show only when they differ
/// from what a quick entry leaves. The Edit button (T046) opens
/// `EditObservationSheet`.
class ObservationDetailView extends ConsumerWidget {
  const ObservationDetailView({super.key, required this.observation});
  final ButterflyObservation observation;

  /// "± 5 m" or "accuracy unknown".
  String _accuracy() {
    final accuracy = observation.locationAccuracyM;
    return accuracy == null ? 'accuracy unknown' : '± ${accuracy.round()} m';
  }

  /// Opens the edit sheet, or says why it cannot: an observation with a sync
  /// problem must be dealt with on the sync screen first.
  Future<void> _edit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final o = observation;
    if (o.syncStatus == SyncStatus.conflict ||
        o.syncStatus == SyncStatus.rejected) {
      messenger.showSnackBar(
        const SnackBar(content: Text(ObservationRepository.syncProblemMessage)),
      );
      return;
    }
    final saved = await EditObservationSheet.show(context, observation: o);
    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Saved')));
    }
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
    // Edit: only for the user's own observation (logout keeps other users'
    // rows, and the server would refuse the edit), and only while the visit is
    // known and not locked. It stays hidden while the visit loads.
    final userId = ref.watch(authControllerProvider).profile?.id;
    final canEdit =
        o.recordedById == userId &&
        (visitId == null || (visit != null && !visitIsLocked(visit.status)));
    final behaviours = [
      for (final value in behaviourValuesFromJson(o.behaviour))
        observationValueLabel(value),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observation'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
        ],
      ),
      // The app bar covers the top; SafeArea keeps the list above the system
      // navigation buttons.
      body: SafeArea(
        top: false,
        child: ListView(
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
                o.microhabitat.isNotEmpty ||
                o.flightDirectionDeg != null ||
                o.hostPlantRecordId != null ||
                o.nectarPlantRecordId != null ||
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
                    if (o.microhabitat.isNotEmpty)
                      ListTile(
                        title: const Text('Microhabitat'),
                        subtitle: Text(o.microhabitat),
                      ),
                    if (o.flightDirectionDeg != null)
                      ListTile(
                        title: const Text('Flight direction'),
                        subtitle: Text(
                          flightDirectionLabel(o.flightDirectionDeg!),
                        ),
                      ),
                    if (o.hostPlantRecordId != null)
                      _LinkedPlantRow(
                        role: PlantLinkRole.host,
                        projectId: o.projectId,
                        plantRecordId: o.hostPlantRecordId!,
                      ),
                    if (o.nectarPlantRecordId != null)
                      _LinkedPlantRow(
                        role: PlantLinkRole.nectar,
                        projectId: o.projectId,
                        plantRecordId: o.nectarPlantRecordId!,
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
            RecordPhotoSection(
              parent: PhotoParent.observation(
                id: o.id,
                projectId: o.projectId,
                surveyVisitId: o.surveyVisitId,
              ),
              photoRequired: taxon?.photoRequired ?? false,
            ),
          ],
        ),
      ),
    );
  }
}

/// A "Host plant" or "Nectar plant" row of the observation detail (T052): the
/// linked plant's name, and a tap opens that plant record's form.
class _LinkedPlantRow extends ConsumerWidget {
  const _LinkedPlantRow({
    required this.role,
    required this.projectId,
    required this.plantRecordId,
  });
  final PlantLinkRole role;
  final String projectId;
  final String plantRecordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(plantRecordProvider(plantRecordId)).value;
    final taxonId = record?.plantTaxonId;
    final plant = taxonId == null
        ? null
        : ref.watch(plantTaxaByIdsProvider(taxonId)).value?.firstOrNull;
    return ListTile(
      title: Text(plantLinkLabel(role)),
      subtitle: Text(
        record == null
            ? 'Not on this phone'
            : plant == null
            ? 'Unidentified plant'
            : plantTitle(plant),
      ),
      trailing: record == null ? null : const Icon(Icons.chevron_right),
      onTap: record == null
          ? null
          : () => context.push('/projects/$projectId/plants/$plantRecordId'),
    );
  }
}
