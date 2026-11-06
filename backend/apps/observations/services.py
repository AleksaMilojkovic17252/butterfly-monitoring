"""Observation rules and scopes (T044) and photo records and uploads (T049). Push, the REST
endpoints and admin call these, not the models.

A change is built on the instance first (`build_new_observation`, `apply_observation_changes`)
and then saved by `save_observation`, as for visits. An observation of a locked visit refuses
every change (`state.ensure_unlocked`, T042). `save_observation` checks the input rules of
`observations.rules` (T055), so REST, push and admin are all covered. Photos follow the same
shape (`build_new_photo`, `apply_photo_changes`, `save_photo`); the bytes go through
`init_upload`, `store_content` and `complete_upload`, with storage work in `photo_storage`.
"""

import hashlib
import tempfile

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Q
from django.utils import timezone
from PIL import Image
from rest_framework import exceptions, serializers

from apps.accounts.services import is_admin
from apps.core.history import save_with_reason
from apps.observations import photo_storage, rules
from apps.observations.models import (
    MAX_PHOTO_BYTES,
    PHOTO_MIME_TYPES,
    ButterflyObservation,
    Confidence,
    Photo,
    UploadStatus,
    ValidationStatus,
)
from apps.observations.serializers import ButterflyObservationSyncSerializer, PhotoSyncSerializer
from apps.projects.services import ensure_project_open, is_member, projects_for
from apps.resources.models import ResourceType
from apps.resources.rules import PLANT_LINK_ROLE_NAMES, PLANT_LINK_ROLES
from apps.resources.services import own_plant_resources_for, plant_resources_for
from apps.surveys.models import SurveyVisit, VisitStatus
from apps.surveys.services import visits_for
from apps.surveys.state import ensure_unlocked
from apps.sync.handlers import current_client_time, current_push_reason, soft_delete_pushed
from apps.transects.services import nearest_section_id
from apps.validation import flags

REST_REASON = "REST API"  # history_change_reason of changes made through /observations
REASSIGN_REASON = "reassign sections"  # history_change_reason of the admin action (T048)
UPLOAD_REASON = "photo upload"  # history_change_reason of the server's own upload saves
CHUNK_BYTES = 64 * 1024
PLANT_LINK_FIELDS = ("host_plant_record", "nectar_plant_record")  # links to plant records (T051)
MAX_PHOTO_PIXELS = (
    100_000_000  # the thumbnail is made in memory; the byte limit alone does not bound it
)
MAGIC_BYTES = {  # the first bytes of a file of each allowed type
    "image/jpeg": b"\xff\xd8\xff",
    "image/png": b"\x89PNG\r\n\x1a\n",
}

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
    """Every member's observations in the project, deleted rows included (D-049). Read-only on
    the phone for other members' rows (T112, D-107); the validation fields stay unsent."""
    return ButterflyObservation.objects.filter(project=project).select_related("recorded_by")


def photo_count(observation):
    """How many live photos the observation has, uploaded or not."""
    return Photo.objects.alive().filter(observation_id=observation.pk).count()


def initial_validation_status(confidence, taxon):
    """`pending` when the record needs an expert's look, `not_required` otherwise (outline 8.8).

    Worked out on create, and again by `reevaluate_validation_status` when a recorder changes the
    taxon or confidence of an undecided record. A new observation has no photo yet (photos arrive
    after it, T049), so a taxon that requires one is always pending (W01); a photo that arrives
    later does not change it, because an expert still has to look at it (D-091).
    """
    if confidence in PENDING_CONFIDENCES or rules.photo_missing(taxon.photo_required, 0):
        return ValidationStatus.PENDING
    return ValidationStatus.NOT_REQUIRED


def reevaluate_validation_status(observation, changed_fields):
    """A recorder's edit of the taxon or confidence of an undecided record (T057, D-091). A
    decided record is left alone, and so is one a validator sent back (it stays pending).

    Sets `validation_status` on the unsaved `observation`; the caller's `save_observation`
    saves it."""
    if not {"taxon", "identification_confidence"} & set(changed_fields):
        return
    if observation.validation_status not in (
        ValidationStatus.PENDING,
        ValidationStatus.NOT_REQUIRED,
    ):
        return
    status = initial_validation_status(observation.identification_confidence, observation.taxon)
    if status == ValidationStatus.NOT_REQUIRED and observation.validation_events.exists():
        return  # a validator has touched it: it never drops back to not_required
    observation.validation_status = status


