"""Request, tombstone and response shapes of the pull (T025) and push (T026) endpoints."""

from drf_spectacular.utils import PolymorphicProxySerializer
from rest_framework import serializers

from apps.core.serializers import UTCDateTimeField
from apps.sync.registry import ENTITIES

DEFAULT_PULL_LIMIT = 1000
MAX_PULL_LIMIT = 5000
MAX_CURSOR = 2**63 - 1  # server_version is a bigint
MAX_PUSH_MUTATIONS = 1000
MAX_BATCH_ROWS = 1000


class PullRequestSerializer(serializers.Serializer):
    project_id = serializers.UUIDField()
    cursor = serializers.IntegerField(min_value=0, max_value=MAX_CURSOR, default=0)
    limit = serializers.IntegerField(
        min_value=1, max_value=MAX_PULL_LIMIT, default=DEFAULT_PULL_LIMIT
    )


class TombstoneSerializer(serializers.Serializer):
    """A soft-deleted row: the phone removes it."""

    id = serializers.UUIDField()
    deleted_at = serializers.DateTimeField()
    server_version = serializers.IntegerField()


# For OpenAPI only: the view returns the dict built by services.pull.
PullChangesSerializer = type(
    "PullChanges",
    (serializers.Serializer,),
    {
        entity.entity_type: PolymorphicProxySerializer(
            component_name=f"Pull_{entity.entity_type}",
            serializers=[entity.serializer, TombstoneSerializer],
            resource_type_field_name=None,
            many=True,
        )
        for entity in ENTITIES
    },
)


class PullResponseSerializer(serializers.Serializer):
    changes = PullChangesSerializer()
    next_cursor = serializers.IntegerField()
    has_more = serializers.BooleanField()
    server_time = serializers.DateTimeField()


class MutationSerializer(serializers.Serializer):
    """One change from the phone. For a `create_batch`, `entity_id` is the parent record."""

    mutation_id = serializers.UUIDField()
    entity_type = serializers.CharField(max_length=40)
    entity_id = serializers.UUIDField()
    operation = serializers.ChoiceField(choices=["create", "update", "delete", "create_batch"])
    base_version = serializers.IntegerField(
        min_value=0, max_value=MAX_CURSOR, allow_null=True, required=False, default=None
    )
    payload = serializers.DictField(default=dict)
    client_created_at = UTCDateTimeField(allow_null=True, required=False, default=None)


class PushRequestSerializer(serializers.Serializer):
    """The envelope. Each mutation is validated on its own, so one bad item is only rejected."""

    device_id = serializers.CharField(max_length=64)
    # Any item type: a non-object item is rejected on its own in the service, not with a 400.
    mutations = serializers.ListField(child=serializers.JSONField(), max_length=MAX_PUSH_MUTATIONS)


# For OpenAPI only: the view validates with PushRequestSerializer.
class PushMutationsSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=64)
    mutations = MutationSerializer(many=True)


class ErrorSerializer(serializers.Serializer):
    code = serializers.CharField()
    detail = serializers.CharField()
    fields = serializers.DictField()


class MutationResultSerializer(serializers.Serializer):
    mutation_id = serializers.UUIDField()
    status = serializers.ChoiceField(
        choices=["applied", "merged", "duplicate", "conflict", "rejected"]
    )
    server_version = serializers.IntegerField(allow_null=True)
    errors = ErrorSerializer(many=True)


class PushResponseSerializer(serializers.Serializer):
    results = MutationResultSerializer(many=True)
