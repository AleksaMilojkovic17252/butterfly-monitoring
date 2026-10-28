import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';

/// Used when the project protocol is not on the phone: the server's default
/// `max_distance_from_transect_m`.
const _defaultMaxDistanceM = 20.0;

/// Index of the section the observer is in (T039): the section line nearest
/// to [position], if it is at most [maxDistanceM] away. Null when every
/// section is further away (off the transect) or there are none.
int? currentSectionIndex(
  LatLng position,
  List<List<LatLng>> sections,
  double maxDistanceM,
) {
  int? nearestIndex;
  double? nearestM;
  for (var i = 0; i < sections.length; i++) {
    final d = distanceToLineM(position, sections[i]);
    if (d == null || d > maxDistanceM) continue;
    if (nearestM == null || d < nearestM) {
      nearestM = d;
      nearestIndex = i;
    }
  }
  return nearestIndex;
}

/// The section of [sections] that [position] is in, or null (off the
/// transect, or no sections). [protocol] gives the allowed distance; the
/// server's default is used while it is not on the phone.
TransectSection? sectionAt(
  LatLng position,
  List<SectionWithHabitat> sections,
  ProjectProtocol? protocol,
) {
  final index = currentSectionIndex(position, [
    for (final s in sections) parseLineString(s.section.geometry),
  ], protocol?.maxDistanceFromTransectM ?? _defaultMaxDistanceM);
  return index == null ? null : sections[index].section;
}

/// The section the observer of a visit is in now, from the newest GPS fix,
/// or null (no fix yet, off the transect, or the visit is not tracked on
/// this phone). The active visit screen shows its code; the butterfly entry
/// (T045) stores it on the observation. `autoDispose`: it stops following
/// the fixes when no screen uses it.
final currentSectionProvider = Provider.autoDispose
    .family<TransectSection?, String>((ref, visitId) {
      final visit = ref.watch(visitProvider(visitId)).value;
      final position = ref.watch(
        trackingControllerProvider.select(
          (tracking) =>
              tracking.visitId == visitId ? tracking.lastPosition : null,
        ),
      );
      if (visit == null || position == null) return null;

      final sections =
          ref.watch(transectSectionsProvider(visit.transectId)).value ?? [];
      final protocol = ref
          .watch(projectProtocolProvider(visit.projectId))
          .value;
      return sectionAt(
        LatLng(position.latitude, position.longitude),
        sections,
        protocol,
      );
    });
