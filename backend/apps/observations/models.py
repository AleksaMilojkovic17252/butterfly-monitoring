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

    `photo_count` is not a column: it is computed (`observations.services.photo_count`).
    `host_plant_record` and `nectar_plant_record` are added in T051. The
    `validation_*` fields and `quality_flags` belong to the server (T055-T057); a client never
    sets them.
    """

    project = models.ForeignKey(
        "projects.Project",
        on_delete=models.PROTECT,
        related_name="observations",
        help_text="Project the observation belongs to",
    )
    survey_visit = models.ForeignKey(
        "surveys.SurveyVisit",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="observations",
        help_text="Visit the observation was made on; empty for incidental records",
    )
    transect_section = models.ForeignKey(
        "transects.TransectSection",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="observations",
        help_text="Transect section the observation falls in, when known",
    )
    observed_at = models.DateTimeField(help_text="When the butterfly was seen (UTC, ISO 8601)")
    taxon = models.ForeignKey(
        "catalogues.Taxon",
        on_delete=models.PROTECT,
        related_name="observations",
        help_text="Taxon as identified by the observer",
    )
    count = models.PositiveIntegerField(default=1, help_text="Number of individuals seen")
    geometry = gis_models.PointField(srid=4326, help_text="Where it was seen, WGS 84")
    location_accuracy_m = models.DecimalField(
        max_digits=6,
        decimal_places=1,
        null=True,
        blank=True,
        help_text="Horizontal accuracy of the position, metres",
    )
    identification_confidence = models.CharField(
        max_length=30,
        choices=Confidence.choices,
        default=Confidence.CONFIRMED_IN_FIELD,
        help_text="Observer's confidence in the identification, e.g. confirmed_in_field, probable",
    )
    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="observations",
        help_text="User who recorded the observation",
    )
    sex = models.CharField(
        max_length=15,
        choices=Sex.choices,
        default=Sex.UNKNOWN,
        help_text="Sex: male, female, mixed, unknown or not_applicable",
    )
    life_stage = models.CharField(
        max_length=10,
        choices=LifeStage.choices,
        default=LifeStage.ADULT,
        help_text="Life stage: egg, larva, pupa, adult or unknown",
    )
    behaviour = ArrayField(
        models.CharField(max_length=20, choices=Behaviour.choices),
        default=list,
        blank=True,
        help_text="Behaviours seen, joined with ';' in CSV, e.g. flying;nectaring",
    )
    microhabitat = models.CharField(
        max_length=100, blank=True, help_text="Short free-text description of the microhabitat"
    )
    flight_direction_deg = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        help_text="Flight direction, degrees clockwise from north (0-359)",
    )
    notes = models.TextField(blank=True, help_text="Free-text notes on the observation")
    source = models.CharField(
        max_length=20,
        choices=ObservationSource.choices,
        default=ObservationSource.TRANSECT,
        help_text="How the record was made: transect, incidental, larval_search, ...",
    )
    validation_status = models.CharField(
        max_length=15,
        choices=ValidationStatus.choices,
        default=ValidationStatus.NOT_REQUIRED,
        help_text="Expert validation: not_required, pending, confirmed, unconfirmed or "
        "undeterminable",
    )
    validated_taxon = models.ForeignKey(
        "catalogues.Taxon",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        help_text="Taxon set by the validator when it differs from the observer's",
    )
    validated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        help_text="User who validated the observation",
    )
    validated_at = models.DateTimeField(
        null=True, blank=True, help_text="When it was validated (UTC, ISO 8601)"
    )
    validation_comment = models.TextField(blank=True, help_text="Validator's comment")
    # Set by the server's quality checks (T056).
    quality_flags = ArrayField(
        models.CharField(max_length=40),
        default=list,
        blank=True,
        help_text="Quality flags raised by the server's checks, joined with ';' in CSV",
    )
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


# Photo limits (T049). The services and the CHECK constraints both read them.
MAX_PHOTO_BYTES = 15 * 1024 * 1024
PHOTO_MIME_TYPES = {"image/jpeg": "jpg", "image/png": "png"}  # mime type -> file extension


class UploadStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    UPLOADED = "uploaded", "Uploaded"


class Photo(SyncableModel):
    """A photo's metadata row (T049). It syncs like any record; the bytes follow in the three
    upload steps (`observations.services.init_upload`, `store_content`, `complete_upload`).

    The phone owns the metadata, including `sha256`, `mime_type` and `file_size`, which cannot
    change after the create. The server owns `storage_key`, `upload_status`, `uploaded_at` and
    `metadata_json` (`server_owned` in the sync registry). Photos with the same `sha256` share
    one stored object. A plant record becomes the second possible parent in T051, with a CHECK
    that a photo has exactly one; until then the observation is required by the service.
    """

    observation = models.ForeignKey(
        ButterflyObservation,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="photos",
    )
    local_path = models.CharField(max_length=500, blank=True)  # informational, from the phone
    storage_key = models.CharField(max_length=200, blank=True)
    mime_type = models.CharField(max_length=50)
    file_size = models.PositiveIntegerField()
    sha256 = models.CharField(max_length=64)
    width = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    captured_at = models.DateTimeField()
    uploaded_at = models.DateTimeField(null=True, blank=True)
    upload_status = models.CharField(
        max_length=10, choices=UploadStatus.choices, default=UploadStatus.PENDING
    )
    is_primary = models.BooleanField(default=False)
    metadata_json = models.JSONField(default=dict, blank=True)
    history = HistoricalRecords(table_name="historical_photo")

    class Meta:
        db_table = "photo"
        indexes = [
            models.Index(fields=["sha256"], name="photo_sha256_idx"),
            models.Index(fields=["upload_status"], name="photo_upload_status_idx"),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(sha256__regex=r"^[0-9a-f]{64}$"), name="photo_sha256_format"
            ),
            models.CheckConstraint(
                condition=models.Q(mime_type__in=list(PHOTO_MIME_TYPES)), name="photo_mime_valid"
            ),
            models.CheckConstraint(
                condition=models.Q(file_size__lte=MAX_PHOTO_BYTES), name="photo_size_max"
            ),
            models.CheckConstraint(
                condition=models.Q(upload_status__in=UploadStatus.values),
                name="photo_upload_status_valid",
            ),
            models.CheckConstraint(
                condition=~models.Q(upload_status=UploadStatus.UPLOADED)
                | ~models.Q(storage_key=""),
                name="photo_uploaded_has_key",
            ),
            models.UniqueConstraint(
                fields=["observation"],
                condition=models.Q(is_primary=True, deleted_at__isnull=True),
                name="photo_one_primary_per_observation",
            ),
        ]

    def __str__(self):
        return f"{self.sha256[:12]} ({self.upload_status})"
