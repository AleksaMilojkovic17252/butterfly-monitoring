from rest_framework import serializers

from apps.core.serializers import UTCDateTimeField, WritableGeoJSONField
from apps.observations.models import Behaviour, ButterflyObservation

# Never sent to or read from the phone: who saved it, and the validation data the server owns
# (T055-T057). The phone learns the outcome of validation from the REST output only.
_NOT_SYNCED = [
    "created_by",
    "updated_by",
    "validation_status",
    "validated_taxon",
    "validated_by",
    "validated_at",
    "validation_comment",
    "quality_flags",
]


class ButterflyObservationSyncSerializer(serializers.ModelSerializer):
    """An observation row as pulled to the phone and pushed from it (T044).

    `observations.services` also validates REST input with it, so push and REST read a payload
    the same way. `recorded_by` may be left out; the service then uses the caller.

    The messages of the hard rules are the rule IDs (T055, docs/requirements/validation-rules.md),
    so the phone can map them to its own text.
    """

    created_at = UTCDateTimeField(required=False)
    observed_at = UTCDateTimeField(error_messages={"required": "V02", "null": "V02"})
    geometry = WritableGeoJSONField(
        "Point",
        error_messages={"required": "V02", "null": "V02", "wrong_type": "V08", "invalid": "V08"},
    )
    # A plain list of strings, so a bad item is one "V07" on the field and not one per index.
    behaviour = serializers.ListField(child=serializers.CharField(allow_blank=True), required=False)

    class Meta:
        model = ButterflyObservation
        exclude = _NOT_SYNCED
        read_only_fields = ["deleted_at"]
        extra_kwargs = {
            "recorded_by": {"required": False},
            "count": {"min_value": 1, "error_messages": {"min_value": "V01"}},
            "sex": {"error_messages": {"invalid_choice": "V07"}},
            "life_stage": {"error_messages": {"invalid_choice": "V07"}},
            "source": {"error_messages": {"invalid_choice": "V07"}},
            "identification_confidence": {"error_messages": {"invalid_choice": "V07"}},
        }

    def validate_behaviour(self, value):
        if any(item not in Behaviour.values for item in value):
            raise serializers.ValidationError("V07")
        # Repeated values are dropped, the order is kept.
        return list(dict.fromkeys(value))


class ButterflyObservationSerializer(serializers.ModelSerializer):
    """An observation as the REST API returns it: every field, plus the computed `photo_count`.

    Output only; the endpoints read their input with `ButterflyObservationSyncSerializer`.
    """

    photo_count = serializers.SerializerMethodField()

    class Meta:
        model = ButterflyObservation
        exclude = ["created_by", "updated_by"]

    def get_photo_count(self, observation) -> int:
        from apps.observations import services  # services imports this module

        return services.photo_count(observation)
