from rest_framework import serializers

from apps.core.serializers import UTCDateTimeField
from apps.surveys.models import SurveyVisit

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
        # distance_walked_m: computed from the track (T036). deleted_at: push strips it, but REST
        # validates with this class too, and a visit is cancelled, never deleted by a client.
        read_only_fields = ["distance_walked_m", "deleted_at"]
        extra_kwargs = {"observer": {"required": False}}


class SurveyVisitSerializer(serializers.ModelSerializer):
    """A visit as the REST API returns it: the synced fields plus the server-owned ones.

    Output only; the endpoints read their input with `SurveyVisitSyncSerializer`.
    """

    class Meta:
        model = SurveyVisit
        exclude = ["created_by", "updated_by"]
