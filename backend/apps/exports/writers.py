"""CSV, GeoJSON and JSON writers (T064). Each is a generator of `str` chunks over an iterator of
row dicts, so a response can stream and a ZIP can be filled without holding a dataset in memory.
"""

import csv
import json
from datetime import date, datetime
from decimal import Decimal
from itertools import islice
from uuid import UUID

from apps.exports.datasets import GEOMETRY_KEY

BOM = "﻿"
BATCH_ROWS = 500  # rows joined into one chunk, so a stream is not one tiny write per row


class _Echo:
    """The pseudo-buffer from the Django docs: `write` returns the value instead of storing it."""

    def write(self, value):
        return value


def _csv_value(value, na):
    if value is None:
        return na
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, datetime | date):
        return value.isoformat()
    if isinstance(value, Decimal | UUID):
        return str(value)
    if isinstance(value, list | tuple):
        return ";".join(str(item) for item in value)
    if isinstance(value, dict):
        return json.dumps(value, ensure_ascii=False)
    return value


def _json_default(value):
    """What `json.dumps` does with the types it does not know. Decimals become numbers."""
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, datetime | date):
        return value.isoformat()
    if isinstance(value, UUID):
        return str(value)
    raise TypeError(f"{type(value).__name__} is not JSON serializable")


def _dumps(value):
    return json.dumps(value, default=_json_default, ensure_ascii=False)


def _batches(texts, separator=""):
    """Join the strings of `texts` with `separator`, in groups of `BATCH_ROWS`."""
    texts = iter(texts)
    while batch := list(islice(texts, BATCH_ROWS)):
        yield separator.join(batch)


def csv_chunks(column_names, rows, na, excel=False):
    """The CSV: a header, then one line per row. `None` is written as `na`, booleans as
    true/false, times as ISO 8601 with their offset, lists joined with `;`. With `excel`, the
    text starts with a byte order mark so Excel reads it as UTF-8."""
    writer = csv.writer(_Echo())

    def lines():
        yield writer.writerow(column_names)
        for row in rows:
            yield writer.writerow([_csv_value(row[name], na) for name in column_names])

    first = True
    for chunk in _batches(lines()):
        yield (BOM + chunk) if (excel and first) else chunk
        first = False


def geojson_chunks(column_names, rows):
    """A FeatureCollection with no `crs` member: coordinates are CRS84 lon/lat (RFC 7946). A row
    without geometry gets `"geometry": null`, which the standard allows."""

    def features():
        for row in rows:
            properties = _dumps({name: row[name] for name in column_names})
            geometry = row.get(GEOMETRY_KEY) or "null"
            feature_id = _dumps(str(row["id"]))
            yield (
                f'{{"type":"Feature","id":{feature_id},'
                f'"geometry":{geometry},"properties":{properties}}}'
            )

    yield '{"type":"FeatureCollection","features":['
    first = True
    for chunk in _batches(features(), ","):
        # A comma also starts every batch but the first.
        yield chunk if first else "," + chunk
        first = False
    yield "]}"


def json_chunks(metadata, column_names, rows):
    """`{"metadata": {...}, "data": [{...}, ...]}`. Missing values are `null`."""

    def items():
        for row in rows:
            yield _dumps({name: row[name] for name in column_names})

    yield f'{{"metadata":{_dumps(metadata)},"data":['

    first = True
    for chunk in _batches(items(), ","):
        yield chunk if first else "," + chunk
        first = False
    yield "]}"
