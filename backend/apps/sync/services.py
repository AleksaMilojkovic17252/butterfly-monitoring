"""Sync rules. The pull view calls `pull`; push (T026) will add its handlers here."""

from django.db import connection, transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone

from apps.projects.services import projects_for
from apps.sync.registry import ENTITIES
from apps.sync.serializers import TombstoneSerializer


def pull(user, project_id, cursor, limit):
    """One page of changes after `cursor` for `project_id`, ordered by `server_version`.

    Raises Http404 when the user cannot see the project (D-036).
    """
    # durable: inside an outer transaction the SET below would fail with an unclear error.
    with transaction.atomic(durable=True):
        # One snapshot for the whole page. The page is built from one query per entity; under
        # READ COMMITTED each would see its own snapshot, so a row committed in between could
        # show up in a later query while an earlier type misses a lower version that committed
        # at the same time, and next_cursor would jump past it. With one snapshot, and versions
        # committing in order (T005 advisory lock, D-029), every page is a prefix of the commit
        # order and nothing is skipped. Must be the first statement of the transaction.
        with connection.cursor() as db:
            db.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")

        project = get_object_or_404(projects_for(user), pk=project_id)
        scopes = [(e, e.pull_scope(user, project)) for e in ENTITIES]

        # Phase 1: find the page boundary from the versions alone. Versions come from one global
        # sequence, so they are unique and there are no ties.
        versions = []
        for _, scope in scopes:
            versions.extend(
                scope.filter(server_version__gt=cursor)
                .order_by("server_version")
                .values_list("server_version", flat=True)[: limit + 1]
            )
        versions.sort()
        has_more = len(versions) > limit
        if has_more:
            next_cursor = versions[limit - 1]
        else:
            next_cursor = versions[-1] if versions else cursor

        # Phase 2: fetch the rows up to the boundary.
        changes = {}
        for entity, scope in scopes:
            rows = []
            if versions:
                rows = scope.filter(
                    server_version__gt=cursor, server_version__lte=next_cursor
                ).order_by("server_version")
            changes[entity.entity_type] = [
                TombstoneSerializer(row).data
                if row.deleted_at is not None
                else entity.serializer(row).data
                for row in rows
            ]

    return {
        "changes": changes,
        "next_cursor": next_cursor,
        "has_more": has_more,
        "server_time": timezone.now(),
    }
