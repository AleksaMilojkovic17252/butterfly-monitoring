"""Visit and track rules and scopes (T034, T036). Push, the REST endpoints and admin call these,
not the models.

A change is built on the instance first (`build_new_visit`, `apply_visit_changes`) and then
saved by `save_visit`, so push can add the server's completed -> synced step in the same save.
A locked visit and its track points refuse every change (`state.ensure_unlocked`, T042).
`save_visit` checks the input rules of `surveys.rules` (T055), so REST, push and admin are all
covered.
"""

import json
from decimal import Decimal

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import connection
from django.shortcuts import get_object_or_404
from rest_framework import exceptions, serializers

from apps.accounts.services import is_admin
from apps.core.history import save_with_reason
from apps.environment import services as environment_services
from apps.projects.services import is_member, projects_for
from apps.surveys import rules
from apps.surveys.models import CancelReason, SurveyTrackPoint, SurveyVisit, VisitStatus
from apps.surveys.serializers import SurveyTrackPointSyncSerializer, SurveyVisitSyncSerializer
from apps.surveys.state import InvalidTransition, ensure_unlocked, move_to, transition
from apps.sync.handlers import current_push_reason, insert_batch

REST_REASON = "REST API"  # history_change_reason of changes made through /survey-visits

# Statuses in which the walk is over, so the server works out distance_walked_m (T036).
FINISHED_STATUSES = [VisitStatus.COMPLETED, VisitStatus.SYNCED]
# A visit in these has its manual weather copied to environmental snapshots (T063, D-076).
# `locked` is left out: a locked visit cannot change, and Unlock moves it to `reviewed`.
SNAPSHOT_STATUSES = [VisitStatus.COMPLETED, VisitStatus.SYNCED, VisitStatus.REVIEWED]

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


def pull_track_points(user, project):
    """Track points are not pulled (D-060): the phone that recorded them already has them, and
    sending each pushed batch straight back would double the track traffic."""
    return SurveyTrackPoint.objects.none()


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
    ensure_unlocked(visit)
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


def save_visit(visit, user, history_reason, check_rules=True):
    """Check the input rules (T055) and the table's constraints, then save with a history reason.

    They are checked here so a broken rule comes back as a validation error with a message (the
    rule ID, e.g. `{"temperature_end_c": ["V05"]}`), not as a database error. `check_rules=False`
    leaves the input rules out (the unlock, which changes no field a rule reads); the table's
    constraints are always checked.
    """
    if check_rules:
        errors = rules.validate_visit(_rule_data(visit), _rule_context(visit))
        if errors:
            raise exceptions.ValidationError(errors)
    try:
        visit.validate_constraints()
    except DjangoValidationError as error:
        raise exceptions.ValidationError(serializers.as_serializer_error(error)) from error
    save_with_reason(visit, user, history_reason)
    # The trigger wrote a new server_version; the instance still holds the old one (D-029).
    visit.refresh_from_db(fields=["server_version"])
    if visit.status in SNAPSHOT_STATUSES:
        environment_services.refresh_manual_snapshots(visit)
    return visit


# REST (views.py)


def create_visit(user, visit_id, data):
    return save_visit(build_new_visit(user, visit_id, data), user, REST_REASON)


def update_visit(user, visit, data):
    apply_visit_changes(user, visit, data)
    set_distance_if_finished(visit)
    return save_visit(visit, user, REST_REASON)


def complete_visit(user, visit, data):
    """Finish a visit: in_progress -> completed, with any end fields in `data` in the same save."""
    ensure_unlocked(visit)  # before the status check, so a locked visit says why
    if visit.status != VisitStatus.IN_PROGRESS:
        raise InvalidTransition(f"Only a visit in progress can be completed, not {visit.status}.")
    changes = {**data, "status": VisitStatus.COMPLETED}
    apply_visit_changes(user, visit, changes)
    set_distance_if_finished(visit)
    return save_visit(visit, user, REST_REASON)


# Push (sync registry). The framework has checked ownership and the base version.


def push_create(user, visit_id, data):
    visit = build_new_visit(user, visit_id, data)
    mark_synced_if_completed(visit)
    set_distance_if_finished(visit)
    return save_visit(visit, user, current_push_reason())


def push_update(user, visit, data):
    apply_visit_changes(user, visit, data)
    mark_synced_if_completed(visit)
    set_distance_if_finished(visit)
    return save_visit(visit, user, current_push_reason())


