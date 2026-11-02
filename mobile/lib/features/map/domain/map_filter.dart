import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/domain/behaviour_json.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';

/// The filters of the project map (T059). Each one is optional (null means
/// "any"). They narrow the observations layer only; the visit filter also
/// picks the visit whose route the route layer draws.
@immutable
class MapFilter {
  const MapFilter({
    this.visitId,
    this.taxonId,
    this.from,
    this.to,
    this.lifeStage,
    this.behaviour,
    this.habitatTypeId,
  });

  final String? visitId;
  final String? taxonId;

  /// First and last local calendar day of the date range, both included.
  final DateTime? from;
  final DateTime? to;
  final String? lifeStage;

  /// One behaviour value (an observation can have several).
  final String? behaviour;

  /// The habitat type of the observation's section.
  final String? habitatTypeId;

  /// How many filters are set. The date range counts as one.
  int get activeCount =>
      (visitId != null ? 1 : 0) +
      (taxonId != null ? 1 : 0) +
      (from != null || to != null ? 1 : 0) +
      (lifeStage != null ? 1 : 0) +
      (behaviour != null ? 1 : 0) +
      (habitatTypeId != null ? 1 : 0);

  /// A copy with some fields changed. Each argument is a function, not a
  /// value: with a plain `String? visitId` argument, "not given" and "set to
  /// null" would look the same, and the filter could never be cleared. Pass
  /// `visitId: () => null` to clear it, `visitId: () => 'abc'` to set it, and
  /// leave it out to keep it.
  MapFilter copyWith({
    ValueGetter<String?>? visitId,
    ValueGetter<String?>? taxonId,
    ValueGetter<DateTime?>? from,
    ValueGetter<DateTime?>? to,
    ValueGetter<String?>? lifeStage,
    ValueGetter<String?>? behaviour,
    ValueGetter<String?>? habitatTypeId,
  }) {
    return MapFilter(
      visitId: visitId != null ? visitId() : this.visitId,
      taxonId: taxonId != null ? taxonId() : this.taxonId,
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      lifeStage: lifeStage != null ? lifeStage() : this.lifeStage,
      behaviour: behaviour != null ? behaviour() : this.behaviour,
      habitatTypeId: habitatTypeId != null
          ? habitatTypeId()
          : this.habitatTypeId,
    );
  }

  /// Whether [o] passes every filter that is set. [sectionHabitats] maps a
  /// section id to its habitat type id; an observation without a section does
  /// not match while the habitat filter is on.
  bool matches(ButterflyObservation o, Map<String, String?> sectionHabitats) {
    if (visitId != null && o.surveyVisitId != visitId) return false;
    if (taxonId != null && o.taxonId != taxonId) return false;
    if (lifeStage != null && o.lifeStage != lifeStage) return false;

    // The days are local calendar days, so compare the local time.
    final seen = o.observedAt.toLocal();
    final start = from;
    if (start != null &&
        seen.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    final end = to;
    // The end is the start of the next day, excluded. `DateTime(y, m, d + 1)`
    // and not `+ Duration(days: 1)`, because a day with a clock change is not
    // 24 hours long.
    if (end != null &&
        !seen.isBefore(DateTime(end.year, end.month, end.day + 1))) {
      return false;
    }

    if (habitatTypeId != null) {
      final sectionId = o.transectSectionId;
      if (sectionId == null || sectionHabitats[sectionId] != habitatTypeId) {
        return false;
      }
    }
    // The JSON is parsed only when this filter is on.
    if (behaviour != null &&
        !behaviourValuesFromJson(o.behaviour).contains(behaviour)) {
      return false;
    }
    return true;
  }
}

/// The map's filters. `autoDispose`, so they reset when the map closes.
class MapFilterNotifier extends Notifier<MapFilter> {
  @override
  MapFilter build() => const MapFilter();

  /// Replaces the filters.
  void set(MapFilter filter) => state = filter;

  /// Clears every filter.
  void clear() => state = const MapFilter();
}

final mapFilterProvider =
    NotifierProvider.autoDispose<MapFilterNotifier, MapFilter>(
      MapFilterNotifier.new,
    );

/// The map's filters without the values that are no longer on this phone (T059).
/// A pull can remove a visit or a species, or a section's habitat, that is
/// selected; the dropdown then shows "Any", so the filter must not go on
/// hiding every observation. Everything that shows or applies the filters
/// (the badge, the sheet, the map) reads this one and not [mapFilterProvider].
/// A list that is still loading counts as "keep the value".
final effectiveMapFilterProvider = Provider.autoDispose
    .family<MapFilter, String>((ref, projectId) {
      final filter = ref.watch(mapFilterProvider);
      final visits = ref.watch(projectVisitsProvider(projectId)).value;
      final observations = ref
          .watch(projectObservationsProvider(projectId))
          .value;
      final sections = ref.watch(projectSectionsProvider(projectId)).value;

      final visitGone =
          visits != null && !visits.any((v) => v.id == filter.visitId);
      final taxonGone =
          observations != null &&
          !observations.any((o) => o.taxonId == filter.taxonId);
      // The Habitat type row offers only habitats that have a name.
      final habitatGone =
          sections != null &&
          !sections.any(
            (s) =>
                s.section.habitatTypeId == filter.habitatTypeId &&
                s.habitatName != null,
          );
      return filter.copyWith(
        visitId: filter.visitId != null && visitGone ? () => null : null,
        taxonId: filter.taxonId != null && taxonGone ? () => null : null,
        habitatTypeId: filter.habitatTypeId != null && habitatGone
            ? () => null
            : null,
      );
    });

/// The project's observations that pass the map's filters. A new list is made
/// only when the observations, the sections or the filters change, so the map
/// can use `identical` to tell whether it has to rebuild its markers.
final filteredObservationsProvider = Provider.autoDispose
    .family<List<ButterflyObservation>, String>((ref, projectId) {
      final observations =
          ref.watch(projectObservationsProvider(projectId)).value ?? const [];
      final sections =
          ref.watch(projectSectionsProvider(projectId)).value ?? const [];
      final filter = ref.watch(effectiveMapFilterProvider(projectId));

      final habitats = {
        for (final s in sections) s.section.id: s.section.habitatTypeId,
      };
      return [
        for (final o in observations)
          if (filter.matches(o, habitats)) o,
      ];
    });
