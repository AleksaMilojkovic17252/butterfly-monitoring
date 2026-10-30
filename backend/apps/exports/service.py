"""The export service (T064). The API calls `export` and `bundle`; the admin actions (T065) call
the same functions, so both give the same bytes for the same filter.
"""

import json
import tempfile
import zipfile
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID

from django.conf import settings
from django.db.models import Q
from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError

from apps.exports import writers
from apps.exports.datasets import (
    BUNDLE_DATASETS,
    DATASETS,
    DEFERRED,
    iter_rows,
)
from apps.projects.services import projects_for

EXPORT_FORMAT_VERSION = "1"
FORMATS = {
    "csv": ("text/csv; charset=utf-8", "csv"),
    "geojson": ("application/geo+json", "geojson"),
    "json": ("application/json", "json"),
}
DATE_NOTE = "from and to filter on started_at (visits), observed_at (observations), "
DATE_NOTE += "phenomenon_time_start (snapshots) and recorded_at (track points), in UTC, "
DATE_NOTE += "both days included. Transects and transect_sections ignore them."
TRUE_VALUES = {"1", "true", "yes"}
FALSE_VALUES = {"0", "false", "no", ""}


@dataclass(frozen=True)
class ExportFilters:
    project: UUID | None = None
    date_from: date | None = None
    date_to: date | None = None
    na: str = ""  # the missing-value code; parse_filters fills in the setting
    excel: bool = False
    track_points: bool = False


def _parse_flag(params, name):
    value = params.get(name, "0").strip().lower()
    if value in TRUE_VALUES:
        return True
    if value in FALSE_VALUES:
        return False
    raise ValidationError({name: ["Use 1 or 0."]})


def _parse_date(params, name):
    value = params.get(name)
    if not value:
        return None
    try:
        if len(value) != 10:  # fromisoformat also takes 20260101; the API takes YYYY-MM-DD only
            raise ValueError
        return date.fromisoformat(value)
    except ValueError:
        raise ValidationError({name: ["Use a date as YYYY-MM-DD."]}) from None


def parse_format(params):
    """The `format` query parameter: csv (default), geojson or json."""
    value = params.get("format", "csv").lower()
    if value not in FORMATS:
        raise ValidationError({"format": [f"Use one of: {', '.join(FORMATS)}."]})
    return value


def parse_filters(params):
    """Read the query parameters into an `ExportFilters`; bad input is a 400 on that field."""
    project = None
    if params.get("project"):
        try:
            project = UUID(params["project"])
        except ValueError:
            raise ValidationError({"project": ["Use the project's UUID."]}) from None
    date_from = _parse_date(params, "from")
    date_to = _parse_date(params, "to")
    if date_from and date_to and date_from > date_to:
        raise ValidationError({"to": ["to is before from."]})
    return ExportFilters(
        project=project,
        date_from=date_from,
        date_to=date_to,
        na=params.get("na", settings.EXPORT_MISSING_VALUE),
        excel=_parse_flag(params, "excel"),
        track_points=_parse_flag(params, "track_points"),
    )


def _dataset(name):
    if name in DEFERRED:
        raise NotFound(f"Not available until {DEFERRED[name]}.")
    if name not in DATASETS:
        raise NotFound(f"No dataset called {name}.")
    return DATASETS[name]


def _queryset(user, dataset, filters):
    """The dataset's rows for this user, narrowed by the project and the dates."""
    queryset = dataset.queryset(user)
    if filters.project:
        match = Q()
        for path in dataset.project_fields:
            match |= Q(**{path: filters.project})
        queryset = queryset.filter(match)
    if dataset.time_field:
        if filters.date_from:
            start = datetime.combine(filters.date_from, time.min, tzinfo=UTC)
            queryset = queryset.filter(**{f"{dataset.time_field}__gte": start})
        if filters.date_to:
            end = datetime.combine(filters.date_to + timedelta(days=1), time.min, tzinfo=UTC)
            queryset = queryset.filter(**{f"{dataset.time_field}__lt": end})
    return queryset.order_by(*dataset.order_by)


def _distinct(user, dataset, filters, column_name):
    column = next((c for c in dataset.columns if c.name == column_name), None)
    if column is None:
        return set()
    values = _queryset(user, dataset, filters).order_by().values_list(column.source, flat=True)
    return {value for value in values.distinct() if value}