def push_track_points(user, visit_id, rows):
    """`create_batch` handler: store a batch of GPS fixes of one visit (T036).

    One bad row rejects the whole batch. A point id the server already has is skipped
    (`insert_batch`, ON CONFLICT DO NOTHING), so a resent batch changes nothing. The visit is
    locked for the rest of the push, so a completion in the same push sees these points.
    """
    visit = get_object_or_404(SurveyVisit.objects.alive().select_for_update(), pk=visit_id)
    if not is_admin(user):
        if visit.created_by_id != user.pk:
            raise exceptions.PermissionDenied("You can only add track points to your own visits.")
        if not is_member(user, visit.project_id):
            raise exceptions.PermissionDenied("You are not a member of this visit's project.")
    ensure_unlocked(visit)

    serializer = SurveyTrackPointSyncSerializer(data=rows, many=True)
    if not serializer.is_valid():
        # DRF reports {row index: {field: messages}}. Name the row in each field instead, e.g.
        # "rows[3].heading_deg", so the phone's sync error message says which point was refused.
        raise exceptions.ValidationError(
            {
                f"rows[{index}].{field}": messages
                for index, row_errors in serializer.errors.items()
                for field, messages in row_errors.items()
            }
        )
    points = [
        SurveyTrackPoint(survey_visit=visit, created_by=user, updated_by=user, **values)
        for values in serializer.validated_data
    ]
    insert_batch(SurveyTrackPoint, points)
    refresh_distance(visit, user)


def walked_distance_m(visit):
    """Metres walked along the visit's track, or None with fewer than two usable points.

    Points are joined in recorded order (sequence number breaks ties). A point whose accuracy is
    worse than twice the protocol's warning value is left out; one without an accuracy is kept.
    Raw SQL, because Django's MakeLine aggregate cannot order its input.
    """
    max_accuracy_m = visit.project.protocol.gps_accuracy_warning_m * 2
    with connection.cursor() as db:
        db.execute(
            """
            SELECT count(*),
                   ST_Length(ST_MakeLine(geometry ORDER BY recorded_at, sequence_number)::geography)
            FROM survey_track_point
            WHERE survey_visit_id = %s AND deleted_at IS NULL
              AND (accuracy_m IS NULL OR accuracy_m <= %s)
            """,
            [visit.pk, max_accuracy_m],
        )
        point_count, length_m = db.fetchone()
    if point_count < 2:
        return None
    return Decimal(str(length_m)).quantize(Decimal("0.1"))


def set_distance_if_finished(visit):
    """Put the server's distance on a finished visit (unsaved). With fewer than two usable points
    the value the phone sent stays."""
    if visit.status not in FINISHED_STATUSES:
        return
    distance_m = walked_distance_m(visit)
    if distance_m is not None:
        visit.distance_walked_m = distance_m


def refresh_distance(visit, user):
    """After new points: work the distance out again if the visit is already finished, and save
    only when it changed. A visit created and finished offline reaches the server as one create
    before its points (the phone's queue merges the two, D-051), so this is where it gets its
    distance."""
    before = visit.distance_walked_m
    set_distance_if_finished(visit)
    if visit.distance_walked_m != before:
        save_visit(visit, user, current_push_reason())


def route_geojson(visit):
    """The visit's route as `(GeoJSON LineString or None, point count)`, for the admin map.

    Every live point in recorded order, unfiltered; None with fewer than two points.
    """
    with connection.cursor() as db:
        db.execute(
            """
            SELECT count(*),
                   ST_AsGeoJSON(ST_MakeLine(geometry ORDER BY recorded_at, sequence_number))
            FROM survey_track_point
            WHERE survey_visit_id = %s AND deleted_at IS NULL
            """,
            [visit.pk],
        )
        point_count, line = db.fetchone()
    if point_count < 2:
        return None, point_count
    return json.loads(line), point_count


def project_of(visit):
    return visit.project


def guard_visit(user, visit):
    """Push guard (`PushHandlers.guard`): runs before the merge, so an update of a locked visit is
    rejected even when its base version is stale, instead of becoming a conflict (T042)."""
    ensure_unlocked(visit)


# Admin (admin.py)


def mark_reviewed(visit, admin_user):
    # locked -> reviewed is the unlock, which needs a reason (`unlock_visit`), so a locked visit
    # is refused here.
    ensure_unlocked(visit)
    transition(visit, VisitStatus.REVIEWED, admin_user)
    return save_visit(visit, admin_user, "marked reviewed")


