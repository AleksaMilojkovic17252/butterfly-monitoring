from rest_framework import serializers

from apps.core.serializers import GeoJSONField, UTCDateTimeField, WritableGeoJSONField
from apps.transects.models import Transect, TransectProposal, TransectSection
from apps.transects.services import geodesic_length_m


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


class TransectSectionSyncSerializer(serializers.ModelSerializer):
    """A section row as pulled to the phone (T025). Push (T026) uses the same class."""

    geometry = GeoJSONField()

    class Meta:
        model = TransectSection
        exclude = ["created_by", "updated_by"]


class TransectSyncSerializer(serializers.ModelSerializer):
    """A transect row as pulled to the phone (T025). Push (T026) uses the same class."""

    geometry = GeoJSONField()
    # Annotated by transects.services.pull_transects; computed for other instances (push, T026).
    length_m = serializers.SerializerMethodField()

    class Meta:
        model = Transect
        exclude = ["created_by", "updated_by"]

    def get_length_m(self, transect) -> float:
        """Geodesic length of the line in metres, to 0.1 m."""
        length = getattr(transect, "length_m", None)
        if length is None:
            length = geodesic_length_m(transect)
        return round(length, 1)


class TransectProposalSyncSerializer(serializers.ModelSerializer):
    """A route proposal as pulled to the phone and pushed from it (T108).

    The status, the review fields, `created_transect` and `length_m` are the server's: they are
    read-only here and listed in `SyncEntity.server_owned`. The messages of the hard rules are the
    rule IDs (docs/requirements/validation-rules.md).
    """

    created_at = UTCDateTimeField(required=False)
    recorded_from = UTCDateTimeField(error_messages={"required": "V02", "null": "V02"})
    recorded_to = UTCDateTimeField(error_messages={"required": "V02", "null": "V02"})
    geometry = WritableGeoJSONField(
        ("LineString",),
        error_messages={"required": "V02", "null": "V02", "wrong_type": "V08", "invalid": "V08"},
    )

    class Meta:
        model = TransectProposal
        exclude = ["updated_by"]
        read_only_fields = [
            "created_by",
            "deleted_at",
            "status",
            "review_note",
            "reviewed_by",
            "reviewed_at",
            "created_transect",
            "length_m",
        ]
        extra_kwargs = {
            "reason": {"error_messages": {"invalid_choice": "V07", "required": "V02"}},
            "name": {"error_messages": {"required": "V02", "blank": "V02", "null": "V02"}},
        }
