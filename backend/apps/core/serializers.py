"""Serializer pieces shared by the apps."""

import json

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
