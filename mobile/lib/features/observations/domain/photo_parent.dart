/// What a photo belongs to: a butterfly observation or a plant record (T052).
/// The server wants exactly one parent per photo, and the payload names it by a
/// different key (`observation` or `plant_resource`). `PhotoRepository` takes
/// this instead of an observation, so one code path serves both.
class PhotoParent {
  /// A photo of a butterfly observation.
  const PhotoParent.observation({
    required this.id,
    required this.projectId,
    required this.surveyVisitId,
  }) : payloadKey = 'observation';

  /// A photo of a plant record.
  const PhotoParent.plant({
    required this.id,
    required this.projectId,
    required this.surveyVisitId,
  }) : payloadKey = 'plant_resource';

  /// The id of the observation or plant record.
  final String id;
  final String projectId;

  /// The parent's visit; null for a record made outside a visit. A locked visit
  /// refuses new photos (D-072).
  final String? surveyVisitId;

  /// The key that holds [id] in the photo's create payload.
  final String payloadKey;

  /// True for a plant record's photo; it fills `plant_resource_id` locally.
  bool get isPlant => payloadKey == 'plant_resource';
}