def build_new_observation(user, observation_id, data):
    """An unsaved observation from a create payload. `validation_status` is the server's: a value
    the client sent is never read (the sync serializer has no such field)."""
    serializer = ButterflyObservationSyncSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    values = dict(serializer.validated_data)
    values.setdefault("recorded_by", user)

    observation = ButterflyObservation(id=observation_id, created_by=user, **values)
    _check_context(user, observation)
    ensure_project_open(observation.project, current_client_time())  # T099, D-104
    _check_recorder(user, observation)
    _check_plant_links(user, observation, PLANT_LINK_FIELDS)
    if observation.transect_section_id is None:
        observation.transect_section_id = _nearest_section_id(observation)
    observation.validation_status = initial_validation_status(
        observation.identification_confidence, observation.taxon
    )
    return observation


def apply_observation_changes(user, observation, data):
    """Apply an update payload to `observation` (unsaved). Only the keys in `data` change. A real
    change of the taxon or confidence works the validation status out again for an undecided
    record (`reevaluate_validation_status`, D-091)."""
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
    old_links = {name: getattr(observation, f"{name}_id") for name in PLANT_LINK_FIELDS}
    old_taxon_id = observation.taxon_id
    old_confidence = observation.identification_confidence
    for field_name, value in changes.items():
        setattr(observation, field_name, value)
    # Only a value that really changed counts: a full payload that repeats one changes nothing.
    changed = []
    if observation.taxon_id != old_taxon_id:
        changed.append("taxon")
    if observation.identification_confidence != old_confidence:
        changed.append("identification_confidence")
    reevaluate_validation_status(observation, changed)
    if {"transect_section", "taxon"} & changes.keys():
        _check_context(user, observation)
    if "recorded_by" in changes:
        _check_recorder(user, observation)
    # Only a link that changed is checked: a full payload that repeats an old link, also to a
    # plant record deleted since, is not refused (D-086).
    _check_plant_links(
        user,
        observation,
        [
            name
            for name in PLANT_LINK_FIELDS
            if getattr(observation, f"{name}_id") != old_links[name]
        ],
    )
    if changes.get("transect_section", "absent") is None:
        observation.transect_section_id = _nearest_section_id(observation)
    return observation


def save_observation(observation, user, history_reason):
    """Check the input rules (T055) and the table's constraints, then save with a history reason.

    They are checked here so a broken rule comes back as a validation error with a message (the
    rule ID, e.g. `{"observed_at": ["V04"]}`), not as a database error.
    """
    errors = rules.validate_observation(_rule_data(observation), _rule_context(observation))
    if errors:
        raise exceptions.ValidationError(errors)
    # Set just before the save, so one save writes one history row and one version (D-093).
    observation.quality_flags = flags.observation_flags(observation)
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
    ensure_project_open(observation.project, None)  # REST has no push time (T099, D-104)
    apply_observation_changes(user, observation, data)
    return save_observation(observation, user, REST_REASON)


def remove_observation(user, observation):
    ensure_project_open(observation.project, None)  # REST has no push time (T099, D-104)
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
    must not be locked, and a changed section, taxon, recorder or plant link must fit. Raises DRF
    exceptions."""
    if observation.survey_visit_id is not None:
        ensure_unlocked(observation.survey_visit)
    if {"transect_section", "taxon"} & set(changed_fields):
        _check_context(admin_user, observation)
    if "recorded_by" in changed_fields:
        _check_recorder(admin_user, observation)
    _check_plant_links(admin_user, observation, changed_fields)


def admin_save_observation(observation, admin_user, reason, changed_fields):
    check_admin_edit(admin_user, observation, changed_fields)
    reevaluate_validation_status(observation, changed_fields)
    return save_observation(observation, admin_user, reason or "admin edit")


def reassign_section(observation, admin_user):
    """Admin action: recompute from the position. Replaces any section, or clears it when the
    point is too far. True when it changed. Saved per row, so history applies. Refuses a locked
    visit."""
    _lock_visit(observation)
    section_id = _nearest_section_id(observation)
    if section_id == observation.transect_section_id:
        return False
    observation.transect_section_id = section_id
    save_observation(observation, admin_user, REASSIGN_REASON)
    return True


def _nearest_section_id(observation):
    """The section the server works out, or None: no visit, an invalid point (V08 rejects it on
    save) or nothing within the protocol's distance. The visit's transect is the one that counts."""
    if observation.survey_visit_id is None or not rules.is_valid_point(observation.geometry):
        return None
    return nearest_section_id(
        observation.survey_visit.transect_id,
        observation.geometry,
        observation.project.protocol.max_distance_from_transect_m,
    )


def _rule_data(observation):
    """The observation's values (unsaved, as they will be stored) that the input rules read."""
    return {
        name: getattr(observation, name)
        for name in (
            "observed_at",
            "count",
            "geometry",
            "source",
            "sex",
            "life_stage",
            "behaviour",
            "identification_confidence",
            "location_accuracy_m",
            "host_plant_record_id",
        )
    }