def missing_track_points(visit):
    """`(points on the server, points the phone recorded)` when the server has fewer live track
    points than the count the phone sent on finish (T040, D-062); otherwise None. A visit without
    a count (finished before T040, or through REST) is never short."""
    if visit.track_point_count is None:
        return None
    server_count = visit.track_points.filter(deleted_at__isnull=True).count()
    if server_count < visit.track_point_count:
        return server_count, visit.track_point_count
    return None


def lock_visit(visit, admin_user, reason, allow_missing_points=False):
    """Lock a finished visit, with the admin's reason as the lock reason and the history reason.

    Refused while the server has fewer track points than the phone recorded, because a lock that
    lands before the last batches makes the phone's remaining points fail with `visit_locked`;
    `allow_missing_points` overrides that. Locking a locked visit fails in `transition()`.
    The caller holds the visit row `FOR UPDATE`: `push_track_points` locks it too, so the point
    count and the lock cannot interleave with a batch.
    """
    shortfall = None if allow_missing_points else missing_track_points(visit)
    if shortfall:
        raise exceptions.ValidationError(
            {
                "track_point_count": [
                    f"The server has {shortfall[0]} of {shortfall[1]} track points; wait for the "
                    "phone to sync, or tick 'Lock even if track points are missing'."
                ]
            },
            code="track_points_missing",
        )
    transition(visit, VisitStatus.LOCKED, admin_user, reason=reason)
    return save_visit(visit, admin_user, reason)


def unlock_visit(visit, admin_user, reason):
    """Unlock a locked visit: it becomes `reviewed` and editable again. `transition()` clears the
    lock fields; the history row keeps them and carries the admin's reason. The caller holds the
    visit row `FOR UPDATE`.

    The input rules are not run: a locked visit must always be unlockable, even when a rule or the
    protocol changed after the lock (the page is read-only, so the admin could not fix it first).
    The admin corrects the data once the visit is editable."""
    if visit.status != VisitStatus.LOCKED:
        raise InvalidTransition("This visit is not locked.")
    transition(visit, VisitStatus.REVIEWED, admin_user)
    return save_visit(visit, admin_user, reason, check_rules=False)


def is_locked(visit):
    """For admin pages: a locked visit and its records open read-only (T042)."""
    return visit.status == VisitStatus.LOCKED


def check_admin_edit(admin_user, visit, changed_fields):
    """The checks for an admin's edit of `visit` (unsaved, with the form's values): it must not be
    locked, a changed transect or observer must fit the project, and the input rules (V05-V09)
    must hold, so a refused edit shows as a form error and not when `save_visit` runs after the
    form. Raises DRF exceptions."""
    _check_admin_scope(admin_user, visit, changed_fields)
    errors = rules.validate_visit(_rule_data(visit), _rule_context(visit))
    if errors:
        raise exceptions.ValidationError(errors)


def _check_admin_scope(admin_user, visit, changed_fields):
    # The part of check_admin_edit that is not an input rule: `save_visit` checks the rules.
    ensure_unlocked(visit)
    if "transect" in changed_fields:
        _check_project_and_transect(admin_user, visit)
    if "observer" in changed_fields:
        _check_observer(admin_user, visit)


def admin_save_visit(visit, admin_user, reason, changed_fields):
    """Save an admin's edit of an unlocked visit. The distance is not worked out again: it is
    read-only in the admin. The form already ran `check_admin_edit`; the input rules run again in
    `save_visit`, the one place that always checks them."""
    _check_admin_scope(admin_user, visit, changed_fields)
    return save_visit(visit, admin_user, reason or "admin edit")


def _rule_data(visit):
    """The visit's values (unsaved, as they will be stored) that the input rules read."""
    return {
        name: getattr(visit, name)
        for name in (
            "status",
            "survey_method",
            "precipitation",
            "cancel_reason",
            "started_at",
            "zero_observation_confirmed",
            "weather_missing_reason",
            "temperature_start_c",
            "temperature_end_c",
            "wind_beaufort_start",
            "wind_beaufort_end",
            "cloud_cover_start_pct",
            "cloud_cover_end_pct",
        )
    }


def _rule_context(visit):
    """What the input rules need from the database: the protocol and, for a visit confirmed as a
    true zero, how many transect observations it has (V06)."""
    transect_observation_count = 0
    if visit.zero_observation_confirmed and not visit._state.adding:
        transect_observation_count = visit.observations.filter(
            deleted_at__isnull=True, source="transect"
        ).count()
    return rules.VisitRuleContext(
        protocol=visit.project.protocol, transect_observation_count=transect_observation_count
    )


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
