"""What the exports contain (T064): one `Dataset` per table, each a queryset plus a column list.

A column's description comes from the model field's `help_text` unless the column is computed,
comes from another table, or is one of the common `SyncableModel` columns; those carry their own
description here. `metadata.json` is built from these descriptions.
"""

from collections.abc import Callable
from dataclasses import dataclass

from django.contrib.gis.db.models.functions import AsGeoJSON, AsWKT
from django.db.models import F, FloatField, Func, Q, Value
from django.db.models.functions import Coalesce

from apps.environment.models import EnvironmentalSnapshot
from apps.observations.models import ButterflyObservation
from apps.observations.services import observations_for
from apps.surveys.models import SurveyTrackPoint, SurveyVisit, visit_outcome
from apps.surveys.services import visits_for
from apps.transects.models import Transect, TransectSection
from apps.transects.services import GeodesicLength, sections_for, transects_for

# Datasets named in the ticket whose tables do not exist yet. They are added here when the
# ticket that builds the table is done.
DEFERRED = {
    "plant_resources": "T051",
    "habitat_features": "T053",
    "validation_history": "T058",
}

# The name of the hidden column that carries a row's geometry as a GeoJSON string.
GEOMETRY_KEY = "_geojson"


@dataclass(frozen=True)
class Column:
    """One exported column. `source` is a field path or an ORM expression."""

    name: str
    source: object
    description: str = ""


@dataclass(frozen=True)
class Dataset:
    name: str
    model: type
    queryset: Callable  # user -> the live rows that user may export
    columns: tuple
    time_field: str | None  # the field `from`/`to` filter on; None if dates do not apply
    project_fields: tuple  # paths to the project id, any of which may match
    geometry: str | None  # "point", "line" or None
    order_by: tuple
    geometry_columns: tuple = ()  # lon/lat or geometry_wkt: in CSV and JSON, not in GeoJSON
    post: Callable | None = None  # changes a row (a dict) after it is read

    @property
    def all_columns(self):
        return self.columns + self.geometry_columns

    def description(self, column):
        """The column's description, from the column itself or the model field's help_text."""
        if column.description:
            return column.description
        if not isinstance(column.source, str):
            return ""
        model = self.model
        found = None
        for part in column.source.split("__"):
            found = model._meta.get_field(part)
            model = found.related_model
        return str(found.help_text)


def _common(created=True):
    """The columns every synced table has; `SyncableModel` leaves them without help_text."""
    columns = [Column("id", "id", "Stable identifier of the record (UUID, set by the phone)")]
    if created:
        columns += [
            Column("created_at", "created_at", "When the record was created (UTC, ISO 8601)"),
            Column("updated_at", "updated_at", "When the record last changed (UTC, ISO 8601)"),
        ]
    return columns


def _point_columns():
    return (
        Column(
            "lon",
            Func(F("geometry"), function="ST_X", output_field=FloatField()),
            "Longitude, decimal degrees, WGS 84 (EPSG:4326)",
        ),
        Column(
            "lat",
            Func(F("geometry"), function="ST_Y", output_field=FloatField()),
            "Latitude, decimal degrees, WGS 84 (EPSG:4326)",
        ),
    )


def _line_columns():
    return (
        Column(
            "geometry_wkt",
            AsWKT("geometry"),
            "Line as WKT, WGS 84 (EPSG:4326), coordinates in lon lat order",
        ),
    )


def _outcome_post(row):
    """The visit outcome (D-069), through the one definition in `surveys.models`."""
    row["outcome"] = (
        visit_outcome(row["status"], row["cancel_reason"], row["zero_observation_confirmed"])
        or None
    )


VISIT_COLUMNS = tuple(
    _common(created=False)
    + [
        Column("project_id", "project_id"),
        Column("transect_id", "transect_id"),
        Column("transect_code", "transect__code", "Code of the transect that was walked"),
        Column("observer_id", "observer_id"),
        Column("protocol_version", "protocol_version"),
        Column("survey_method", "survey_method"),
        Column(
            "taxon_list_version",
            "project__taxon_list_version__version_label",
            "Butterfly list release the project uses, e.g. 2026.1",
        ),
        Column("status", "status"),
        Column(
            "outcome",
            Value(""),
            "What the visit came to: completed_with_records, true_zero, cancelled:<reason>; "
            "missing while the visit is a draft or in progress",
        ),
        Column("cancel_reason", "cancel_reason"),
        Column("started_at", "started_at"),
        Column("ended_at", "ended_at"),
        Column("duration_seconds", "duration_seconds"),
        Column("paused_seconds", "paused_seconds"),
        Column("distance_walked_m", "distance_walked_m"),
        Column("observer_count", "observer_count"),
        Column("observer_names", "observer_names"),
        Column("temperature_start_c", "temperature_start_c"),
        Column("temperature_end_c", "temperature_end_c"),
        Column("wind_beaufort_start", "wind_beaufort_start"),
        Column("wind_beaufort_end", "wind_beaufort_end"),
        Column("cloud_cover_start_pct", "cloud_cover_start_pct"),
        Column("cloud_cover_end_pct", "cloud_cover_end_pct"),
        Column("precipitation", "precipitation"),
        Column("weather_suitable", "weather_suitable"),
        Column("weather_missing_reason", "weather_missing_reason"),
        Column("zero_observation_confirmed", "zero_observation_confirmed"),
        Column("track_point_count", "track_point_count"),
        Column("battery_saver_used", "battery_saver_used"),
        Column("quality_flags", "quality_flags"),
        Column("locked_at", "locked_at"),
        Column("notes", "notes"),
        Column("created_at", "created_at", "When the record was created (UTC, ISO 8601)"),
        Column("updated_at", "updated_at", "When the record last changed (UTC, ISO 8601)"),
    ]
)

