from rest_framework import serializers

from apps.core.serializers import UTCDateTimeField, WritableGeoJSONField
from apps.resources.models import HabitatFeature, PlantResourceObservation


class PlantResourceSyncSerializer(serializers.ModelSerializer):
    """A plant record as pulled to the phone, pushed from it and returned by REST (T051).

    `resources.services` also validates REST input with it, so push and REST read a payload the
    same way. Nothing here belongs to the server except `patch_area_m2`, which the server fills in
    for a polygon when it is empty, and `created_by`, which is output only, so the same serializer
    is the REST output.

    The messages of the hard rules are the rule IDs (docs/requirements/validation-rules.md), so
    the phone can map them to its own text.
    """

    created_at = UTCDateTimeField(required=False)
    observed_at = UTCDateTimeField(error_messages={"required": "V02", "null": "V02"})
    geometry = WritableGeoJSONField(
        ("Point", "Polygon"),
        error_messages={"required": "V02", "null": "V02", "wrong_type": "V08", "invalid": "V08"},
    )

    class Meta:
        model = PlantResourceObservation
        exclude = ["updated_by"]
        # created_by is pulled so the phone can show only its user's records (logout keeps other
        # users' rows, T052). It is read-only: the server sets it from the caller.
        read_only_fields = ["created_by", "deleted_at"]
        extra_kwargs = {
            "resource_type": {"error_messages": {"invalid_choice": "V07"}},
            "abundance_class": {"error_messages": {"invalid_choice": "V07"}},
            "phenology_stage": {"error_messages": {"invalid_choice": "V07"}},
            "flowering_intensity": {"error_messages": {"invalid_choice": "V07"}},
            "patch_area_m2": {"min_value": 0},
        }

    def validate(self, attrs):
        """An unidentified plant needs notes. Read the final values: a partial update that only
        clears the notes or the plant is checked against the stored row."""
        instance = self.instance

        def final(name):
            if name in attrs:
                return attrs[name]
            if instance is None:
                return None
            # The id of the plant, so the stored row's plant is not loaded just to test for null.
            return getattr(instance, "plant_taxon_id" if name == "plant_taxon" else name)

        if final("plant_taxon") is None and not final("notes"):
            raise serializers.ValidationError(
                {"notes": ["Required when the plant is not identified."]}
            )
        return attrs


class HabitatFeatureSyncSerializer(serializers.ModelSerializer):
    """A habitat feature as pulled to the phone, pushed from it and returned by REST (T053).

    Built like `PlantResourceSyncSerializer`, and `resources.services` validates REST input with
    it too. `habitat_type` is required (a non-null foreign key) and `management_type` may be
    null. The messages of the hard rules are the rule IDs; a percentage outside 0-100 has no rule
    ID, so its message is a plain sentence on the field.
    """

    created_at = UTCDateTimeField(required=False)
    observed_at = UTCDateTimeField(error_messages={"required": "V02", "null": "V02"})
    geometry = WritableGeoJSONField(
        ("Point", "LineString", "Polygon"),
        error_messages={"required": "V02", "null": "V02", "wrong_type": "V08", "invalid": "V08"},
    )

    class Meta:
        model = HabitatFeature
        exclude = ["updated_by"]
        read_only_fields = ["created_by", "deleted_at"]
        extra_kwargs = {
            "flower_abundance_class": {"error_messages": {"invalid_choice": "V07"}},
            "grazing_intensity": {"error_messages": {"invalid_choice": "V07"}},
            "mowing_status": {"error_messages": {"invalid_choice": "V07"}},
            "disturbance_type": {"error_messages": {"invalid_choice": "V07"}},
            "shrub_cover_pct": {"min_value": 0, "max_value": 100},
            "tree_cover_pct": {"min_value": 0, "max_value": 100},
            "bare_ground_pct": {"min_value": 0, "max_value": 100},
        }
