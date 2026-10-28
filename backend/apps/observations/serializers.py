from rest_framework import serializers

from apps.core.serializers import UTCDateTimeField, WritableGeoJSONField
from apps.observations.models import ButterflyObservation

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
    """

    created_at = UTCDateTimeField(required=False)
    observed_at = UTCDateTimeField()
    geometry = WritableGeoJSONField("Point")

    class Meta:
        model = ButterflyObservation
        exclude = _NOT_SYNCED
        read_only_fields = ["deleted_at"]
        extra_kwargs = {"recorded_by": {"required": False}}

    def validate_behaviour(self, value):
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
