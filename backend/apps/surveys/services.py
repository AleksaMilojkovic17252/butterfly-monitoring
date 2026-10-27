"""Visit rules and scopes (T034). Push, the REST endpoints and admin call these, not the models.

A change is built on the instance first (`build_new_visit`, `apply_visit_changes`) and then
saved by `save_visit`, so push can add the server's completed -> synced step in the same save.
The visit lock (T042) and the field rules per status (T055) are added here later.
"""

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import exceptions, serializers

from apps.accounts.services import is_admin
from apps.core.history import save_with_reason
from apps.projects.services import is_member, projects_for
from apps.surveys.models import CancelReason, SurveyVisit, VisitStatus
from apps.surveys.serializers import SurveyVisitSyncSerializer
from apps.surveys.state import InvalidTransition, move_to, transition
from apps.sync.handlers import current_push_reason

REST_REASON = "REST API"  # history_change_reason of changes made through /survey-visits

# Statuses that count as a walked visit in the transect stats: not a draft, not cancelled.
COUNTED_STATUSES = [
    VisitStatus.IN_PROGRESS,
    VisitStatus.COMPLETED,
    VisitStatus.SYNCED,
    VisitStatus.REVIEWED,
    VisitStatus.LOCKED,
]


def visits_for(user):
    """Live visits the user may see: an admin all of them in live projects, a researcher only
    the ones they created, in projects they are still a member of."""
    visits = SurveyVisit.objects.alive().filter(project__in=projects_for(user))
    if is_admin(user):
        return visits
    return visits.filter(created_by=user)


def counted_visits(user):
    """The visits the transect stats count: live, walked (COUNTED_STATUSES), and the caller's
    own unless the caller is an admin."""
    visits = SurveyVisit.objects.alive().filter(status__in=COUNTED_STATUSES)
    if is_admin(user):
        return visits
    return visits.filter(created_by=user)


def pull_visits(user, project):
    """The caller's own visits in the project, deleted rows included (D-049)."""
    return SurveyVisit.objects.filter(project=project, created_by=user)


def build_new_visit(user, visit_id, data):
    """An unsaved visit from a create payload. Its status is reached from `draft` through
    `move_to()`, so a visit started or finished offline follows the same rules."""
    serializer = SurveyVisitSyncSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    values = dict(serializer.validated_data)
    target_status = values.pop("status", VisitStatus.DRAFT)
    cancel_reason = values.pop("cancel_reason", "")
    values.setdefault("observer", user)

    visit = SurveyVisit(id=visit_id, created_by=user, **values)
    _check_project_and_transect(user, visit)
    _check_observer(user, visit)
    move_to(visit, target_status, user, reason=cancel_reason)
    if target_status != VisitStatus.CANCELLED and cancel_reason:
        raise exceptions.ValidationError(
            {"cancel_reason": ["Only allowed when the status is cancelled."]}
        )
    return visit


def apply_visit_changes(user, visit, data):
    """Apply an update payload to `visit` (unsaved). Only the keys in `data` change; a status
    change goes through `move_to()`, which may take several app moves at once (D-051)."""
    if not is_admin(user) and not is_member(user, visit.project_id):
        raise exceptions.PermissionDenied("You are not a member of this visit's project.")
    serializer = SurveyVisitSyncSerializer(visit, data=data, partial=True)
    serializer.is_valid(raise_exception=True)
    changes = dict(serializer.validated_data)
    target_status = changes.pop("status", visit.status)
    cancel_reason = changes.pop("cancel_reason", None)

    new_project = changes.pop("project", None)
    if new_project is not None and new_project.pk != visit.project_id:
        raise exceptions.ValidationError({"project": ["A visit cannot move to another project."]})
    for field_name, value in changes.items():
        setattr(visit, field_name, value)
    if "transect" in changes:
        _check_project_and_transect(user, visit)
    if "observer" in changes:
        _check_observer(user, visit)

    # `synced` is "completed, and the server has it". A phone that has not pulled since its push
    # still holds `completed`; sending that again is no change, not a move back.
    if target_status == VisitStatus.COMPLETED and visit.status == VisitStatus.SYNCED:
        target_status = VisitStatus.SYNCED

    if target_status != visit.status:
        move_to(visit, target_status, user, reason=cancel_reason)
    elif cancel_reason is not None and cancel_reason != visit.cancel_reason:
        if visit.status != VisitStatus.CANCELLED:
            raise exceptions.ValidationError(
                {"cancel_reason": ["Only allowed when the status is cancelled."]}
            )
        if cancel_reason not in CancelReason.values:
            raise exceptions.ValidationError(
                {"cancel_reason": [f"Must be one of {CancelReason.values}."]}
            )
        visit.cancel_reason = cancel_reason
    return visit


