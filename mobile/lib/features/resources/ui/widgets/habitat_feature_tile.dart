import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/resources/data/habitat_repository.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/domain/habitat_names.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/local_time.dart';

/// One habitat feature in a list (T054): the habitat type's name, "Habitat",
/// the date, and the date of the visit it was recorded on. The icon shows the
/// shape. Used by the Plants & habitat screen.
class HabitatFeatureTile extends ConsumerWidget {
  const HabitatFeatureTile({
    super.key,
    required this.feature,
    required this.onTap,
  });
  final HabitatFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Every type is read, so a deactivated one still shows its name.
    final types = ref.watch(habitatTypesProvider).value ?? const [];
    final type = types.where((t) => t.id == feature.habitatTypeId).firstOrNull;
    final visitId = feature.surveyVisitId;
    final visit = visitId == null
        ? null
        : ref.watch(visitProvider(visitId)).value;
    final visitDate = visit == null
        ? null
        : (visit.startedAt ?? visit.createdAt);

    final icon = switch (CapturedGeometry.fromGeoJson(feature.geometryGeojson)
        ?.mode) {
      GeometryMode.line => Icons.timeline,
      GeometryMode.polygon => Icons.pentagon_outlined,
      _ => Icons.place_outlined,
    };
    final parts = [
      'Habitat',
      formatLocalDateTime(feature.observedAt),
      if (visitDate != null) 'visit ${formatLocalDateTime(visitDate)}',
    ];
    return ListTile(
      leading: Icon(icon),
      title: Text(type == null ? 'Habitat feature' : habitatTypeTitle(type)),
      subtitle: Text(parts.join(' · ')),
      onTap: onTap,
    );
  }
}
