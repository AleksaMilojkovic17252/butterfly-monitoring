"""Serializer pieces shared by the apps."""

import json

from django.contrib.gis.gdal import GDALException
from django.contrib.gis.geos import GEOSException, GEOSGeometry
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers


@extend_schema_field(OpenApiTypes.OBJECT)
class GeoJSONField(serializers.Field):
    """A GEOS geometry as a GeoJSON geometry object (read-only)."""

    def __init__(self, **kwargs):
        super().__init__(read_only=True, **kwargs)

    def to_representation(self, value) -> dict:
        return json.loads(value.geojson)


@extend_schema_field(OpenApiTypes.OBJECT)
class WritableGeoJSONField(serializers.Field):
    """A GEOS geometry read from and written as a GeoJSON geometry object in EPSG:4326.

    `geom_type` is the one GEOS type accepted ("Point", "LineString", ...). Track points (T036)
    and observations (T044) use it for what the phone sends. A caller can replace the message
    with a rule ID: `error_messages={"wrong_type": "V08", "invalid": "V08"}` (T055).
    """

    default_error_messages = {
        "wrong_type": "Send a GeoJSON {geom_type} object.",
        "invalid": "Not a valid GeoJSON {geom_type}.",
    }

    def __init__(self, geom_type, **kwargs):
        self.geom_type = geom_type
        super().__init__(**kwargs)

    def to_representation(self, value) -> dict:
        return json.loads(value.geojson)

    def to_internal_value(self, data):
        if not isinstance(data, dict) or data.get("type") != self.geom_type:
            self.fail("wrong_type", geom_type=self.geom_type)
        try:
            geometry = GEOSGeometry(json.dumps(data), srid=4326)
        except (GDALException, GEOSException, ValueError, TypeError):
            self.fail("invalid", geom_type=self.geom_type)
        if geometry.geom_type != self.geom_type or geometry.empty or not geometry.valid:
            self.fail("invalid", geom_type=self.geom_type)
        return geometry


class UTCDateTimeField(serializers.DateTimeField):
    """A datetime that must carry an offset; DRF would read a bare one in the server zone."""

    def enforce_timezone(self, value):
        if timezone.is_naive(value):
            raise serializers.ValidationError(
                "Datetime needs a UTC offset, e.g. 2026-05-01T08:00:00Z."
            )
        return value
