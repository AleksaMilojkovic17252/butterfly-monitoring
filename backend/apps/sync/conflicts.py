"""Pull side of SyncConflict (T027). Kept apart from `services`/`serializers`, which import the
registry that registers this type."""

from rest_framework import serializers

from apps.sync.models import SyncConflict


class SyncConflictSyncSerializer(serializers.ModelSerializer):
    """A conflict row as pulled to its owner's phone (T027). Read-only: the phone never writes it.

    The payload and snapshots stay on the server; the phone only needs to know a conflict exists
    and how it ended.
    """

    class Meta:
        model = SyncConflict
        fields = [
            "id",
            "entity_type",
            "entity_id",
            "operation",
            "conflicting_fields",
            "status",
            "created_at",
            "resolved_at",
            "resolution_note",
            "server_version",
            "deleted_at",
        ]


def pull_conflicts(user, project):
    """The caller's own conflicts in the project, deleted rows included (D-049)."""
    return SyncConflict.objects.filter(owner=user, project=project)