def _rule_context(observation):
    """What the input rules need from the database: the visit, the protocol and the taxon."""
    visit = observation.survey_visit if observation.survey_visit_id is not None else None
    protocol = observation.project.protocol
    return rules.ObservationRuleContext(
        visit_status=visit.status if visit else None,
        visit_started_at=visit.started_at if visit else None,
        visit_ended_at=visit.ended_at if visit else None,
        visit_zero_confirmed=visit.zero_observation_confirmed if visit else False,
        tolerance_min=protocol.observation_time_tolerance_min,
        accuracy_warning_m=protocol.gps_accuracy_warning_m,
        taxon_photo_required=observation.taxon.photo_required,
        photo_count=photo_count(observation),
    )


def _lock_visit(record):
    """Lock the visit of `record` (an observation or a plant record) for the rest of the
    transaction and refuse a locked one. Done first, so a lock that lands while another request
    works on the visit is not missed."""
    if record.survey_visit_id is None:
        return
    visit = SurveyVisit.objects.select_for_update().get(pk=record.survey_visit_id)
    ensure_unlocked(visit)
    record.survey_visit = visit


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


def _check_plant_links(user, observation, changed_fields):
    """A host or nectar plant record that is set, and in `changed_fields`, must be one the user
    may see, be in the observation's project and have a resource type that fits the role. A
    deleted record is not found, so it cannot be linked anew; a link already there stays (soft
    delete keeps links, D-086). The visit is not compared: a patch is revisited, and a plant
    record may be made off a visit."""
    for field_name in PLANT_LINK_FIELDS:
        plant_id = getattr(observation, f"{field_name}_id")
        if field_name not in changed_fields or plant_id is None:
            continue
        resource_type = (
            plant_resources_for(user)
            .filter(pk=plant_id, project_id=observation.project_id)
            .values_list("resource_type", flat=True)
            .first()
        )
        if resource_type is None:
            raise exceptions.ValidationError({field_name: ["This plant record was not found."]})
        if resource_type not in PLANT_LINK_ROLES[field_name]:
            raise exceptions.ValidationError(
                {
                    field_name: [
                        f"This plant record is not {PLANT_LINK_ROLE_NAMES[field_name]} "
                        f"({ResourceType(resource_type).label.lower()})."
                    ]
                }
            )


# Photos (T049)


class UploadMismatch(exceptions.APIException):
    """The bytes or the values sent do not match the photo record (sha256, size, type)."""

    status_code = 422
    default_code = "upload_mismatch"
    default_detail = "The upload does not match the photo record."


class AlreadyUploaded(exceptions.APIException):
    status_code = 409
    default_code = "already_uploaded"
    default_detail = "This photo is already uploaded."


class UploadMissing(exceptions.APIException):
    status_code = 409
    default_code = "upload_missing"
    default_detail = "PUT the content first."


class UnsupportedMediaType(exceptions.APIException):
    status_code = 415
    default_code = "unsupported_media_type"
    default_detail = "The Content-Type must be the photo's mime type."


class LengthRequired(exceptions.APIException):
    status_code = 411
    default_code = "length_required"
    default_detail = "A Content-Length header is required."


class PayloadTooLarge(exceptions.APIException):
    status_code = 413
    default_code = "payload_too_large"
    default_detail = f"A photo can be at most {MAX_PHOTO_BYTES // (1024 * 1024)} MB."


def photos_for(user):
    """Live photos of live observations and plant records the user may change (and upload to):
    an admin all of them, a researcher the ones they created."""
    photos = Photo.objects.alive().filter(
        Q(observation__in=observations_for(user))
        | Q(plant_resource__in=own_plant_resources_for(user))
    )
    if is_admin(user):
        return photos
    return photos.filter(created_by=user)


def viewable_photos_for(user):
    """`photos_for(user)` plus the live photos of every plant record the user may see (T112,
    D-107). Only the content and thumbnail downloads read through this."""
    return Photo.objects.alive().filter(
        Q(pk__in=photos_for(user).values("pk")) | Q(plant_resource__in=plant_resources_for(user))
    )


