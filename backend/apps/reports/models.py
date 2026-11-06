"""Unmanaged models over the indicator views (T061, D-099).

The views are created in `0001_initial`; the tables are never written. Django needs a
single-column primary key, so each view has a synthetic `row_id`.
"""

from django.db import models


def _fk(to, help_text):
    # No database constraint (a view has none) and no reverse accessor; the link lets the admin
    # show names and filter on them.
    return models.ForeignKey(
        to,
        on_delete=models.DO_NOTHING,
        db_constraint=False,
        related_name="+",
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
