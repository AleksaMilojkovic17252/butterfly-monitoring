from django.conf import settings
from django.contrib.gis.db import models as gis_models
from django.contrib.postgres.fields import ArrayField
from django.contrib.postgres.indexes import GinIndex
from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel


class Confidence(models.TextChoices):
    CONFIRMED_IN_FIELD = "confirmed_in_field", "Confirmed in the field"
    PROBABLE = "probable", "Probable"
    PHOTO_REQUIRED = "photo_required", "Photo required"
    GENUS_ONLY = "genus_only", "Genus only"
    SPECIES_GROUP = "species_group", "Species group"
    UNKNOWN = "unknown", "Unknown"
    EXPERT_REVIEW_REQUIRED = "expert_review_required", "Expert review required"


class Sex(models.TextChoices):
    MALE = "male", "Male"
    FEMALE = "female", "Female"
    MIXED = "mixed", "Mixed"
    UNKNOWN = "unknown", "Unknown"
    NOT_APPLICABLE = "not_applicable", "Not applicable"


class LifeStage(models.TextChoices):
    EGG = "egg", "Egg"
    LARVA = "larva", "Larva"
    PUPA = "pupa", "Pupa"
    ADULT = "adult", "Adult"
    UNKNOWN = "unknown", "Unknown"


class Behaviour(models.TextChoices):
    FLYING = "flying", "Flying"
    RESTING = "resting", "Resting"
    BASKING = "basking", "Basking"
    NECTARING = "nectaring", "Nectaring"
    COURTSHIP = "courtship", "Courtship"
    MATING = "mating", "Mating"
    TERRITORIAL = "territorial", "Territorial"
    OVIPOSITION = "oviposition", "Oviposition"
    MUD_PUDDLING = "mud_puddling", "Mud-puddling"
    FEEDING_ON_FRUIT = "feeding_on_fruit", "Feeding on fruit"
    FEEDING_ON_SAP = "feeding_on_sap", "Feeding on sap"
    LARVAL_FEEDING = "larval_feeding", "Larval feeding"
    OTHER = "other", "Other"
    UNKNOWN = "unknown", "Unknown"


class ObservationSource(models.TextChoices):
    TRANSECT = "transect", "Transect"
    INCIDENTAL = "incidental", "Incidental"
    FOCAL_FOLLOW = "focal_follow", "Focal follow"  # used from Phase 2
    LARVAL_SEARCH = "larval_search", "Larval search"
    HOST_PLANT_SEARCH = "host_plant_search", "Host plant search"


class ValidationStatus(models.TextChoices):
    NOT_REQUIRED = "not_required", "Not required"
    PENDING = "pending", "Pending"
    CONFIRMED = "confirmed", "Confirmed"
    UNCONFIRMED = "unconfirmed", "Unconfirmed"
    UNDETERMINABLE = "undeterminable", "Undeterminable"


class ButterflyObservation(SyncableModel):
    """What was seen, how many, where, when, how sure, and in which context (T044).

    `photo_count` is not a column: it is computed (`observations.services.photo_count`) once
    photos exist (T049). `host_plant_record` and `nectar_plant_record` are added in T051. The
    `validation_*` fields and `quality_flags` belong to the server (T055-T057); a client never
    sets them.
    """

    project = models.ForeignKey(
        "projects.Project", on_delete=models.PROTECT, related_name="observations"
    )
    survey_visit = models.ForeignKey(
        "surveys.SurveyVisit",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="observations",
    )
    transect_section = models.ForeignKey(
        "transects.TransectSection",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="observations",
    )
    observed_at = models.DateTimeField()
    taxon = models.ForeignKey(
        "catalogues.Taxon", on_delete=models.PROTECT, related_name="observations"
    )
    count = models.PositiveIntegerField(default=1)
    geometry = gis_models.PointField(srid=4326)
    location_accuracy_m = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)
    identification_confidence = models.CharField(
        max_length=30, choices=Confidence.choices, default=Confidence.CONFIRMED_IN_FIELD
    )
    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="observations"
    )
    sex = models.CharField(max_length=15, choices=Sex.choices, default=Sex.UNKNOWN)
    life_stage = models.CharField(max_length=10, choices=LifeStage.choices, default=LifeStage.ADULT)
    behaviour = ArrayField(
        models.CharField(max_length=20, choices=Behaviour.choices), default=list, blank=True
    )
    microhabitat = models.CharField(max_length=100, blank=True)
    flight_direction_deg = models.PositiveSmallIntegerField(null=True, blank=True)
    notes = models.TextField(blank=True)
    source = models.CharField(
        max_length=20, choices=ObservationSource.choices, default=ObservationSource.TRANSECT
    )
    validation_status = models.CharField(
        max_length=15, choices=ValidationStatus.choices, default=ValidationStatus.NOT_REQUIRED
    )
    validated_taxon = models.ForeignKey(
        "catalogues.Taxon", on_delete=models.PROTECT, null=True, blank=True, related_name="+"
    )
    validated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True, related_name="+"
    )
    validated_at = models.DateTimeField(null=True, blank=True)
    validation_comment = models.TextField(blank=True)
    quality_flags = ArrayField(models.CharField(max_length=40), default=list, blank=True)  # T056
    history = HistoricalRecords(table_name="historical_butterfly_observation")

    class Meta:
        db_table = "butterfly_observation"
        indexes = [
            models.Index(fields=["project", "observed_at"], name="butterfly_obs_proj_idx"),
            models.Index(fields=["taxon"], name="butterfly_obs_taxon_idx"),
            models.Index(fields=["survey_visit"], name="butterfly_obs_visit_idx"),
            models.Index(fields=["validation_status"], name="butterfly_obs_valid_idx"),
            GinIndex(fields=["quality_flags"], name="butterfly_obs_flags_gin"),
        ]
        constraints = [
            models.CheckConstraint(condition=models.Q(count__gte=1), name="obs_count_positive"),
            models.CheckConstraint(
                condition=models.Q(identification_confidence__in=Confidence.values),
                name="obs_confidence_valid",
            ),
            models.CheckConstraint(condition=models.Q(sex__in=Sex.values), name="obs_sex_valid"),
            models.CheckConstraint(
                condition=models.Q(life_stage__in=LifeStage.values), name="obs_life_stage_valid"
            ),
            models.CheckConstraint(
                condition=models.Q(source__in=ObservationSource.values), name="obs_source_valid"
            ),
            models.CheckConstraint(
                condition=models.Q(validation_status__in=ValidationStatus.values),
                name="obs_validation_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(behaviour__contained_by=Behaviour.values),
                name="obs_behaviour_valid",
            ),
            models.CheckConstraint(
                condition=~models.Q(source=ObservationSource.TRANSECT)
                | models.Q(survey_visit__isnull=False),
                name="obs_transect_needs_visit",
            ),
            models.CheckConstraint(
                condition=models.Q(flight_direction_deg__isnull=True)
                | models.Q(flight_direction_deg__lt=360),
                name="obs_flight_dir_ok",
            ),
        ]

    def __str__(self):
        return f"{self.taxon.scientific_name} × {self.count} @ {self.observed_at:%Y-%m-%d %H:%M}"