def pull_photos(user, project):
    """The caller's own photos in the project, deleted rows included (D-049), plus the photos of
    other members' plant records once uploaded (T112, D-107). A pending one stays off the phone:
    it would show as an upload in progress. `complete_upload` saves the photo, so its version
    moves on and it arrives then."""
    own = Q(observation__project=project) | Q(plant_resource__project=project)
    return Photo.objects.filter(
        Q(own, created_by=user)
        | Q(plant_resource__project=project, upload_status=UploadStatus.UPLOADED)
    )


def build_new_photo(user, photo_id, data):
    """An unsaved photo from a create payload. The upload fields are the server's: the sync
    serializer has them read-only, and the photo starts `pending`."""
    serializer = PhotoSyncSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    values = dict(serializer.validated_data)

    observation = values.get("observation")
    plant = values.get("plant_resource")
    if (observation is None) == (plant is None):
        raise exceptions.ValidationError(
            {"observation": ["Send exactly one of observation and plant_resource."]}
        )
    if observation is not None:
        if not observations_for(user).filter(pk=observation.pk).exists():
            raise exceptions.ValidationError({"observation": ["This observation was not found."]})
        _lock_visit(observation)
        ensure_project_open(observation.project, current_client_time())  # T099, D-104
    else:
        if not own_plant_resources_for(user).filter(pk=plant.pk).exists():
            raise exceptions.ValidationError(
                {"plant_resource": ["This plant record was not found."]}
            )
        _lock_visit(plant)
        ensure_project_open(plant.project, current_client_time())  # T099, D-104

    if values["mime_type"] not in PHOTO_MIME_TYPES:
        raise exceptions.ValidationError(
            {"mime_type": [f"Must be one of {', '.join(PHOTO_MIME_TYPES)}."]}
        )
    if values["file_size"] > MAX_PHOTO_BYTES:
        raise exceptions.ValidationError(
            {"file_size": [f"Must be at most {MAX_PHOTO_BYTES} bytes."]}
        )
    return Photo(id=photo_id, created_by=user, **values)


def apply_photo_changes(user, photo, data):
    """Apply an update payload to `photo` (unsaved). Only the keys in `data` change, and only
    `is_primary`, `local_path`, `captured_at`, `width` and `height` may: the file's identity is
    frozen at the create, parent included."""
    parent = photo.parent
    _lock_visit(parent)
    if not is_admin(user) and not is_member(user, parent.project_id):
        raise exceptions.PermissionDenied("You are not a member of this photo's project.")
    serializer = PhotoSyncSerializer(photo, data=data, partial=True)
    serializer.is_valid(raise_exception=True)
    changes = dict(serializer.validated_data)

    for field_name in ("observation", "plant_resource"):
        if field_name in changes:
            if getattr(changes.pop(field_name), "pk", None) != getattr(photo, f"{field_name}_id"):
                raise exceptions.ValidationError({field_name: ["Cannot be changed."]})
    for field_name in ("sha256", "mime_type", "file_size"):
        if field_name in changes and changes.pop(field_name) != getattr(photo, field_name):
            raise exceptions.ValidationError({field_name: ["Cannot be changed."]})
    for field_name, value in changes.items():
        setattr(photo, field_name, value)
    return photo


def save_photo(photo, user, history_reason):
    """Check the table's constraints (also the one-primary rule), then save with a history
    reason, so a broken rule is a validation error and not a database one."""
    try:
        photo.validate_constraints()
    except DjangoValidationError as error:
        raise exceptions.ValidationError(serializers.as_serializer_error(error)) from error
    save_with_reason(photo, user, history_reason)
    photo.refresh_from_db(fields=["server_version"])
    return photo


def push_create_photo(user, photo_id, data):
    photo = build_new_photo(user, photo_id, data)
    return save_photo(photo, user, current_push_reason())


def push_update_photo(user, photo, data):
    apply_photo_changes(user, photo, data)
    return save_photo(photo, user, current_push_reason())


def push_delete_photo(user, photo):
    _lock_visit(photo.parent)
    soft_delete_pushed(photo, user)


def photo_project_of(photo):
    return photo.parent.project


def guard_photo(user, photo):
    """Push guard (`PushHandlers.guard`): a photo of a locked visit refuses every change (T042)."""
    parent = photo.parent
    if parent.survey_visit_id is not None:
        ensure_unlocked(parent.survey_visit)


# Upload steps. Each takes a photo loaded through `photos_for(user)`. They do not call
# `ensure_unlocked`: the metadata was accepted before the lock and the bytes only fulfil a record
# whose sha256 is already frozen, so refusing would leave the photo pending for ever (D-072).