OBSERVATION_COLUMNS = tuple(
    _common(created=False)
    + [
        Column("project_id", "project_id"),
        Column("survey_visit_id", "survey_visit_id"),
        Column(
            "transect_id",
            Coalesce("survey_visit__transect_id", "transect_section__transect_id"),
            "Transect of the visit or section; missing for an incidental record off a transect",
        ),
        Column(
            "section_code",
            "transect_section__section_code",
            "Code of the transect section the observation falls in, when known",
        ),
        Column("observed_at", "observed_at"),
        Column("taxon_id", "taxon_id"),
        Column(
            "taxon_scientific_name", "taxon__scientific_name", "Taxon as the observer identified it"
        ),
        Column(
            "effective_taxon_id",
            Coalesce("validated_taxon_id", "taxon_id"),
            "Taxon to analyse: the validator's taxon if one was set, else the observer's",
        ),
        Column(
            "effective_taxon_scientific_name",
            Coalesce("validated_taxon__scientific_name", "taxon__scientific_name"),
            "Scientific name of the effective taxon",
        ),
        Column(
            "taxon_list_version",
            "project__taxon_list_version__version_label",
            "Butterfly list release the project uses, e.g. 2026.1",
        ),
        Column(
            "protocol_version",
            Coalesce("survey_visit__protocol_version", "project__protocol__protocol_version"),
            "Protocol version of the visit, or of the project for a record without a visit",
        ),
        Column("count", "count"),
        Column("location_accuracy_m", "location_accuracy_m"),
        Column("confidence", "identification_confidence"),
        Column("sex", "sex"),
        Column("life_stage", "life_stage"),
        Column("behaviour", "behaviour"),
        Column("microhabitat", "microhabitat"),
        Column("flight_direction_deg", "flight_direction_deg"),
        Column("source", "source"),
        Column("validation_status", "validation_status"),
        Column("validated_at", "validated_at"),
        Column("validation_comment", "validation_comment"),
        Column("recorded_by_id", "recorded_by_id"),
        Column("quality_flags", "quality_flags"),
        Column("notes", "notes"),
        Column("created_at", "created_at", "When the record was created (UTC, ISO 8601)"),
        Column("updated_at", "updated_at", "When the record last changed (UTC, ISO 8601)"),
    ]
)

TRANSECT_COLUMNS = tuple(
    _common(created=False)
    + [
        Column("project_id", "project_id"),
        Column("code", "code"),
        Column("name", "name"),
        Column("description", "description"),
        Column("target_length_m", "target_length_m"),
        Column(
            "length_m",
            GeodesicLength("geometry"),
            "Length of the line on the WGS 84 ellipsoid, metres",
        ),
        Column("habitat_summary", "habitat_summary"),
        Column("active", "active"),
        Column("created_at", "created_at", "When the record was created (UTC, ISO 8601)"),
        Column("updated_at", "updated_at", "When the record last changed (UTC, ISO 8601)"),
    ]
)

SECTION_COLUMNS = tuple(
    _common(created=False)
    + [
        Column("project_id", "transect__project_id", "Project the transect belongs to"),
        Column("transect_id", "transect_id"),
        Column("transect_code", "transect__code", "Code of the transect the section belongs to"),
        Column("section_code", "section_code"),
        Column("sequence_number", "sequence_number"),
        Column("habitat_type_code", "habitat_type__code", "Code of the habitat type list value"),
        Column(
            "management_type_code",
            "management_type__code",
            "Code of the management type list value",
        ),
        Column(
            "length_m",
            GeodesicLength("geometry"),
            "Length of the line on the WGS 84 ellipsoid, metres",
        ),
        Column("notes", "notes"),
        Column("created_at", "created_at", "When the record was created (UTC, ISO 8601)"),
        Column("updated_at", "updated_at", "When the record last changed (UTC, ISO 8601)"),
    ]
)

