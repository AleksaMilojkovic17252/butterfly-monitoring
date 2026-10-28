"""Observation rules and scopes (T044). Push, the REST endpoints and admin call these, not the
models.

A change is built on the instance first (`build_new_observation`, `apply_observation_changes`)
and then saved by `save_observation`, as for visits. An observation of a locked visit refuses
every change (`state.ensure_unlocked`, T042). The field rules (T055) are added here later.
"""

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import exceptions, serializers

from apps.accounts.services import is_admin
from apps.core.history import save_with_reason
from apps.observations.models import ButterflyObservation, Confidence, ValidationStatus
from apps.observations.serializers import ButterflyObservationSyncSerializer
from apps.projects.services import is_member, projects_for
from apps.surveys.models import SurveyVisit, VisitStatus
from apps.surveys.services import visits_for
from apps.surveys.state import ensure_unlocked
from apps.sync.handlers import current_push_reason, soft_delete_pushed

REST_REASON = "REST API"  # history_change_reason of changes made through /observations

# Confidences that always need an expert to look at the record (rule W01 reads the same list).
PENDING_CONFIDENCES = [
    Confidence.PHOTO_REQUIRED,
    Confidence.EXPERT_REVIEW_REQUIRED,
    Confidence.UNKNOWN,
    Confidence.GENUS_ONLY,
]


def observations_for(user):
    """Live observations the user may see: an admin all of them in live projects, a researcher
    only the ones they created, in projects they are still a member of."""
    observations = ButterflyObservation.objects.alive().filter(project__in=projects_for(user))
    if is_admin(user):
        return observations
    return observations.filter(created_by=user)


def pull_observations(user, project):
    """The caller's own observations in the project, deleted rows included (D-049)."""
    return ButterflyObservation.objects.filter(project=project, created_by=user)


def photo_count(observation):
    """How many live photos the observation has."""
    return 0  # TODO(T049): count live photos, there is no Photo model yet


def initial_validation_status(confidence, taxon):
    """`pending` when the record needs an expert's look, `not_required` otherwise (outline 8.8).

    Used on create only. A new observation has no photo yet (photos arrive later, T049), so a
    taxon that requires one is always pending.
    """
    if confidence in PENDING_CONFIDENCES or taxon.photo_required:
        return ValidationStatus.PENDING
    return ValidationStatus.NOT_REQUIRED


def build_new_observation(user, observation_id, data):
    """An unsaved observation from a create payload. `validation_status` is the server's: a value
    the client sent is never read (the sync serializer has no such field)."""
    serializer = ButterflyObservationSyncSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    values = dict(serializer.validated_data)
    values.setdefault("recorded_by", user)

    observation = ButterflyObservation(id=observation_id, created_by=user, **values)
    _check_context(user, observation)
    _check_recorder(user, observation)
    observation.validation_status = initial_validation_status(
        observation.identification_confidence, observation.taxon
    )
    return observation


def apply_observation_changes(user, observation, data):
    """Apply an update payload to `observation` (unsaved). Only the keys in `data` change. The
    validation status is not worked out again (T055 and T057 own it)."""
    _lock_visit(observation)
    if not is_admin(user) and not is_member(user, observation.project_id):
        raise exceptions.PermissionDenied("You are not a member of this observation's project.")
    serializer = ButterflyObservationSyncSerializer(observation, data=data, partial=True)
    serializer.is_valid(raise_exception=True)
    changes = dict(serializer.validated_data)

    for field_name in ("project", "survey_visit"):
        if field_name in changes:
            new_value = changes.pop(field_name)
            if getattr(new_value, "pk", None) != getattr(observation, f"{field_name}_id"):
                raise exceptions.ValidationError({field_name: ["Cannot be changed."]})
    for field_name, value in changes.items():
        setattr(observation, field_name, value)
    if {"transect_section", "taxon"} & changes.keys():
        _check_context(user, observation)
    if "recorded_by" in changes:
        _check_recorder(user, observation)
    return observation


def save_observation(observation, user, history_reason):
    """Check the table's constraints, then save with a history reason.

    The constraints are checked here so a broken rule comes back as a validation error with a
    message, not as a database error.
    """
    try:
        observation.validate_constraints()
    except DjangoValidationError as error:
        raise exceptions.ValidationError(serializers.as_serializer_error(error)) from error
    save_with_reason(observation, user, history_reason)
    # The trigger wrote a new server_version; the instance still holds the old one (D-029).
    observation.refresh_from_db(fields=["server_version"])
    return observation