def metadata(user, names, filters, fmt="csv"):
    """The content of metadata.json for an export of the datasets in `names`."""
    extension = FORMATS[fmt][1]
    datasets = {}
    row_counts = {}
    protocol_versions = set()
    taxon_list_versions = set()
    for name in names:
        dataset = DATASETS[name]
        row_counts[name] = _queryset(user, dataset, filters).count()
        datasets[name] = {
            "file": f"{name}.{extension}",
            "geometry": {"point": "Point", "line": "LineString"}.get(dataset.geometry),
            "columns": {column.name: dataset.description(column) for column in dataset.all_columns},
        }
        protocol_versions |= _distinct(user, dataset, filters, "protocol_version")
        taxon_list_versions |= _distinct(user, dataset, filters, "taxon_list_version")
    not_included = {name: f"Not available until {ticket}." for name, ticket in DEFERRED.items()}
    if "track_points" not in names:
        not_included["track_points"] = "Large; add track_points=1 to the bundle request."
    return {
        "exported_at": timezone.now().astimezone(UTC).isoformat(),
        "exported_by": user.email,
        "filters": {
            "project": str(filters.project) if filters.project else None,
            "from": filters.date_from.isoformat() if filters.date_from else None,
            "to": filters.date_to.isoformat() if filters.date_to else None,
            "date_filter": DATE_NOTE,
        },
        "crs": "EPSG:4326",
        "crs_note": "Coordinates are WGS 84 longitude, latitude. GeoJSON follows RFC 7946 "
        "(CRS84, lon/lat) and has no crs member.",
        "missing_value_code": filters.na,
        "missing_value_note": "The code is written in CSV files. JSON and GeoJSON use null.",
        "versions": {
            "export_format": EXPORT_FORMAT_VERSION,
            "protocol": sorted(protocol_versions),
            "taxon_list": sorted(taxon_list_versions),
        },
        "row_counts": row_counts,
        "datasets": datasets,
        "not_included": not_included,
    }


def _chunks(user, dataset, fmt, filters):
    queryset = _queryset(user, dataset, filters)
    names = [column.name for column in dataset.all_columns]
    if fmt == "csv":
        return writers.csv_chunks(names, iter_rows(dataset, queryset), filters.na, filters.excel)
    if fmt == "geojson":
        properties = [column.name for column in dataset.columns]
        return writers.geojson_chunks(properties, iter_rows(dataset, queryset, True))
    info = metadata(user, [dataset.name], filters, fmt)
    return writers.json_chunks(info, names, iter_rows(dataset, queryset))


def export(user, name, fmt, filters):
    """One dataset as a stream of text chunks: `(chunks, content_type, filename)`."""
    dataset = _dataset(name)
    content_type, extension = FORMATS[fmt]
    return _chunks(user, dataset, fmt, filters), content_type, f"{name}.{extension}"


def bundle(user, filters):
    """A ZIP of the project's CSV files and metadata.json: `(file, filename)`.

    Built in a temporary file, not streamed (D-014: exports run in the request). Track points
    are in it only when `filters.track_points` is set.
    """
    if not filters.project:
        raise ValidationError({"project": ["The bundle needs a project."]})
    if not projects_for(user).filter(pk=filters.project).exists():
        raise NotFound("No such project.")
    names = list(BUNDLE_DATASETS)
    if filters.track_points:
        names.append("track_points")
    info = metadata(user, names, filters)
    file = tempfile.SpooledTemporaryFile(max_size=50 * 1024 * 1024)  # noqa: SIM115
    with zipfile.ZipFile(file, "w", zipfile.ZIP_DEFLATED) as archive:
        for name in names:
            with archive.open(f"{name}.csv", "w") as target:
                for chunk in _chunks(user, DATASETS[name], "csv", filters):
                    target.write(chunk.encode("utf-8"))
        archive.writestr(
            "metadata.json", json.dumps(info, indent=2, ensure_ascii=False).encode("utf-8")
        )
    file.seek(0)
    stamp = timezone.now().astimezone(UTC).strftime("%Y%m%dT%H%M%SZ")
    return file, f"butterfly-export-{filters.project}-{stamp}.zip"