SNAPSHOT_COLUMNS = (
    Column("id", "id", "Stable identifier of the snapshot (UUID)"),
    Column(
        "project_id",
        Coalesce("survey_visit__project_id", "observation__project_id"),
        "Project of the visit or observation the snapshot belongs to",
    ),
    Column("survey_visit_id", "survey_visit_id"),
    Column("observation_id", "observation_id"),
    Column("source_type", "source_type"),
    Column("moment", "moment"),
    Column("source_uri", "source_uri"),
    Column("retrieved_at", "retrieved_at"),
    Column("phenomenon_time_start", "phenomenon_time_start"),
    Column("phenomenon_time_end", "phenomenon_time_end"),
    Column("temperature_c", "temperature_c"),
    Column("relative_humidity_pct", "relative_humidity_pct"),
    Column("wind_speed_m_s", "wind_speed_m_s"),
    Column("wind_direction_deg", "wind_direction_deg"),
    Column("cloud_cover_pct", "cloud_cover_pct"),
    Column("precipitation_mm", "precipitation_mm"),
    Column("solar_radiation_w_m2", "solar_radiation_w_m2"),
    Column("is_simulated", "is_simulated"),
    Column(
        "raw_payload_json",
        "raw_payload_json",
        "Source values kept as received, JSON; for manual rows the Beaufort force and the "
        "precipitation category",
    ),
)

TRACK_POINT_COLUMNS = tuple(
    _common(created=False)
    + [
        Column("survey_visit_id", "survey_visit_id"),
        Column("project_id", "survey_visit__project_id", "Project of the visit"),
        Column("sequence_number", "sequence_number"),
        Column("recorded_at", "recorded_at"),
        Column("accuracy_m", "accuracy_m"),
        Column("altitude_m", "altitude_m"),
        Column("speed_m_s", "speed_m_s"),
        Column("heading_deg", "heading_deg"),
        Column("provider", "provider"),
    ]
)


def _snapshots_for(user):
    return EnvironmentalSnapshot.objects.filter(
        Q(survey_visit__in=visits_for(user)) | Q(observation__in=observations_for(user))
    )


def _track_points_for(user):
    return SurveyTrackPoint.objects.alive().filter(survey_visit__in=visits_for(user))


DATASETS = {
    dataset.name: dataset
    for dataset in (
        Dataset(
            name="survey_visits",
            model=SurveyVisit,
            queryset=visits_for,
            columns=VISIT_COLUMNS,
            time_field="started_at",
            project_fields=("project_id",),
            geometry=None,
            order_by=("started_at", "id"),
            post=_outcome_post,
        ),
        Dataset(
            name="butterfly_observations",
            model=ButterflyObservation,
            queryset=observations_for,
            columns=OBSERVATION_COLUMNS,
            time_field="observed_at",
            project_fields=("project_id",),
            geometry="point",
            order_by=("observed_at", "id"),
            geometry_columns=_point_columns(),
        ),
        Dataset(
            name="transects",
            model=Transect,
            queryset=transects_for,
            columns=TRANSECT_COLUMNS,
            time_field=None,
            project_fields=("project_id",),
            geometry="line",
            order_by=("code", "id"),
            geometry_columns=_line_columns(),
        ),
        Dataset(
            name="transect_sections",
            model=TransectSection,
            queryset=sections_for,
            columns=SECTION_COLUMNS,
            time_field=None,
            project_fields=("transect__project_id",),
            geometry="line",
            order_by=("transect__code", "sequence_number", "id"),
            geometry_columns=_line_columns(),
        ),
        Dataset(
            name="environmental_snapshots",
            model=EnvironmentalSnapshot,
            queryset=_snapshots_for,
            columns=SNAPSHOT_COLUMNS,
            time_field="phenomenon_time_start",
            project_fields=("survey_visit__project_id", "observation__project_id"),
            geometry=None,
            order_by=("phenomenon_time_start", "id"),
        ),
        Dataset(
            name="track_points",
            model=SurveyTrackPoint,
            queryset=_track_points_for,
            columns=TRACK_POINT_COLUMNS,
            time_field="recorded_at",
            project_fields=("survey_visit__project_id",),
            geometry="point",
            order_by=("survey_visit_id", "sequence_number"),
            geometry_columns=_point_columns(),
        ),
    )
}

# The datasets in a project bundle. Track points are large and only added on request.
BUNDLE_DATASETS = (
    "survey_visits",
    "butterfly_observations",
    "transects",
    "transect_sections",
    "environmental_snapshots",
)


def iter_rows(dataset, queryset, with_geometry=False):
    """Yield one dict per row, keyed by column name. With `with_geometry`, the GeoJSON of the
    row's geometry (a string, or None) is added under `GEOMETRY_KEY`.

    The queryset is read with a server-side cursor, 2000 rows at a time, so a large export does
    not sit in memory.
    """
    columns = dataset.all_columns
    sources = [column.source for column in columns]
    keys = [column.name for column in columns]
    if with_geometry and dataset.geometry:
        sources.append(AsGeoJSON("geometry"))
        keys.append(GEOMETRY_KEY)
    for values in queryset.values_list(*sources).iterator(chunk_size=2000):
        row = dict(zip(keys, values, strict=True))
        if dataset.post:
            dataset.post(row)
        yield row