def mark_synced_if_completed(visit):
    """The server's own step on push: a completed visit becomes `synced` (ticket d). Not a
    signal, so admin and REST saves do not trigger it."""
    if visit.status == VisitStatus.COMPLETED:
        transition(visit, VisitStatus.SYNCED, actor=None)


def save_visit(visit, user, history_reason):
    """Check the table's constraints, then save with a history reason.

    The constraints are checked here so a broken rule comes back as a validation error with a
    message, not as a database error.
    """
    try:
        visit.validate_constraints()
    except DjangoValidationError as error:
        raise exceptions.ValidationError(serializers.as_serializer_error(error)) from error
    save_with_reason(visit, user, history_reason)
    # The trigger wrote a new server_version; the instance still holds the old one (D-029).
    visit.refresh_from_db(fields=["server_version"])
    return visit


# REST (views.py)


def create_visit(user, visit_id, data):
    return save_visit(build_new_visit(user, visit_id, data), user, REST_REASON)


def update_visit(user, visit, data):
    return save_visit(apply_visit_changes(user, visit, data), user, REST_REASON)


def complete_visit(user, visit, data):
    """Finish a visit: in_progress -> completed, with any end fields in `data` in the same save."""
    if visit.status != VisitStatus.IN_PROGRESS:
        raise InvalidTransition(f"Only a visit in progress can be completed, not {visit.status}.")
    changes = {**data, "status": VisitStatus.COMPLETED}
    return save_visit(apply_visit_changes(user, visit, changes), user, REST_REASON)


# Push (sync registry). The framework has checked ownership and the base version.


def push_create(user, visit_id, data):
    visit = build_new_visit(user, visit_id, data)
    mark_synced_if_completed(visit)
    return save_visit(visit, user, current_push_reason())


def push_update(user, visit, data):
    apply_visit_changes(user, visit, data)
    mark_synced_if_completed(visit)
    return save_visit(visit, user, current_push_reason())


def project_of(visit):
    return visit.project


# Admin (admin.py)


def mark_reviewed(visit, admin_user):
    transition(visit, VisitStatus.REVIEWED, admin_user)
    return save_visit(visit, admin_user, "marked reviewed")


def _check_project_and_transect(user, visit):
    project = visit.project
    if project.deleted_at is not None:
        raise exceptions.ValidationError({"project": ["This project was deleted."]})
    if not is_admin(user) and not is_member(user, project.pk):
        raise exceptions.PermissionDenied("You are not a member of this project.")
    transect = visit.transect
    if transect.project_id != project.pk:
        raise exceptions.ValidationError({"transect": ["This transect is not in the project."]})
    if transect.deleted_at is not None:
        raise exceptions.ValidationError({"transect": ["This transect was deleted."]})


def _check_observer(user, visit):
    """A researcher is always the observer of their own visits; an admin may name any member of
    the project (or another admin)."""
    observer = visit.observer
    if is_admin(user):
        if not is_admin(observer) and not is_member(observer, visit.project_id):
            raise exceptions.ValidationError(
                {"observer": ["The observer must be a member of the project."]}
            )
    elif observer.pk != user.pk:
        raise exceptions.ValidationError({"observer": ["You can only record your own visits."]})
