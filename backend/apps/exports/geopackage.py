"""The project GeoPackage (T066, D-103): one `.gpkg` with the spatial layers and three tables.

Spatial layers are read from the `geo` views (T067), so their columns are the OGC API's. The
non-spatial tables have no view: their SQL is compiled from the T064 dataset querysets, so
columns, scoping, filters and order are the CSV bundle's. Every layer is one `ogr2ogr` run.
"""

import logging
import os
import subprocess
import tempfile
from datetime import UTC, datetime, time, timedelta
from pathlib import Path

from django.conf import settings
from django.db import connection
from django.db.models import Case, CharField, F, Value, When
from django.db.models.functions import Concat
from django.http import FileResponse
from django.utils import timezone

from apps.exports import service
from apps.exports.datasets import DATASETS
from apps.surveys.models import VisitStatus

logger = logging.getLogger(__name__)

CONTENT_TYPE = "application/geopackage+sqlite3"

# (layer, geometry type, geo view, WHERE clause, dated). `%s` is the project id. `dated` layers
# also get the observed_at range when the filters have dates. Every query is
# `SELECT * FROM geo.<view> WHERE … ORDER BY id`.
_SPATIAL = (
    ("transects", "LINESTRING", "transects", "project_id = %s", False),
    (
        "transect_sections",
        "LINESTRING",
        "transect_sections",
        "transect_id IN (SELECT id FROM geo.transects WHERE project_id = %s)",
        False,
    ),
    ("butterfly_observations", "POINT", "butterfly_observations", "project_id = %s", True),
    (
        "plant_resources_points",
        "POINT",
        "plant_resources",
        "project_id = %s AND geometry_type = 'POINT'",
        True,
    ),
    (
        "plant_resources_polygons",
        "POLYGON",
        "plant_resources",
        "project_id = %s AND geometry_type = 'POLYGON'",
        True,
    ),
    (
        "habitat_features_points",
        "POINT",
        "habitat_features",
        "project_id = %s AND geometry_type = 'POINT'",
        True,
    ),
    (
        "habitat_features_lines",
        "LINESTRING",
        "habitat_features",
        "project_id = %s AND geometry_type = 'LINESTRING'",
        True,
    ),
    (
        "habitat_features_polygons",
        "POLYGON",
        "habitat_features",
        "project_id = %s AND geometry_type = 'POLYGON'",
        True,
    ),
)
NON_SPATIAL = ("survey_visits", "environmental_snapshots", "validation_history")

# The SQL twin of `surveys.models.visit_outcome` (D-069). Both must change together.
_OUTCOME = Case(
    When(status=VisitStatus.CANCELLED, then=Concat(Value("cancelled:"), F("cancel_reason"))),
    When(status__in=(VisitStatus.DRAFT, VisitStatus.IN_PROGRESS), then=Value(None)),
    When(zero_observation_confirmed=True, then=Value("true_zero")),
    default=Value("completed_with_records"),
    output_field=CharField(),
)


def _compose(sql, params):
    """The query with its parameters written in as literals by the driver (never f-strings)."""
    return connection.ops.compose_sql(sql, params)


def _spatial_sql(view, where, dated, filters):
    sql = f"SELECT * FROM geo.{view} WHERE {where}"  # noqa: S608 (names are constants above)
    params = [filters.project]
    if dated and filters.date_from:
        sql += " AND observed_at >= %s"
        params.append(datetime.combine(filters.date_from, time.min, tzinfo=UTC))
    if dated and filters.date_to:
        sql += " AND observed_at < %s"
        end = filters.date_to + timedelta(days=1)
        params.append(datetime.combine(end, time.min, tzinfo=UTC))
    return _compose(sql + " ORDER BY id", params)


def _dataset_sql(user, name, filters):
    """The dataset's CSV columns as one SELECT, from the same queryset the CSV bundle reads."""
    dataset = DATASETS[name]
    expressions = {}
    for index, column in enumerate(dataset.columns):
        if name == "survey_visits" and column.name == "outcome":
            source = _OUTCOME
        else:
            source = F(column.source) if isinstance(column.source, str) else column.source
        expressions[f"c{index}"] = source
    queryset = service.scoped_queryset(user, dataset, filters).values(**expressions)
    sql, params = queryset.query.sql_with_params()
    quote = connection.ops.quote_name
    select = ", ".join(
        f"{quote(f'c{index}')} AS {quote(column.name)}"
        for index, column in enumerate(dataset.columns)
    )
    # The inner ORDER BY does not survive the wrapper in theory, so order again by the output
    # names (every order_by of the three tables is a column of the CSV).
    names = {column.name for column in dataset.columns}
    order = ", ".join(quote(part) for part in dataset.order_by if part in names)
    return f"SELECT {select} FROM ({_compose(sql, params)}) AS q ORDER BY {order}"  # noqa: S608


def _ogr2ogr(path, layer, sql, geometry_type, first):
    db = settings.DATABASES["default"]
    dsn = f"PG:dbname={db['NAME']} host={db['HOST']} port={db['PORT'] or 5432} user={db['USER']}"
    command = ["ogr2ogr", "-f", "GPKG"]
    if not first:
        command.append("-update")
    command += [str(path), dsn, "-sql", sql, "-nln", layer]
    if geometry_type:
        command += ["-nlt", geometry_type, "-a_srs", "EPSG:4326", "-lco", "GEOMETRY_NAME=geometry"]
    else:
        command += ["-nlt", "NONE"]
    try:
        subprocess.run(  # noqa: S603
            command,
            check=True,
            capture_output=True,
            text=True,
            timeout=300,
            env={**os.environ, "PGPASSWORD": db["PASSWORD"]},  # not in argv, not in logs
        )
    except subprocess.CalledProcessError as error:
        logger.error("ogr2ogr failed for layer %s: %s", layer, error.stderr)
        raise
    except (subprocess.TimeoutExpired, OSError):  # too slow, or ogr2ogr is not installed
        logger.exception("ogr2ogr could not run for layer %s", layer)
        raise


def build(user, filters):
    """The project's GeoPackage: `(file, filename)`. Built in the request, like the ZIP (D-014)."""
    service.require_project(user, filters)
    with tempfile.TemporaryDirectory() as folder:
        path = Path(folder) / "out.gpkg"
        first = True
        for layer, geometry_type, view, where, dated in _SPATIAL:
            _ogr2ogr(path, layer, _spatial_sql(view, where, dated, filters), geometry_type, first)
            first = False
        for name in NON_SPATIAL:
            _ogr2ogr(path, name, _dataset_sql(user, name, filters), None, False)
        file = tempfile.SpooledTemporaryFile(max_size=50 * 1024 * 1024)  # noqa: SIM115
        with path.open("rb") as source:
            while chunk := source.read(1024 * 1024):
                file.write(chunk)
    file.seek(0)
    stamp = timezone.now().astimezone(UTC).strftime("%Y%m%dT%H%M%SZ")
    return file, f"butterfly-export-{filters.project}-{stamp}.gpkg"


def response(user, filters):
    """The download response for the API view and the admin button."""
    file, filename = build(user, filters)
    return FileResponse(file, as_attachment=True, filename=filename, content_type=CONTENT_TYPE)
