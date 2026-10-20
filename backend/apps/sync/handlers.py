"""How an entity type accepts pushes (T026).

A leaf module: it imports only from `apps.core`, so the app services of later tickets can import
it without a cycle (`registry` imports the app services).
"""

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from apps.core.history import save_with_reason

PUSH_REASON = "sync push"  # history_change_reason of every pushed change


@dataclass(frozen=True)
class PushHandlers:
    """How an entity type accepts pushes. A missing callable means that operation is not allowed.

    The framework (sync.services.push) has already: checked the mutation shape, deduplicated by
    mutation_id, removed server-owned fields from `data`, turned a create of an existing id into
    an update, loaded the row with SELECT ... FOR UPDATE, checked ownership (created_by or admin)
    and the base_version. Handlers call the entity's service function, which owns everything
    entity-specific: payload validation (T055), project membership, the visit lock (T042),
    section assignment (T048) and quality flags (T056). They save with PUSH_REASON. Raise DRF or
    Django exceptions to reject; the framework turns them into {code, detail, fields}.
    """

    create: Callable[..., Any] | None = None  # (user, entity_id, data) -> instance
    update: Callable[..., Any] | None = None  # (user, instance, data) -> instance
    delete: Callable[..., Any] | None = None  # (user, instance) -> None
    create_batch: Callable[..., Any] | None = None  # (user, entity_id, rows) -> None


def save_pushed(obj, user):
    save_with_reason(obj, user, PUSH_REASON)


def soft_delete_pushed(obj, user):
    obj._change_reason = PUSH_REASON
    obj._history_user = user
    obj.soft_delete(user)


def insert_batch(model, rows):
    # ON CONFLICT DO NOTHING makes a resent batch harmless. bulk_create skips history and gives no
    # server_version (D-029), which is right for track points (not audited, CONVENTIONS A.5.7).
    model.objects.bulk_create(rows, ignore_conflicts=True)
