"""Unmanaged models over the indicator views (T061, D-099).

The views are created in `0001_initial`; the tables are never written. Django needs a
single-column primary key, so each view has a synthetic `row_id`.
"""

from django.contrib.gis.db import models as gis_models
from django.db import models


def _fk(to, help_text, null=False):
    # No database constraint (a view has none) and no reverse accessor; the link lets the admin
    # show names and filter on them.
    return models.ForeignKey(
        to,
        on_delete=models.DO_NOTHING,
        db_constraint=False,
        related_name="+",
        null=null,
        help_text=help_text,
    )


class TransectIndicators(models.Model):
    row_id = models.CharField(
        max_length=80, primary_key=True, help_text="Transect id and year, joined with a colon"
    )
    project = _fk("projects.Project", "Project the transect belongs to")
    transect = _fk("transects.Transect", "Transect the figures are for")
    transect_code = models.CharField(max_length=20, help_text="Short transect code")
    year = models.IntegerField(help_text="Calendar year of the visits, in the project's time zone")
    visits_completed = models.IntegerField(help_text="Finished visits (completed or later)")
    true_zero_visits = models.IntegerField(
        help_text="Finished visits confirmed to have seen no butterflies"
    )
    valid_visits = models.IntegerField(
        help_text="Finished visits that meet the valid-visit rule (weather, coverage)"
    )
    total_hours = models.DecimalField(
        max_digits=8, decimal_places=2, help_text="Total walking time, hours"
    )
    total_km = models.DecimalField(
        max_digits=8, decimal_places=2, help_text="Total distance walked, kilometres"
    )
    species_count = models.IntegerField(help_text="Distinct species on transect records")
    individuals = models.IntegerField(help_text="Individuals counted on transect records")
    observations = models.IntegerField(help_text="Transect observation records")
    confirmed_obs = models.IntegerField(help_text="Transect records confirmed by a validator")
    to_review_obs = models.IntegerField(help_text="Transect records still pending validation")
    target_visits = models.IntegerField(help_text="Target visits per season (project protocol)")
    individuals_per_km = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        help_text="Individuals per kilometre walked; empty when no distance was walked",
    )
    individuals_per_hour = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        help_text="Individuals per hour walked; empty when no time was recorded",
    )

    class Meta:
        managed = False
        db_table = "report_transect_indicators"
        verbose_name = "transect indicators"
        verbose_name_plural = "transect indicators"


class SpeciesPhenology(models.Model):
    row_id = models.CharField(
        max_length=120,
        primary_key=True,
        help_text="Project, taxon and ISO year-week, joined with colons",
    )
    project = _fk("projects.Project", "Project of the records")
    taxon = _fk("catalogues.Taxon", "Species (the validated one when there is one)")
    year = models.IntegerField(help_text="ISO year of the week, in the project's time zone")
    iso_week = models.IntegerField(help_text="ISO week number (1-53)")
    individuals = models.IntegerField(help_text="Individuals counted in the week")
    observations = models.IntegerField(help_text="Observation records in the week")
    first_date = models.DateField(help_text="First day with a record in the week (local date)")
    last_date = models.DateField(help_text="Last day with a record in the week (local date)")

    class Meta:
        managed = False
        db_table = "report_species_phenology"
        verbose_name = "species phenology"
        verbose_name_plural = "species phenology"


class BehaviourCounts(models.Model):
    row_id = models.CharField(
        max_length=120, primary_key=True, help_text="Project, year and behaviour, joined"
    )
    project = _fk("projects.Project", "Project of the records")
    year = models.IntegerField(help_text="Calendar year, in the project's time zone")
    behaviour = models.CharField(
        max_length=40,
        help_text="Behaviour value; 'reproductive' counts courtship, mating, oviposition "
        "and egg, larva or pupa records",
    )
    records = models.IntegerField(help_text="Observation records with this behaviour")

    class Meta:
        managed = False
        db_table = "report_behaviour_counts"
        verbose_name = "behaviour counts"
        verbose_name_plural = "behaviour counts"