def init_upload(user, photo, sha256, file_size, mime_type):
    """Step 1. `{"status": "exists"}` when the photo is (now) linked to a stored object,
    `{"status": "upload_required"}` when the bytes must be PUT. Both carry `server_version`."""
    if (sha256, file_size, mime_type) != (photo.sha256, photo.file_size, photo.mime_type):
        raise UploadMismatch("sha256, file_size and mime_type must equal the photo record's.")
    if photo.upload_status == UploadStatus.UPLOADED:
        return {"status": "exists", "server_version": photo.server_version}

    # Deleted rows count too: their object is still stored (D-072).
    stored = Photo.objects.filter(
        sha256=photo.sha256, mime_type=photo.mime_type, upload_status=UploadStatus.UPLOADED
    ).first()
    if stored is None or not photo_storage.original_exists(stored.storage_key):
        # No match, or its object is gone (a bucket restored without the row's photos).
        return {"status": "upload_required", "server_version": photo.server_version}
    photo.storage_key = stored.storage_key
    photo.upload_status = UploadStatus.UPLOADED
    photo.uploaded_at = timezone.now()
    _save_upload(photo, user)
    return {"status": "exists", "server_version": photo.server_version}


def store_content(photo, stream, content_type, content_length):
    """Step 2: check and store the bytes of `stream`. Touches storage only, not the database.
    `content_length` is the header's value (a string) or None."""
    if photo.upload_status == UploadStatus.UPLOADED:
        raise AlreadyUploaded("The photo is already uploaded; a PUT is only allowed until then.")
    if (content_type or "").split(";")[0].strip().lower() != photo.mime_type:
        raise UnsupportedMediaType(f"The Content-Type must be {photo.mime_type}.")
    if not content_length:
        raise LengthRequired()
    try:
        declared = int(content_length)
    except ValueError as error:
        raise LengthRequired("The Content-Length is not a number.") from error
    if declared > MAX_PHOTO_BYTES:
        raise PayloadTooLarge()
    if stream is None:  # DRF gives no stream for a Content-Length of 0
        raise UploadMismatch(f"The body has 0 bytes, the photo record says {photo.file_size}.")

    digest = hashlib.sha256()
    size = 0
    with tempfile.TemporaryFile() as received:
        while chunk := stream.read(CHUNK_BYTES):
            size += len(chunk)
            if size > MAX_PHOTO_BYTES:
                raise PayloadTooLarge()
            digest.update(chunk)
            received.write(chunk)
        if size != photo.file_size:
            raise UploadMismatch(
                f"The body has {size} bytes, the photo record says {photo.file_size}."
            )
        if digest.hexdigest() != photo.sha256:
            raise UploadMismatch("The SHA-256 of the body is not the photo record's.")
        received.seek(0)
        if not received.read(len(MAGIC_BYTES[photo.mime_type])) == MAGIC_BYTES[photo.mime_type]:
            raise UploadMismatch(f"The file is not a {photo.mime_type} image.")
        received.seek(0)
        try:
            image = Image.open(received)
            image.verify()
        except (OSError, SyntaxError, Image.DecompressionBombError) as error:
            raise UploadMismatch("The file is not a readable image.") from error
        if image.width * image.height > MAX_PHOTO_PIXELS:
            raise UploadMismatch(f"The image has more than {MAX_PHOTO_PIXELS} pixels.")
        received.seek(0)
        photo_storage.put_original(photo.sha256, PHOTO_MIME_TYPES[photo.mime_type], received)


def complete_upload(user, photo):
    """Step 3: make the thumbnail and mark the photo uploaded. Idempotent."""
    if photo.upload_status != UploadStatus.UPLOADED:
        key = photo_storage.original_key(photo.sha256, PHOTO_MIME_TYPES[photo.mime_type])
        if not photo_storage.original_exists(key):
            raise UploadMissing()
        photo_storage.make_thumbnail(photo.sha256, key)
        photo.storage_key = key
        photo.upload_status = UploadStatus.UPLOADED
        photo.uploaded_at = timezone.now()
        _save_upload(photo, user)
    return {
        "status": "uploaded",
        "server_version": photo.server_version,
        "uploaded_at": photo.uploaded_at,
    }


def _save_upload(photo, user):
    """Save the server's own upload fields. This bumps `server_version`: the responses return the
    new one, so the phone's copy is current and a later delete is not a conflict (D-072)."""
    save_with_reason(photo, user, UPLOAD_REASON)
    photo.refresh_from_db(fields=["server_version"])
