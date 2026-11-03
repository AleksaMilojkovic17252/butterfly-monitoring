import 'package:flutter/foundation.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';

/// What the habitat form edits (T054): the values of one habitat feature,
/// without the parts the repository decides (project, visit, time, who made
/// it). Immutable: every change makes a new copy with [copyWith].
@immutable
class HabitatInput {
  const HabitatInput({
    this.habitatTypeId = '',
    this.managementTypeId,
    this.vegetationHeightCm,
    this.shrubCoverPct,
    this.treeCoverPct,
    this.bareGroundPct,
    this.flowerAbundanceClass = '',
    this.grazingIntensity = '',
    this.mowingStatus = '',
    this.disturbanceType = '',
    this.notes = '',
    this.geometry,
  });

  /// The values of a stored row. A geometry that cannot be read is null.
  factory HabitatInput.fromRow(HabitatFeature row) => HabitatInput(
    habitatTypeId: row.habitatTypeId,
    managementTypeId: row.managementTypeId,
    vegetationHeightCm: row.vegetationHeightCm,
    shrubCoverPct: row.shrubCoverPct,
    treeCoverPct: row.treeCoverPct,
    bareGroundPct: row.bareGroundPct,
    flowerAbundanceClass: row.flowerAbundanceClass,
    grazingIntensity: row.grazingIntensity,
    mowingStatus: row.mowingStatus,
    disturbanceType: row.disturbanceType,
    notes: row.notes,
    geometry: CapturedGeometry.fromGeoJson(row.geometryGeojson),
  );

  /// Empty until the user chooses; the form requires a choice.
  final String habitatTypeId;

  /// Null means not recorded.
  final String? managementTypeId;

  /// Centimetres; null means not measured.
  final int? vegetationHeightCm;

  /// Cover in percent. Null means not recorded, which is not the same as 0.
  final int? shrubCoverPct;
  final int? treeCoverPct;
  final int? bareGroundPct;

  /// Empty means not recorded, for these four.
  final String flowerAbundanceClass;
  final String grazingIntensity;
  final String mowingStatus;
  final String disturbanceType;
  final String notes;

  /// Null until a point, line or polygon is drawn.
  final CapturedGeometry? geometry;

  /// A copy with some fields changed. The nullable fields take a function,
  /// not a value: with a plain `int? shrubCoverPct` argument, "not given" and
  /// "set to null" would look the same and a cover could never be cleared. Pass
  /// `shrubCoverPct: () => null` to clear it, `() => 40` to set it, and leave
  /// it out to keep it (the pattern of `MapFilter.copyWith`).
  HabitatInput copyWith({
    String? habitatTypeId,
    ValueGetter<String?>? managementTypeId,
    ValueGetter<int?>? vegetationHeightCm,
    ValueGetter<int?>? shrubCoverPct,
    ValueGetter<int?>? treeCoverPct,
    ValueGetter<int?>? bareGroundPct,
    String? flowerAbundanceClass,
    String? grazingIntensity,
    String? mowingStatus,
    String? disturbanceType,
    String? notes,
    ValueGetter<CapturedGeometry?>? geometry,
  }) {
    return HabitatInput(
      habitatTypeId: habitatTypeId ?? this.habitatTypeId,
      managementTypeId: managementTypeId != null
          ? managementTypeId()
          : this.managementTypeId,
      vegetationHeightCm: vegetationHeightCm != null
          ? vegetationHeightCm()
          : this.vegetationHeightCm,
      shrubCoverPct: shrubCoverPct != null
          ? shrubCoverPct()
          : this.shrubCoverPct,
      treeCoverPct: treeCoverPct != null ? treeCoverPct() : this.treeCoverPct,
      bareGroundPct: bareGroundPct != null
          ? bareGroundPct()
          : this.bareGroundPct,
      flowerAbundanceClass: flowerAbundanceClass ?? this.flowerAbundanceClass,
      grazingIntensity: grazingIntensity ?? this.grazingIntensity,
      mowingStatus: mowingStatus ?? this.mowingStatus,
      disturbanceType: disturbanceType ?? this.disturbanceType,
      notes: notes ?? this.notes,
      geometry: geometry != null ? geometry() : this.geometry,
    );
  }

  /// A copy with the notes trimmed, as they are stored.
  HabitatInput trimmed() => copyWith(notes: notes.trim());

  /// The fields with the server's names, for a sync payload. Needs a
  /// [geometry].
  Map<String, Object?> toPayload() => {
    'habitat_type': habitatTypeId,
    'management_type': managementTypeId,
    'vegetation_height_cm': vegetationHeightCm,
    'shrub_cover_pct': shrubCoverPct,
    'tree_cover_pct': treeCoverPct,
    'bare_ground_pct': bareGroundPct,
    'flower_abundance_class': flowerAbundanceClass,
    'grazing_intensity': grazingIntensity,
    'mowing_status': mowingStatus,
    'disturbance_type': disturbanceType,
    'notes': notes,
    'geometry': geometry?.toGeoJson(),
  };
}
