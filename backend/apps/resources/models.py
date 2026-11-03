from django.contrib.gis.db import models as gis_models
from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel


class ResourceType(models.TextChoices):
    LARVAL_HOST = "larval_host", "Larval host plant"
    NECTAR_SOURCE = "nectar_source", "Nectar source"
    OVIPOSITION_PLANT = "oviposition_plant", "Oviposition plant"
    RESTING_PLANT = "resting_plant", "Resting plant"
    UNKNOWN_ASSOCIATION = "unknown_association", "Unknown association"


class AbundanceClass(models.TextChoices):
    """Individuals or flowering stems in the patch."""

    A_1 = "1", "1"
    B_2_10 = "2-10", "2-10"
    C_11_100 = "11-100", "11-100"
    D_101_1000 = "101-1000", "101-1000"
    E_GT_1000 = ">1000", "More than 1000"


class PhenologyStage(models.TextChoices):
    VEGETATIVE = "vegetative", "Vegetative"
    BUDDING = "budding", "Budding"
    FLOWERING = "flowering", "Flowering"
    FRUITING = "fruiting", "Fruiting"
    SENESCENT = "senescent", "Senescent"


class Intensity(models.TextChoices):
    NONE = "none", "None"
    LOW = "low", "Low"
    MEDIUM = "medium", "Medium"
    HIGH = "high", "High"


class MowingStatus(models.TextChoices):
    UNMOWN = "unmown", "Unmown"
    RECENTLY_MOWN = "recently_mown", "Recently mown"
    MOWN_THIS_SEASON = "mown_this_season", "Mown this season"
    UNKNOWN = "unknown", "Unknown"


class Disturbance(models.TextChoices):
    NONE = "none", "None"
    TRAMPLING = "trampling", "Trampling"
    VEHICLE_TRACKS = "vehicle_tracks", "Vehicle tracks"
    FIRE = "fire", "Fire"
    EROSION = "erosion", "Erosion"
    DUMPING = "dumping", "Dumping"
    OTHER = "other", "Other"


class PlantResourceObservation(SyncableModel):
    """A plant record (T051): which plant, its role for butterflies, where it is (a point or the
    polygon of a patch) and in what state. Butterfly observations link to it as host or nectar
    plant, and a photo can belong to it.

    `patch_area_m2` is worked out by the server for a polygon when the client leaves it empty
    (`resources.services.save_plant_resource`). The geometry is a point or a valid polygon: the
    table's CHECKs and rule V08 say so.
    """

    project = models.ForeignKey(
        "projects.Project",
        on_delete=models.PROTECT,
        related_name="plant_resources",
        help_text="Project the plant record belongs to",
    )
    survey_visit = models.ForeignKey(
        "surveys.SurveyVisit",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="plant_resources",
        help_text="Visit the plant was recorded on; empty for a record made off a visit",
    )
    plant_taxon = models.ForeignKey(
        "catalogues.PlantTaxon",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        help_text="Plant as identified; empty for an unidentified plant (then notes are required)",
    )
    resource_type = models.CharField(
        max_length=20,
        choices=ResourceType.choices,
        help_text="Role for butterflies: larval_host, nectar_source, oviposition_plant, "
        "resting_plant or unknown_association",
    )
    observed_at = models.DateTimeField(help_text="When the plant was recorded (UTC, ISO 8601)")
    geometry = gis_models.GeometryField(
        srid=4326, help_text="Point, or the polygon of the patch, WGS 84"
    )
    abundance_class = models.CharField(
        max_length=10,
        choices=AbundanceClass.choices,
        blank=True,
        help_text="Individuals or flowering stems in the patch: 1, 2-10, 11-100, 101-1000 or >1000",
    )
    patch_area_m2 = models.DecimalField(
        max_digits=10,
        decimal_places=1,
        null=True,
        blank=True,
        help_text="Area of the patch polygon, square metres; worked out by the server when empty",
    )
    phenology_stage = models.CharField(
        max_length=12,
        choices=PhenologyStage.choices,
        blank=True,
        help_text="Stage of the plant: vegetative, budding, flowering, fruiting or senescent",
    )
    flowering_intensity = models.CharField(
        max_length=6,
        choices=Intensity.choices,
        blank=True,
        help_text="How much of the plant is in flower: none, low, medium or high",
    )
    eggs_present = models.BooleanField(
        null=True, blank=True, help_text="Butterfly eggs seen on the plant; empty when not checked"
    )
    larvae_present = models.BooleanField(
        null=True, blank=True, help_text="Larvae seen on the plant; empty when not checked"
    )
    feeding_damage_present = models.BooleanField(
        null=True, blank=True, help_text="Feeding damage seen on the plant; empty when not checked"
    )
    notes = models.TextField(
        blank=True, help_text="Free-text notes; required when the plant is not identified"
    )
    history = HistoricalRecords(table_name="historical_plant_resource_observation")

    class Meta:
        db_table = "plant_resource_observation"
        indexes = [models.Index(fields=["project", "observed_at"], name="plant_res_proj_idx")]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(resource_type__in=ResourceType.values),
                name="plant_res_type_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(abundance_class__in=[*AbundanceClass.values, ""]),
                name="plant_res_abund_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(phenology_stage__in=[*PhenologyStage.values, ""]),
                name="plant_res_pheno_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(flowering_intensity__in=[*Intensity.values, ""]),
                name="plant_res_flower_valid",
            ),
        ]
        # The geometry type and validity CHECKs (plant_res_geom_type, plant_res_geom_valid) call
        # PostGIS functions, so they are added by RunSQL in the first migration (D-086).

    def __str__(self):
        name = self.plant_taxon.scientific_name if self.plant_taxon_id else "Unidentified plant"
        return f"{name} @ {self.observed_at:%Y-%m-%d}"