class TransectProfile(models.Model):
    row_id = models.CharField(
        max_length=120,
        primary_key=True,
        help_text="Transect id, year and bin start, joined with colons",
    )
    project = _fk("projects.Project", "Project the transect belongs to")
    transect = _fk("transects.Transect", "Transect the figures are for")
    transect_code = models.CharField(max_length=20, help_text="Short transect code")
    year = models.IntegerField(
        help_text="Calendar year of the visits, in the project's time zone; a year with no "
        "finished visit has no rows (not surveyed), unlike a surveyed bin with no records (zeros)"
    )
    bin_m = models.IntegerField(help_text="Bin width, metres along the transect")
    bin_start_m = models.IntegerField(help_text="Metres along the transect where the bin starts")
    bin_end_m = models.DecimalField(
        max_digits=8,
        decimal_places=1,
        help_text="Metres along the transect where the bin ends (the last bin stops at the end)",
    )
    observations = models.IntegerField(help_text="Transect observation records in the bin")
    individuals = models.IntegerField(help_text="Individuals counted in the bin")
    species = models.IntegerField(help_text="Distinct species recorded in the bin")

    class Meta:
        managed = False
        db_table = "report_transect_profile"
        verbose_name = "transect profile"
        verbose_name_plural = "transect profile"


class HabitatRichness(models.Model):
    """Q1 (T101, D-110): project x habitat type x year."""

    row_id = models.CharField(
        max_length=120,
        primary_key=True,
        help_text="Project, habitat type code and year, joined with colons",
    )
    project = _fk("projects.Project", "Project of the records")
    habitat_type = _fk("catalogues.HabitatType", "Habitat type; empty for unknown", null=True)
    habitat_code = models.CharField(
        max_length=30, help_text="Habitat type code; 'unknown' when a record has no habitat"
    )
    year = models.IntegerField(help_text="Calendar year, in the project's time zone")
    sections = models.IntegerField(
        help_text="Live transect sections of this habitat type on transects with a valid visit "
        "that year"
    )
    section_km = models.DecimalField(
        max_digits=12,
        decimal_places=3,
        help_text="Total length of those sections, kilometres (UTM)",
    )
    valid_visits = models.IntegerField(
        help_text="Valid visits whose transect has a section of this habitat type"
    )
    effort_km = models.DecimalField(
        max_digits=12,
        decimal_places=3,
        help_text="Walking effort in this habitat type: the section lengths summed over the "
        "valid visits, kilometres",
    )
    species = models.IntegerField(help_text="Distinct species over transect and incidental records")
    transect_species = models.IntegerField(help_text="Distinct species on transect records only")
    transect_records = models.IntegerField(help_text="Transect records of valid visits")
    transect_individuals = models.IntegerField(help_text="Individuals on transect records")
    incidental_records = models.IntegerField(
        help_text="Records of other sources, in a polygon of this habitat type"
    )
    incidental_individuals = models.IntegerField(help_text="Individuals on those records")
    individuals = models.IntegerField(help_text="Individuals on transect and incidental records")
    individuals_per_km = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        help_text="Transect individuals per kilometre of effort; empty when there is no effort "
        "(incidental records have no effort)",
    )

    class Meta:
        managed = False
        db_table = "report_habitat_richness"
        verbose_name = "habitat richness"
        verbose_name_plural = "habitat richness"


