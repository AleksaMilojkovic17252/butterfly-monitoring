from rest_framework import serializers

from apps.core.serializers import UTCDateTimeField, WritableGeoJSONField
from apps.surveys.models import SurveyTrackPoint, SurveyVisit

# Never sent to the phone: who saved it, and the lock and quality data the server owns. The phone
# learns about a lock from `status = locked`.
_NOT_SYNCED = ["created_by", "updated_by", "locked_at", "locked_by", "lock_reason", "quality_flags"]


class SurveyVisitSyncSerializer(serializers.ModelSerializer):
    """A visit row as pulled to the phone and pushed from it (T034).

    `surveys.services` also validates REST input with it, so push and REST read a payload the
    same way. `observer` may be left out; the service then uses the caller.
    """

    created_at = UTCDateTimeField(required=False)
    started_at = UTCDateTimeField(required=False, allow_null=True)
    ended_at = UTCDateTimeField(required=False, allow_null=True)

    class Meta:
        model = SurveyVisit
        exclude = _NOT_SYNCED
        # deleted_at: push strips it, but REST validates with this class too, and a visit is
        # cancelled, never deleted by a client. distance_walked_m is writable: the phone's figure
        # is kept unless the server can work it out from the track (T036).
        read_only_fields = ["deleted_at"]
        # The messages of the hard rules are the rule IDs (T055).
        extra_kwargs = {
            "observer": {"required": False},
            "status": {"error_messages": {"invalid_choice": "V07"}},
            "survey_method": {"error_messages": {"invalid_choice": "V07"}},
            "precipitation": {"error_messages": {"invalid_choice": "V07"}},
            "cancel_reason": {"error_messages": {"invalid_choice": "V07"}},
        }


class SurveyVisitSerializer(serializers.ModelSerializer):
    """A visit as the REST API returns it: the synced fields plus the server-owned ones.

    Output only; the endpoints read their input with `SurveyVisitSyncSerializer`.
    """

    class Meta:
        model = SurveyVisit
        exclude = ["created_by", "updated_by"]


class SurveyTrackPointSyncSerializer(serializers.ModelSerializer):
    """One GPS fix as the phone pushes it in a `create_batch` row (T036).

    The visit is the mutation's `entity_id`, so it is not a field here. Track points are not
    pulled (`surveys.services.pull_track_points`); the class also describes them in the schema.
    """

    id = serializers.UUIDField()
    created_at = UTCDateTimeField(required=False)
    recorded_at = UTCDateTimeField()
    geometry = WritableGeoJSONField("Point")

    class Meta:
        model = SurveyTrackPoint
        exclude = ["survey_visit", "created_by", "updated_by"]
        read_only_fields = ["deleted_at"]

    def validate_heading_deg(self, value):
        # Checked here too, so a bad value is a field error and not an integrity_error.
        if value is not None and not 0 <= value < 360:
            raise serializers.ValidationError("Must be at least 0 and below 360.")
        return value