class HabitatFeature(SyncableModel):
    """A habitat feature (T053): habitat type, management, vegetation structure and disturbance of
    a point, a line or a polygon. T054 builds the phone screens; T091 (Phase 2) later intersects
    the polygons with trajectories.

    The geometry is a point, a line or a valid polygon: the table's CHECKs and rule V08 say so.
    """

    project = models.ForeignKey(
        "projects.Project",
        on_delete=models.PROTECT,
        related_name="habitat_features",
        help_text="Project the habitat feature belongs to",
    )
    survey_visit = models.ForeignKey(
        "surveys.SurveyVisit",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="habitat_features",
        help_text="Visit the feature was recorded on; empty for a record made off a visit",
    )
    habitat_type = models.ForeignKey(
        "catalogues.HabitatType",
        on_delete=models.PROTECT,
        help_text="Habitat type (codelist)",
    )
    management_type = models.ForeignKey(
        "catalogues.ManagementType",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        help_text="Management type (codelist); empty when not recorded",
    )
    observed_at = models.DateTimeField(help_text="When the feature was recorded (UTC, ISO 8601)")
    geometry = gis_models.GeometryField(
        srid=4326, help_text="Point, line or polygon of the feature, WGS 84"
    )
    vegetation_height_cm = models.PositiveSmallIntegerField(
        null=True, blank=True, help_text="Vegetation height in centimetres; empty when not measured"
    )
    shrub_cover_pct = models.PositiveSmallIntegerField(
        null=True, blank=True, help_text="Shrub cover, percent (0-100); empty when not estimated"
    )
    tree_cover_pct = models.PositiveSmallIntegerField(
        null=True, blank=True, help_text="Tree cover, percent (0-100); empty when not estimated"
    )
    bare_ground_pct = models.PositiveSmallIntegerField(
        null=True, blank=True, help_text="Bare ground, percent (0-100); empty when not estimated"
    )
    flower_abundance_class = models.CharField(
        max_length=6,
        choices=Intensity.choices,
        blank=True,
        help_text="Abundance of flowers: none, low, medium or high",
    )
    grazing_intensity = models.CharField(
        max_length=6,
        choices=Intensity.choices,
        blank=True,
        help_text="Grazing intensity: none, low, medium or high",
    )
    mowing_status = models.CharField(
        max_length=20,
        choices=MowingStatus.choices,
        blank=True,
        help_text="Mowing: unmown, recently_mown, mown_this_season or unknown",
    )
    disturbance_type = models.CharField(
        max_length=15,
        choices=Disturbance.choices,
        blank=True,
        help_text="Disturbance: none, trampling, vehicle_tracks, fire, erosion, dumping or other",
    )
    notes = models.TextField(blank=True, help_text="Free-text notes")
    history = HistoricalRecords(table_name="historical_habitat_feature")

    class Meta:
        db_table = "habitat_feature"
        indexes = [models.Index(fields=["project", "observed_at"], name="habitat_feat_proj_idx")]
        constraints = [
            models.CheckConstraint(
                condition=(
                    (models.Q(shrub_cover_pct__isnull=True) | models.Q(shrub_cover_pct__lte=100))
                    & (models.Q(tree_cover_pct__isnull=True) | models.Q(tree_cover_pct__lte=100))
                    & (models.Q(bare_ground_pct__isnull=True) | models.Q(bare_ground_pct__lte=100))
                ),
                name="habitat_pct_ok",
            ),
            models.CheckConstraint(
                condition=models.Q(flower_abundance_class__in=[*Intensity.values, ""]),
                name="habitat_flower_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(grazing_intensity__in=[*Intensity.values, ""]),
                name="habitat_grazing_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(mowing_status__in=[*MowingStatus.values, ""]),
                name="habitat_mowing_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(disturbance_type__in=[*Disturbance.values, ""]),
                name="habitat_disturbance_valid",
            ),
        ]
        # The geometry type and validity CHECKs (habitat_geom_type, habitat_geom_valid) call
        # PostGIS functions, so they are added by RunSQL in the migration (D-088).

    def __str__(self):
        return f"{self.habitat_type} @ {self.observed_at:%Y-%m-%d}"
