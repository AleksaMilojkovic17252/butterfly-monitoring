from datetime import UTC

from django.utils.dateparse import parse_datetime
from rest_framework import serializers

from apps.core.serializers import UTCDateTimeField, WritableGeoJSONField
from apps.surveys.models import SurveyTrackPoint, SurveyVisit

# Never sent to the phone: who saved it, and the lock and quality data the server owns. The phone
# learns about a lock from `status = locked`.
_NOT_SYNCED = ["created_by", "updated_by", "locked_at", "locked_by", "lock_reason", "quality_flags"]

_MAX_PAUSES = 500


def _aware_datetime(text):
    """Parse an ISO 8601 string that carries a UTC offset; anything else is a field error."""
    try:
        # Raises ValueError for text that is shaped like a date but is not one ("2026-02-30...").
        parsed = parse_datetime(text) if isinstance(text, str) else None
    except ValueError:
        parsed = None
    if parsed is None or parsed.utcoffset() is None:
        raise serializers.ValidationError("Pause times must be ISO 8601 with a UTC offset.")
    return parsed


def _utc_iso(moment):
    return moment.astimezone(UTC).isoformat().replace("+00:00", "Z")


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

    def validate_pauses(self, value):
        """A list of at most 500 `{started_at, ended_at}` pairs, returned as UTC ISO strings."""
        if not isinstance(value, list):
            raise serializers.ValidationError("Must be a list.")
        if len(value) > _MAX_PAUSES:
            raise serializers.ValidationError(f"At most {_MAX_PAUSES} pauses.")
        pauses = []
        for item in value:
            if not isinstance(item, dict) or set(item) != {"started_at", "ended_at"}:
                raise serializers.ValidationError("Each pause needs started_at and ended_at.")
            started, ended = (_aware_datetime(item[key]) for key in ("started_at", "ended_at"))
            if ended < started:
                raise serializers.ValidationError("A pause cannot end before it starts.")
            pauses.append({"started_at": _utc_iso(started), "ended_at": _utc_iso(ended)})
        return pauses


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