def delete_observation(user, observation, reason):
    """Soft delete `observation`, with `reason` as its history reason."""
    _lock_visit(observation)
    observation._change_reason = reason
    observation._history_user = user
    observation.soft_delete(user)


# REST (views.py)


def create_observation(user, observation_id, data):
    return save_observation(build_new_observation(user, observation_id, data), user, REST_REASON)


def update_observation(user, observation, data):
    apply_observation_changes(user, observation, data)
    return save_observation(observation, user, REST_REASON)


def remove_observation(user, observation):
    delete_observation(user, observation, REST_REASON)


# Push (sync registry). The framework has checked ownership and the base version.


def push_create(user, observation_id, data):
    observation = build_new_observation(user, observation_id, data)
    return save_observation(observation, user, current_push_reason())


def push_update(user, observation, data):
    apply_observation_changes(user, observation, data)
    return save_observation(observation, user, current_push_reason())


def push_delete(user, observation):
    _lock_visit(observation)
    soft_delete_pushed(observation, user)


def project_of(observation):
    return observation.project


def guard_observation(user, observation):
    """Push guard (`PushHandlers.guard`): runs before the merge, so a change to an observation of
    a locked visit is rejected even when its base version is stale (T042)."""
    if observation.survey_visit_id is not None:
        ensure_unlocked(observation.survey_visit)


# Admin (admin.py)


def is_locked(observation):
    """For admin pages: an observation of a locked visit opens read-only (T042)."""
    visit = observation.survey_visit
    return visit is not None and visit.status == VisitStatus.LOCKED


def check_admin_edit(admin_user, observation, changed_fields):
    """The rules for an admin's edit of `observation` (unsaved, with the form's values): its visit
    must not be locked, and a changed section, taxon or recorder must fit. Raises DRF exceptions."""
    if observation.survey_visit_id is not None:
        ensure_unlocked(observation.survey_visit)
    if {"transect_section", "taxon"} & set(changed_fields):
        _check_context(admin_user, observation)
    if "recorded_by" in changed_fields:
        _check_recorder(admin_user, observation)


def admin_save_observation(observation, admin_user, reason, changed_fields):
    check_admin_edit(admin_user, observation, changed_fields)
    return save_observation(observation, admin_user, reason or "admin edit")


def _lock_visit(observation):
    """Lock the observation's visit for the rest of the transaction and refuse a locked one.
    Done first, so a lock that lands while another request works on the visit is not missed."""
    if observation.survey_visit_id is None:
        return
    visit = SurveyVisit.objects.select_for_update().get(pk=observation.survey_visit_id)
    ensure_unlocked(visit)
    observation.survey_visit = visit


def _check_context(user, observation):
    """The project, taxon, visit and section of `observation` must fit together."""
    project = observation.project
    if project.deleted_at is not None:
        raise exceptions.ValidationError({"project": ["This project was deleted."]})
    if not is_admin(user) and not is_member(user, project.pk):
        raise exceptions.PermissionDenied("You are not a member of this project.")
    if observation.taxon.deleted_at is not None:
        # A retired taxon is still allowed (D-043): an old list may still name it.
        raise exceptions.ValidationError({"taxon": ["This taxon was deleted."]})

    visit = None
    if observation.survey_visit_id is not None:
        visit = visits_for(user).select_for_update().filter(pk=observation.survey_visit_id).first()
        if visit is None:
            raise exceptions.ValidationError({"survey_visit": ["This visit was not found."]})
        if visit.project_id != project.pk:
            raise exceptions.ValidationError(
                {"survey_visit": ["This visit is not in the project."]}
            )
        ensure_unlocked(visit)

    section = observation.transect_section
    if section is not None:
        if section.deleted_at is not None:
            raise exceptions.ValidationError({"transect_section": ["This section was deleted."]})
        if visit is not None:
            if section.transect_id != visit.transect_id:
                raise exceptions.ValidationError(
                    {"transect_section": ["This section is not on the visit's transect."]}
                )
        elif section.transect.project_id != project.pk or section.transect.deleted_at is not None:
            raise exceptions.ValidationError(
                {"transect_section": ["This section is not on a transect of the project."]}
            )


def _check_recorder(user, observation):
    """A researcher always records as themselves; an admin may name any member of the project (or
    another admin)."""
    recorder = observation.recorded_by
    if is_admin(user):
        if not is_admin(recorder) and not is_member(recorder, observation.project_id):
            raise exceptions.ValidationError(
                {"recorded_by": ["The recorder must be a member of the project."]}
            )
    elif recorder.pk != user.pk:
        raise exceptions.ValidationError(
            {"recorded_by": ["You can only record observations as yourself."]}
        )
