"""How an entity type accepts pushes (T026).

A leaf module: it imports only from `apps.core`, so the app services of later tickets can import
it without a cycle (`registry` imports the app services).
"""

from collections.abc import Callable
from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass
from typing import Any

from django.core.exceptions import ImproperlyConfigured

from apps.core.history import save_with_reason

PUSH_REASON = "sync push"  # history_change_reason of every pushed change
_reason = ContextVar("push_reason", default=PUSH_REASON)


@contextmanager
def push_reason(reason):
    """Change the history reason of save_pushed / soft_delete_pushed inside the block (T028)."""
    token = _reason.set(reason)
    try:
        yield
    finally:
        _reason.reset(token)


@dataclass(frozen=True)
class PushHandlers:
    """How an entity type accepts pushes. A missing callable means that operation is not allowed.

    The framework (sync.services.push) has already: checked the mutation shape, deduplicated by
    mutation_id, removed server-owned fields from `data`, turned a create of an existing id into
    an update, loaded the row with SELECT ... FOR UPDATE, checked ownership (created_by or admin)
    and the base_version. `create_batch` gets none of the row checks: `entity_id` is the parent
    record (the visit), and the handler must check that the user may add rows to it. Handlers
    call the entity's service function, which owns everything
    entity-specific: payload validation (T055), project membership, the visit lock (T042),
    section assignment (T048) and quality flags (T056). They save through save_pushed /
    soft_delete_pushed (reason PUSH_REASON, or the one set by push_reason). Raise DRF or
    Django exceptions to reject; the framework turns them into {code, detail, fields}.
    `project_of` is required when `create`, `update` or `delete` is set: a SyncConflict (T027)
    belongs to the project of the row, and a resent `create` of an existing row is merged like an
    update. A missing one fails at import, not on the first conflict.
    """

    create: Callable[..., Any] | None = None  # (user, entity_id, data) -> instance
    update: Callable[..., Any] | None = None  # (user, instance, data) -> instance
    delete: Callable[..., Any] | None = None  # (user, instance) -> None
    create_batch: Callable[..., Any] | None = None  # (user, entity_id, rows) -> None
    project_of: Callable[..., Any] | None = None  # (instance) -> Project

    def __post_init__(self):
        if (self.create or self.update or self.delete) and self.project_of is None:
            raise ImproperlyConfigured(
                "PushHandlers with create, update or delete needs project_of (T027)."
            )


def current_push_reason():
    """The history reason save_pushed would use now, for services that save on their own."""
    return _reason.get()


def save_pushed(obj, user):
    save_with_reason(obj, user, current_push_reason())


def soft_delete_pushed(obj, user):
    obj._change_reason = _reason.get()
    obj._history_user = user
    obj.soft_delete(user)


def insert_batch(model, rows):
    # ON CONFLICT DO NOTHING makes a resent batch harmless. bulk_create skips history and gives no
    # server_version (D-029), which is right for track points (not audited, CONVENTIONS A.5.7).
    model.objects.bulk_create(rows, ignore_conflicts=True)
