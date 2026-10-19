"""Request, tombstone and response shapes of the pull endpoint (T025)."""

from drf_spectacular.utils import PolymorphicProxySerializer
from rest_framework import serializers

from apps.sync.registry import ENTITIES

DEFAULT_PULL_LIMIT = 1000
MAX_PULL_LIMIT = 5000
MAX_CURSOR = 2**63 - 1  # server_version is a bigint


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
