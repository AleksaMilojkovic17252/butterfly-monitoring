"""The visit lifecycle (T034, outline 7.2). Push, the REST endpoints and admin all go through
`transition()`.

The same table is in docs/requirements/visit-states.json and in the app
(`lib/features/visits/domain/visit_status.dart`); `surveys/tests.py` checks this copy against the
JSON. A plain dict, not django-fsm (ticket).
"""

from django.utils import timezone
from rest_framework import exceptions

from apps.accounts.services import is_admin
from apps.surveys.models import CancelReason, VisitStatus

# Who may make a move: the visit's creator through the app ("app"; an admin may act for them),
# the push service itself ("server"), or an admin ("admin").
APP = "app"
SERVER = "server"
ADMIN = "admin"

# (from_status, to_status) -> who may make that move.
TRANSITIONS = {
    (VisitStatus.DRAFT, VisitStatus.IN_PROGRESS): APP,
    (VisitStatus.DRAFT, VisitStatus.CANCELLED): APP,
    (VisitStatus.IN_PROGRESS, VisitStatus.CANCELLED): APP,
    (VisitStatus.IN_PROGRESS, VisitStatus.COMPLETED): APP,
    (VisitStatus.COMPLETED, VisitStatus.SYNCED): SERVER,
    (VisitStatus.COMPLETED, VisitStatus.REVIEWED): ADMIN,
    (VisitStatus.SYNCED, VisitStatus.REVIEWED): ADMIN,
    (VisitStatus.COMPLETED, VisitStatus.LOCKED): ADMIN,
    (VisitStatus.SYNCED, VisitStatus.LOCKED): ADMIN,
    (VisitStatus.REVIEWED, VisitStatus.LOCKED): ADMIN,
    (VisitStatus.LOCKED, VisitStatus.REVIEWED): ADMIN,  # unlock (T043)
}

# Who each actor is, for error messages.
_ACTOR_NAMES = {APP: "the visit's creator", SERVER: "the server", ADMIN: "an admin"}


def steps_between(from_status, to_status):
    """The moves that take a visit from `from_status` to `to_status`, in order.

    The direct move when the table has one. Otherwise the shortest chain of app moves: the phone
    works offline and its queue merges unsent changes (D-051), so one push can carry several app
    moves, e.g. draft -> completed for a visit started and finished offline. None when there is
    no way; [] when the status does not change.
    """
    if from_status == to_status:
        return []
    if (from_status, to_status) in TRANSITIONS:
        return [to_status]
    # Breadth-first over the app moves, so the chain is the shortest one.
    paths_to_check = [[from_status]]
    seen_statuses = {from_status}
    while paths_to_check:
        path = paths_to_check.pop(0)
        for (step_from, step_to), actor in TRANSITIONS.items():
            if actor != APP or step_from != path[-1] or step_to in seen_statuses:
                continue
            if step_to == to_status:
                return [*path[1:], step_to]
            seen_statuses.add(step_to)
            paths_to_check.append([*path, step_to])
    return None


def move_to(visit, to, actor, reason=None):
    """Move `visit` to `to` through every step of `steps_between`, each checked by
    `transition()`. On the instance only, like `transition()`."""
    steps = steps_between(visit.status, to)
    if steps is None:
        raise InvalidTransition(f"A visit cannot go from {visit.status} to {to}.")
    for next_status in steps:
        transition(visit, next_status, actor, reason=reason)


class InvalidTransition(exceptions.APIException):
    """A status change the lifecycle does not allow, or one the actor may not make."""

    status_code = 409
    default_code = "invalid_transition"
    default_detail = "This status change is not allowed."


def transition(visit, to, actor, reason=None):
    """Move `visit` to status `to`, on the instance only: the caller saves it with its own
    history reason.

    `actor` is the user making the change, or None for the server's own step (completed to
    synced in push). `reason` is the `cancel_reason` for `cancelled` (a `CancelReason` value) and
    the lock reason for `locked`; other moves ignore it. Raises `InvalidTransition`.
    """
    from_status = visit.status
    allowed_actor = TRANSITIONS.get((from_status, to))
    if allowed_actor is None:
        raise InvalidTransition(f"A visit cannot go from {from_status} to {to}.")
    if not _actor_may(allowed_actor, actor, visit):
        actor_name = _ACTOR_NAMES[allowed_actor]
        raise InvalidTransition(f"Only {actor_name} may move a visit from {from_status} to {to}.")

    if to == VisitStatus.CANCELLED:
        if reason not in CancelReason.values:
            raise exceptions.ValidationError(
                {"cancel_reason": [f"Required when cancelling, one of {CancelReason.values}."]}
            )
        visit.cancel_reason = reason
    if to == VisitStatus.LOCKED:
        if not reason:
            raise exceptions.ValidationError({"lock_reason": ["Required when locking."]})
        visit.locked_at = timezone.now()
        visit.locked_by = actor
        visit.lock_reason = reason
    if from_status == VisitStatus.LOCKED:
        # Unlocked: the history keeps who locked it and why.
        visit.locked_at = None
        visit.locked_by = None
        visit.lock_reason = ""
    visit.status = to


def _actor_may(allowed_actor, actor, visit):
    if allowed_actor == SERVER:
        return actor is None
    if actor is None:
        return False
    if allowed_actor == ADMIN:
        return is_admin(actor)
    # APP: the creator; a new visit has no creator yet, so the caller creating it counts.
    visit_owner_id = visit.created_by_id or actor.pk
    return visit_owner_id == actor.pk or is_admin(actor)
