import json

from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from apps.transects.models import Transect, TransectSection


@extend_schema_field(OpenApiTypes.OBJECT)
class GeoJSONField(serializers.Field):
    """A GEOS geometry as a GeoJSON geometry object (read-only)."""

    def __init__(self, **kwargs):
        super().__init__(read_only=True, **kwargs)

    def to_representation(self, value) -> dict:
        return json.loads(value.geojson)


class TransectSectionSerializer(serializers.ModelSerializer):
    geometry = GeoJSONField()

    class Meta:
        model = TransectSection
        fields = [
            "id",
            "transect",
            "section_code",
            "sequence_number",
            "habitat_type",
            "management_type",
            "notes",
            "geometry",
            "server_version",
            "deleted_at",
        ]
        read_only_fields = fields


class TransectSerializer(serializers.ModelSerializer):
    geometry = GeoJSONField()
    # Annotated by services.with_stats.
    length_m = serializers.SerializerMethodField()
    section_count = serializers.IntegerField(read_only=True)
    visit_count = serializers.IntegerField(read_only=True)
    last_visit_at = serializers.DateTimeField(read_only=True, allow_null=True)

    class Meta:
        model = Transect
        fields = [
            "id",
            "project",
            "code",
            "name",
            "description",
            "target_length_m",
            "length_m",
            "habitat_summary",
            "active",
            "geometry",
            "section_count",
            "visit_count",
            "last_visit_at",
            "server_version",
            "deleted_at",
        ]
        read_only_fields = fields

    def get_length_m(self, transect) -> float:
        """Geodesic length of the line in metres, to 0.1 m."""
        return round(transect.length_m, 1)


class TransectDetailSerializer(TransectSerializer):
    sections = TransectSectionSerializer(source="live_sections", many=True, read_only=True)

    class Meta(TransectSerializer.Meta):
        fields = [*TransectSerializer.Meta.fields, "sections"]
        read_only_fields = fields