class SpecialistHostPlants(models.Model):
    """Q3 (T101, D-110): transect section x year."""

    row_id = models.CharField(
        max_length=80, primary_key=True, help_text="Section id and year, joined with a colon"
    )
    project = _fk("projects.Project", "Project the transect belongs to")
    transect = _fk("transects.Transect", "Transect of the section")
    section = _fk("transects.TransectSection", "Transect section the figures are for")
    transect_code = models.CharField(max_length=20, help_text="Short transect code")
    section_code = models.CharField(max_length=20, help_text="Section code, unique in the transect")
    year = models.IntegerField(
        help_text="Calendar year of the valid visits, in the project's time zone"
    )
    radius_m = models.IntegerField(
        help_text="Distance within which a host-plant patch counts, metres"
    )
    valid_visits = models.IntegerField(help_text="Valid visits of the transect that year")
    specialist_species_individuals = models.IntegerField(
        help_text="Individuals of specialist species on transect records of this section"
    )
    specialist_species = models.IntegerField(
        help_text="Distinct specialist species on those records"
    )
    specialist_species_per_visit = models.DecimalField(
        max_digits=12, decimal_places=2, help_text="Specialist individuals per valid visit"
    )
    host_patches = models.IntegerField(
        help_text="Larval host-plant patches (of any specialist's host plant) within the radius, "
        "same year"
    )
    host_abundance_mid = models.DecimalField(
        max_digits=12,
        decimal_places=1,
        help_text="Sum of the abundance-class midpoints of those patches (>1000 counts as 1000; "
        "no class counts 0)",
    )

    class Meta:
        managed = False
        db_table = "report_specialist_host_plants"
        verbose_name = "specialists and host plants"
        verbose_name_plural = "specialists and host plants"


class ReproductiveMicrohabitat(models.Model):
    """Q4 (T101, D-110): project x habitat type, with Jacobs' selection index."""

    row_id = models.CharField(
        max_length=120, primary_key=True, help_text="Project and habitat type code, joined"
    )
    project = _fk("projects.Project", "Project of the polygons")
    habitat_type = _fk("catalogues.HabitatType", "Habitat type of the polygons")
    habitat_code = models.CharField(max_length=30, help_text="Habitat type code")
    polygons = models.IntegerField(help_text="Live polygon features of this habitat type")
    area_m2 = models.DecimalField(
        max_digits=14,
        decimal_places=1,
        help_text="Area of the union of those polygons, square metres (UTM)",
    )
    repro_records = models.IntegerField(
        help_text="Reproductive records inside polygons of this type"
    )
    project_repro_records = models.IntegerField(
        help_text="Reproductive records inside polygons of any type in the project"
    )
    record_share = models.DecimalField(
        max_digits=8,
        decimal_places=3,
        null=True,
        help_text="Share of the project's reproductive records (in polygons) that are in this "
        "type (r)",
    )
    area_share = models.DecimalField(
        max_digits=8,
        decimal_places=3,
        null=True,
        help_text="Share of the project's polygon area that is this type (p)",
    )
    jacobs_d = models.DecimalField(
        max_digits=8,
        decimal_places=3,
        null=True,
        help_text="Jacobs' selection index (r - p) / (r + p - 2rp): +1 selected, -1 avoided; "
        "empty without reproductive records in polygons",
    )

    class Meta:
        managed = False
        db_table = "report_reproductive_microhabitat"
        verbose_name = "reproductive microhabitat"
        verbose_name_plural = "reproductive microhabitat"


class ObservationHexgrid(models.Model):
    """Q6 (T101, D-110): the `geo.observation_hexgrid` view, as the admin sees it."""

    id = models.CharField(
        max_length=100, primary_key=True, help_text="Project id and hexagon cell, joined"
    )
    project = _fk("projects.Project", "Project of the records")
    project_name = models.CharField(max_length=200, help_text="Project name")
    hex_size_m = models.IntegerField(help_text="Hexagon edge length, metres")
    observations = models.IntegerField(help_text="Observation records in the hexagon")
    individuals = models.IntegerField(help_text="Individuals counted in the hexagon")
    species = models.IntegerField(help_text="Distinct species recorded in the hexagon")
    nectaring_records = models.IntegerField(help_text="Records with the nectaring behaviour")
    reproductive_records = models.IntegerField(help_text="Reproductive records (T061 definition)")
    geometry = gis_models.PolygonField(srid=4326, help_text="The hexagon, WGS 84")

    class Meta:
        managed = False
        db_table = 'geo"."observation_hexgrid'
        verbose_name = "observation hexagon"
        verbose_name_plural = "observation hexagons"
