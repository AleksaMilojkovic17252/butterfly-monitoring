from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel


class TaxonListVersion(SyncableModel):
    """One release of the butterfly list. Exactly one release is current (partial unique index)."""

    version_label = models.CharField(max_length=30, unique=True)  # e.g. "2026.1"
    source = models.CharField(max_length=200)  # e.g. "GBIF Backbone, Serbia, reviewed"
    published_at = models.DateTimeField()
    is_current = models.BooleanField(default=False)
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "taxon_list_version"
        constraints = [
            models.UniqueConstraint(
                fields=["is_current"],
                condition=models.Q(is_current=True),
                name="taxon_list_version_one_current",
            )
        ]

    def __str__(self):
        return self.version_label

    def validate_constraints(self, exclude=None):
        # Forms would reject making a second release current before the old flag is cleared.
        # services.clear_other_current does that clearing; the DB index still guards the rule.
        super().validate_constraints(exclude={*(exclude or ()), "is_current"})


class TaxonRank(models.TextChoices):
    FAMILY = "family", "Family"
    GENUS = "genus", "Genus"
    SPECIES_GROUP = "species_group", "Species group"
    SPECIES = "species", "Species"
    SUBSPECIES = "subspecies", "Subspecies"


class TaxonSource(models.TextChoices):
    GBIF = "gbif", "GBIF"
    MANUAL = "manual", "Manual"


class Taxon(SyncableModel):
    """A butterfly taxon as it stood in one list release.

    A rename or synonymisation never edits the name: it adds a new row and retires the old one
    (`catalogues.services.retire_and_replace_taxon`), so observations keep pointing at the row
    that was used when they were recorded.
    """

    scientific_name = models.CharField(max_length=200)
    author = models.CharField(max_length=200, blank=True)
    rank = models.CharField(max_length=20, choices=TaxonRank.choices, default=TaxonRank.SPECIES)
    genus = models.CharField(max_length=100, blank=True)
    family = models.CharField(max_length=100, blank=True)
    vernacular_name_sr = models.CharField(max_length=200, blank=True)
    vernacular_name_en = models.CharField(max_length=200, blank=True)
    accepted_name = models.ForeignKey(
        "self", on_delete=models.PROTECT, null=True, blank=True, related_name="synonyms"
    )
    taxon_source = models.CharField(
        max_length=10, choices=TaxonSource.choices, default=TaxonSource.GBIF
    )
    taxon_source_id = models.CharField(max_length=50, blank=True)
    introduced_in = models.ForeignKey(
        TaxonListVersion, on_delete=models.PROTECT, related_name="introduced_taxa"
    )
    retired_in = models.ForeignKey(
        TaxonListVersion,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="retired_taxa",
    )
    active = models.BooleanField(default=True)
    photo_required = models.BooleanField(default=False)  # rule W01 (T055)
    identification_notes = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_taxon")

    class Meta:
        db_table = "taxon"
        constraints = [
            models.UniqueConstraint(
                fields=["scientific_name", "rank", "introduced_in"], name="taxon_unique_name"
            ),
            models.CheckConstraint(
                condition=models.Q(rank__in=TaxonRank.values), name="taxon_rank_valid"
            ),
            models.CheckConstraint(
                condition=models.Q(taxon_source__in=TaxonSource.values), name="taxon_source_valid"
            ),
            models.CheckConstraint(
                condition=~models.Q(accepted_name=models.F("id")), name="taxon_not_self_synonym"
            ),
        ]
        indexes = [
            models.Index(fields=["scientific_name"]),
            models.Index(fields=["family", "genus"]),
        ]

    def __str__(self):
        return self.scientific_name


class PlantTaxon(SyncableModel):
    """A plant for host and nectar records (T051). Deactivated plants stay on old records."""

    scientific_name = models.CharField(max_length=200, unique=True)
    family = models.CharField(max_length=100, blank=True)
    vernacular_name = models.CharField(max_length=200, blank=True)  # Serbian
    vernacular_name_en = models.CharField(max_length=200, blank=True)
    taxon_source = models.CharField(
        max_length=10, choices=TaxonSource.choices, default=TaxonSource.GBIF
    )
    taxon_source_id = models.CharField(max_length=50, blank=True)
    active = models.BooleanField(default=True)
    history = HistoricalRecords(table_name="historical_plant_taxon")

    class Meta:
        db_table = "plant_taxon"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(taxon_source__in=TaxonSource.values),
                name="plant_taxon_source_valid",
            ),
        ]

    def __str__(self):
        return self.scientific_name


class Codelist(SyncableModel):
    """An admin-editable value list. Deactivating a value hides it from pickers only."""

    code = models.SlugField(max_length=30, unique=True)
    name_en = models.CharField(max_length=150)
    name_sr = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    sort_order = models.PositiveSmallIntegerField(default=100)
    active = models.BooleanField(default=True)

    class Meta:
        abstract = True
        ordering = ["sort_order", "name_en"]

    def __str__(self):
        return self.name_en


class HabitatType(Codelist):
    eunis_code = models.CharField(max_length=20, blank=True)
    history = HistoricalRecords(table_name="historical_habitat_type")

    class Meta(Codelist.Meta):
        db_table = "habitat_type"


class ManagementType(Codelist):
    history = HistoricalRecords(table_name="historical_management_type")

    class Meta(Codelist.Meta):
        db_table = "management_type"
