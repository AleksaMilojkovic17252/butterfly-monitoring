/// Which link of a butterfly observation a plant record is for (T052).
enum PlantLinkRole { host, nectar }

/// The relations a plant record may have to be linked as the host plant. The
/// same lists as `PLANT_LINK_ROLES` on the server (D-086): a `resting_plant`
/// fits neither, and the server refuses it.
const hostResourceTypes = [
  'larval_host',
  'oviposition_plant',
  'unknown_association',
];

/// The relations a plant record may have to be linked as the nectar plant.
const nectarResourceTypes = ['nectar_source', 'unknown_association'];

/// The relations that fit [role].
List<String> resourceTypesFor(PlantLinkRole role) =>
    role == PlantLinkRole.host ? hostResourceTypes : nectarResourceTypes;

/// True when a plant record of [resourceType] may be linked as [role].
bool fitsRole(String resourceType, PlantLinkRole role) =>
    resourceTypesFor(role).contains(resourceType);

/// The relation a new plant record gets when it is made from the link of
/// [role], so it fits without the user choosing.
String presetResourceType(PlantLinkRole role) =>
    role == PlantLinkRole.host ? 'larval_host' : 'nectar_source';

/// "Host plant" or "Nectar plant", for tiles and titles.
String plantLinkLabel(PlantLinkRole role) =>
    role == PlantLinkRole.host ? 'Host plant' : 'Nectar plant';
