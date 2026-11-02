import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/observation_values.dart';
import 'package:mobile/features/map/ui/widgets/map_feature_dialog.dart';
import 'package:mobile/features/observations/domain/behaviour_json.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/visits/domain/local_time.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// The popups of the project map (T059), one function per kind of feature.
/// Each shows a [MapFeatureDialog]. Open closes the dialog and then pushes the
/// feature's screen, so Back returns to the map with its camera and filters
/// as they were.

/// Opens [path] from a popup: first closes the dialog, then pushes the screen.
/// [context] is the map's, not the dialog's.
void _openFrom(BuildContext context, BuildContext dialogContext, String path) {
  Navigator.of(dialogContext).pop();
  context.push(path);
}

Future<void> _showPopup(
  BuildContext context,
  String title,
  List<(String, String)> lines,
  String path, {
  String? photoPath,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => MapFeatureDialog(
      title: title,
      lines: lines,
      onOpen: () => _openFrom(context, dialogContext, path),
      photoPath: photoPath,
    ),
  );
}

/// An observation: its photo if it has one on this phone, species and count,
/// when, life stage, behaviour and section. [taxon] and [sectionCode] are null
/// when not known on this phone, [photo] when it has none. Opens the
/// observation detail (T106).
Future<void> showObservationPopup(
  BuildContext context, {
  required ButterflyObservation observation,
  required Taxon? taxon,
  required String? sectionCode,
  required Photo? photo,
}) {
  final behaviours = [
    for (final value in behaviourValuesFromJson(observation.behaviour))
      observationValueLabel(value),
  ];
  return _showPopup(
    context,
    '${taxon?.scientificName ?? 'Butterfly'} × ${observation.count}',
    [
      ('Seen', formatLocalDateTime(observation.observedAt)),
      ('Life stage', observationValueLabel(observation.lifeStage)),
      ('Behaviour', behaviours.isEmpty ? '–' : behaviours.join(', ')),
      if (sectionCode != null) ('Section', sectionCode),
    ],
    '/projects/${observation.projectId}/observations/${observation.id}',
    photoPath: photo?.localPath,
  );
}

/// A transect: code, name and length. Opens the transect detail.
Future<void> showTransectPopup(BuildContext context, Transect transect) {
  return _showPopup(context, '${transect.code} · ${transect.name}', [
    ('Length', formatDistance(transect.lengthM)),
  ], '/projects/${transect.projectId}/transects/${transect.id}');
}

/// A section: its code, transect and habitat. A section has no screen of its
/// own, so Open goes to the transect detail.
Future<void> showSectionPopup(
  BuildContext context, {
  required SectionWithHabitat entry,
  required Transect transect,
}) {
  return _showPopup(
    context,
    'Section ${entry.section.sectionCode} · ${transect.code}',
    [('Habitat', entry.habitatName ?? '–')],
    '/projects/${transect.projectId}/transects/${transect.id}',
  );
}

/// A visit's route: transect, when it started and its status. Opens the
/// visit like the transect detail does: a visit in progress in the active
/// visit screen, any other in the read-only detail.
Future<void> showRoutePopup(
  BuildContext context, {
  required SurveyVisit visit,
  required Transect? transect,
}) {
  final path = visit.status == 'in_progress'
      ? '/projects/${visit.projectId}/visits/${visit.id}'
      : '/projects/${visit.projectId}/transects/${visit.transectId}'
            '/visits/${visit.id}';
  return _showPopup(context, 'Visit route · ${transect?.code ?? '?'}', [
    ('Started', formatLocalDateTime(visit.startedAt ?? visit.createdAt)),
    ('Status', visitStatusLabel(visit.status)),
  ], path);
}
