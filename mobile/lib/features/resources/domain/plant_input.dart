import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';

/// What the plant form edits (T052): the values of one plant record, without
/// the parts the repository decides (project, visit, time, who made it).
/// Immutable, like `ObservationDetails`: every change makes a new copy.
class PlantInput {
  const PlantInput({
    this.plantTaxonId,
    this.resourceType = '',
    this.abundanceClass = '',
    this.phenologyStage = '',
    this.floweringIntensity = '',
    this.eggsPresent,
    this.larvaePresent,
    this.feedingDamagePresent,
    this.notes = '',
    this.geometry,
  });

  /// The values of a stored row. A geometry that cannot be read is null.
  factory PlantInput.fromRow(PlantResourceObservation row) => PlantInput(
    plantTaxonId: row.plantTaxonId,
    resourceType: row.resourceType,
    abundanceClass: row.abundanceClass,
    phenologyStage: row.phenologyStage,
    floweringIntensity: row.floweringIntensity,
    eggsPresent: row.eggsPresent,
    larvaePresent: row.larvaePresent,
    feedingDamagePresent: row.feedingDamagePresent,
    notes: row.notes,
    geometry: CapturedGeometry.fromGeoJson(row.geometryGeojson),
  );

  /// Null for an unidentified plant (then [notes] are required).
  final String? plantTaxonId;

  /// Empty until the user chooses; the form requires a choice.
  final String resourceType;

  /// Empty means not recorded, for these three.
  final String abundanceClass;
  final String phenologyStage;
  final String floweringIntensity;

  /// True, false, or null for unknown.
  final bool? eggsPresent;
  final bool? larvaePresent;
  final bool? feedingDamagePresent;
  final String notes;

  /// Null until a point or polygon is drawn.
  final CapturedGeometry? geometry;

  /// A copy with the text choices and the notes changed. The species, the
  /// tri-states and the geometry can be set to null, so they have their own
  /// methods below.
  PlantInput copyWith({
    String? resourceType,
    String? abundanceClass,
    String? phenologyStage,
    String? floweringIntensity,
    String? notes,
  }) => PlantInput(
    plantTaxonId: plantTaxonId,
    resourceType: resourceType ?? this.resourceType,
    abundanceClass: abundanceClass ?? this.abundanceClass,
    phenologyStage: phenologyStage ?? this.phenologyStage,
    floweringIntensity: floweringIntensity ?? this.floweringIntensity,
    eggsPresent: eggsPresent,
    larvaePresent: larvaePresent,
    feedingDamagePresent: feedingDamagePresent,
    notes: notes ?? this.notes,
    geometry: geometry,
  );

  /// A copy with the species set, or cleared with null (unidentified).
  PlantInput withTaxon(String? taxonId) => PlantInput(
    plantTaxonId: taxonId,
    resourceType: resourceType,
    abundanceClass: abundanceClass,
    phenologyStage: phenologyStage,
    floweringIntensity: floweringIntensity,
    eggsPresent: eggsPresent,
    larvaePresent: larvaePresent,
    feedingDamagePresent: feedingDamagePresent,
    notes: notes,
    geometry: geometry,
  );

  /// A copy with the shape set, or cleared with null.
  PlantInput withGeometry(CapturedGeometry? shape) => PlantInput(
    plantTaxonId: plantTaxonId,
    resourceType: resourceType,
    abundanceClass: abundanceClass,
    phenologyStage: phenologyStage,
    floweringIntensity: floweringIntensity,
    eggsPresent: eggsPresent,
    larvaePresent: larvaePresent,
    feedingDamagePresent: feedingDamagePresent,
    notes: notes,
    geometry: shape,
  );

  /// A copy with the three tri-state answers replaced (each true, false or
  /// null for unknown).
  PlantInput withSigns({bool? eggs, bool? larvae, bool? feedingDamage}) =>
      PlantInput(
        plantTaxonId: plantTaxonId,
        resourceType: resourceType,
        abundanceClass: abundanceClass,
        phenologyStage: phenologyStage,
        floweringIntensity: floweringIntensity,
        eggsPresent: eggs,
        larvaePresent: larvae,
        feedingDamagePresent: feedingDamage,
        notes: notes,
        geometry: geometry,
      );

  /// A copy with the notes trimmed, as they are stored.
  PlantInput trimmed() => copyWith(notes: notes.trim());

  /// The fields with the server's names, for a sync payload. There is no
  /// `patch_area_m2`: the phone never sends one (D-086), the server works the
  /// area out. Needs a [geometry].
  Map<String, Object?> toPayload() => {
    'plant_taxon': plantTaxonId,
    'resource_type': resourceType,
    'abundance_class': abundanceClass,
    'phenology_stage': phenologyStage,
    'flowering_intensity': floweringIntensity,
    'eggs_present': eggsPresent,
    'larvae_present': larvaePresent,
    'feeding_damage_present': feedingDamagePresent,
    'notes': notes,
    'geometry': geometry?.toGeoJson(),
  };
}
