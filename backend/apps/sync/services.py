"""Sync rules. The views call `pull` (T025), `push` (T026) and the offline package (T031).

Push merges a stale update/delete against the history (T027, D-052) or records a SyncConflict.
The admin settles a SyncConflict with `resolve_conflict` (T028, D-053).
"""

import json
from contextlib import contextmanager
from dataclasses import dataclass
from uuid import UUID

from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import DataError, IntegrityError, connection, transaction
from django.db.models import Max
from django.http import Http404
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import exceptions, serializers
from rest_framework.renderers import JSONRenderer

from apps.accounts.services import is_admin
from apps.core.exceptions import error_body
from apps.core.history import save_with_reason
from apps.projects.services import projects_for
from apps.sync.handlers import push_reason, save_pushed
from apps.sync.models import ConflictStatus, MutationStatus, SyncConflict, SyncMutation
from apps.sync.registry import ENTITIES, entity_for
from apps.sync.serializers import (
    DEFAULT_PULL_LIMIT,
    MAX_BATCH_ROWS,
    MutationSerializer,
    TombstoneSerializer,
)

# Per-user advisory lock key (two-key form, so it never collides with the single-key global
# lock 727274 of D-029).
PUSH_LOCK_KEY = 727275

# Fields a client may never set (T026 criterion "server-owned fields are ignored"), besides any
# `validation_*` / `locked_*` key and `SyncEntity.server_owned`. `created_at` is not listed: the
# phone sets it for records created offline.
SERVER_OWNED_FIELDS = frozenset(
    {
        "id",
        "server_version",
        "created_by",
        "updated_by",
        "updated_at",
        "deleted_at",
        "quality_flags",
    }
)
SERVER_OWNED_PREFIXES = ("validation_", "locked_")


@contextmanager
def _pull_snapshot():
    """The transaction of a pull: everything read inside it sees one snapshot."""
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
        yield


def _pull_page(user, project, cursor, limit):
    """One page of changes after `cursor`. `project` is authorised; call inside _pull_snapshot."""
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


def _reference_version(user, project):
    """Max `server_version` over the reference tables in the pull scope, 0 when empty.

    Soft-deleted rows count, so a deletion is an update too. Call inside _pull_snapshot.
    """
    return max(
        (
            entity.pull_scope(user, project).aggregate(m=Max("server_version"))["m"] or 0
            for entity in ENTITIES
            if entity.reference
        ),
        default=0,
    )


def pull(user, project_id, cursor, limit):
    """One page of changes after `cursor` for `project_id`, ordered by `server_version`.

    Raises Http404 when the user cannot see the project (D-036).
    """
    with _pull_snapshot():
        project = get_object_or_404(projects_for(user), pk=project_id)
        return _pull_page(user, project, cursor, limit)


def offline_package(user, project_id, limit=DEFAULT_PULL_LIMIT):
    """The first pull page (cursor 0) plus `reference_version`, from one snapshot (T031).

    Raises Http404 when the user cannot see the project (D-036).
    """
    with _pull_snapshot():
        project = get_object_or_404(projects_for(user), pk=project_id)
        page = _pull_page(user, project, 0, limit)
        return {**page, "reference_version": _reference_version(user, project)}


def offline_package_status(user, project_id):
    """`{"reference_version": n}`: the app compares n with its pull cursor (T031).

    Raises Http404 when the user cannot see the project (D-036).
    """
    with _pull_snapshot():
        project = get_object_or_404(projects_for(user), pk=project_id)
        return {"reference_version": _reference_version(user, project)}


class PushError(exceptions.APIException):
    """A rule of the push pipeline itself (not of an entity) that rejects one mutation."""

    status_code = 409

    def __init__(self, code, detail):
        super().__init__(detail, code)
        self.default_code = code  # error_body reads the code from here


# Exceptions that reject one change (push mutations, T028 resolutions). Anything else is a bug.
HANDLER_ERRORS = (
    exceptions.APIException,
    Http404,
    DjangoPermissionDenied,
    DjangoValidationError,
    IntegrityError,
    DataError,
)


def push(user, device_id, raw_mutations):
    """Apply a batch of mutations from the phone. Returns {"results": [...]} in input order.

    Each mutation runs in its own savepoint, so a rejected one does not abort the others. A
    `mutation_id` seen before changes nothing: an applied or merged one returns its stored result
    as `duplicate`, a rejected or conflicting one returns the stored result again.
    """
    results = []
    with transaction.atomic(durable=True):
        # A retry of a batch that is still running would otherwise pass the duplicate check
        # before the first one commits and apply everything twice. With the lock it waits, then
        # sees the stored result.
        with connection.cursor() as db:
            db.execute(
                "SELECT pg_advisory_xact_lock(%s, hashtext(%s))", [PUSH_LOCK_KEY, str(user.pk)]
            )
        for raw in raw_mutations:
            results.append(_push_one(user, device_id, raw))
    return {"results": results}


def _result(mutation_id, status, server_version=None, errors=()):
    return {
        "mutation_id": str(mutation_id) if mutation_id is not None else None,
        "status": status,
        "server_version": server_version,
        "errors": list(errors),
    }


def _echo_id(raw):
    """The mutation_id of an invalid item, only when it is a real UUID."""
    try:
        return UUID(str(raw["mutation_id"])) if isinstance(raw, dict) else None
    except (KeyError, ValueError):
        return None


def _push_one(user, device_id, raw):
    serializer = MutationSerializer(data=raw)
    if not isinstance(raw, dict):
        errors = {"non_field_errors": ["Each mutation must be an object."]}
    elif not serializer.is_valid():
        errors = serializer.errors
    else:
        errors = None
    if errors:
        # No trustworthy mutation_id, so nothing is stored.
        return _result(
            _echo_id(raw),
            "rejected",
            errors=[error_body(exceptions.ValidationError(errors))],
        )
    mutation = serializer.validated_data
    mutation_id = mutation["mutation_id"]

    stored = SyncMutation.objects.filter(pk=mutation_id).first()
    if stored is not None:
        if stored.user_id == user.pk:
            # A rejection or conflict stays what it was: `duplicate` reads as "already applied".
            # To retry a rejected change the phone sends it again under a new mutation_id; a
            # conflict is settled by an admin (T028).
            if stored.status in (MutationStatus.REJECTED, MutationStatus.CONFLICT):
                return stored.result
            return {**stored.result, "status": "duplicate"}
        # Never leak another user's result.
        error = PushError("mutation_id_taken", "This mutation_id belongs to another user.")
        return _result(mutation_id, "rejected", errors=[error_body(error)])

    try:
        # The savepoint. After an error inside it the outer transaction is only usable if the
        # error is caught outside this block (the block rolls back to the savepoint on the way
        # out), so the handlers below sit outside the `with`.
        with transaction.atomic():
            outcome = _apply(user, mutation)
    except HANDLER_ERRORS as exc:
        # Anything else is a bug: it propagates, the whole batch rolls back and returns 500, and
        # the phone retries later. Storing it as a rejection would hide it.
        result = _result(mutation_id, "rejected", errors=[error_body(_as_api_error(exc))])
        status = MutationStatus.REJECTED
    else:
        result = _result(mutation_id, outcome.status, outcome.server_version)
        status = outcome.status

    # Outside the savepoint, so rejections are stored too.
    if status == MutationStatus.CONFLICT:
        try:
            # Own savepoint: the payload goes into a jsonb column, which can refuse it (a \u0000
            # in a string). That must reject this mutation, not abort the batch.
            with transaction.atomic():
                stored_mutation = _store_mutation(user, device_id, mutation, status, result)
                conflict = SyncConflict(
                    owner=user, mutation=stored_mutation, created_by=user, **outcome.conflict
                )
                save_pushed(conflict, user)
            return result
        except (IntegrityError, DataError, ValueError) as exc:
            result = _result(mutation_id, "rejected", errors=[error_body(_as_api_error(exc))])
            status = MutationStatus.REJECTED
    _store_mutation(user, device_id, mutation, status, result)
    return result


def _store_mutation(user, device_id, mutation, status, result):
    return SyncMutation.objects.create(
        mutation_id=mutation["mutation_id"],
        user=user,
        device_id=device_id,
        entity_type=mutation["entity_type"],
        entity_id=mutation["entity_id"],
        operation=mutation["operation"],
        base_version=mutation["base_version"],
        status=status,
        result=result,
        client_created_at=mutation["client_created_at"],
    )


def _as_api_error(exc):
    if isinstance(exc, DjangoPermissionDenied):
        return exceptions.PermissionDenied(str(exc) or None)
    if isinstance(exc, DjangoValidationError):
        return exceptions.ValidationError(serializers.as_serializer_error(exc))
    if isinstance(exc, IntegrityError):
        return PushError("integrity_error", "The change conflicts with existing data.")
    if isinstance(exc, (DataError, ValueError)):  # too long, out of range or unstorable
        return PushError("invalid_data", "A value is too long or out of range for its field.")
    return exc


def _strip(data, entity, keep=()):
    return {
        key: value
        for key, value in data.items()
        if key in keep
        or key not in SERVER_OWNED_FIELDS
        and key not in entity.server_owned
        and not key.startswith(SERVER_OWNED_PREFIXES)
    }


@dataclass
class Outcome:
    """What `_apply` did. `conflict` holds SyncConflict field values (all but owner, mutation)."""

    status: str
    server_version: int | None
    conflict: dict | None = None


def _apply(user, mutation):
    """Run one mutation through its entity's handler. Returns an `Outcome`."""
    entity = entity_for(mutation["entity_type"])
    if entity is None:
        raise PushError("unknown_entity_type", f"Unknown entity type {mutation['entity_type']!r}.")
    if entity.push is None:
        raise PushError("read_only_entity", f"{entity.entity_type} cannot be changed by the app.")
    operation = mutation["operation"]
    entity_id = mutation["entity_id"]
    data = _strip(mutation["payload"], entity)

    if operation == "create_batch":
        _require(entity, "create_batch")
        rows = data.get("rows")
        if (
            not isinstance(rows, list)
            or not 1 <= len(rows) <= MAX_BATCH_ROWS
            or not all(isinstance(row, dict) for row in rows)
        ):
            raise exceptions.ValidationError(
                {"rows": f"Send 1 to {MAX_BATCH_ROWS} rows as a list of objects."}
            )
        # entity_id is the parent record (the visit for track points); rows carry their own id.
        cleaned = [_strip(row, entity, keep=("id",)) for row in rows]
        entity.push.create_batch(user, entity_id, cleaned)
        return Outcome(MutationStatus.APPLIED, None)

    _require(entity, operation)
    model = entity.serializer.Meta.model
    # Base manager: a soft-deleted row still counts as existing.
    instance = model._base_manager.select_for_update().filter(pk=entity_id).first()

    if operation == "create" and instance is None:
        entity.push.create(user, entity_id, data)
        return Outcome(MutationStatus.APPLIED, _current_version(model, entity_id))

    if instance is None:
        raise exceptions.NotFound(f"{entity.entity_type} {entity_id} does not exist.")
    if instance.created_by_id != user.pk and not is_admin(user):
        raise exceptions.PermissionDenied()

    if instance.deleted_at is not None:
        if operation == "delete":
            return Outcome(MutationStatus.APPLIED, instance.server_version)
        raise PushError("deleted", f"{entity.entity_type} {entity_id} was deleted.")

    base_version = mutation["base_version"]
    resend = operation == "create"
    if resend:
        # The phone resent a create the server already has (D-050 gap). Merge it as an update
        # against the row as it was created, so admin edits since then are kept (D-052). Always
        # merged, even when nothing changed since: an exact resend must not bump the version.
        operation, base_version = "update", _creation_version(model, entity_id)
    elif base_version is None:
        raise exceptions.ValidationError({"base_version": ["Required for update and delete."]})
    if resend or base_version != instance.server_version:
        return _merge(user, entity, instance, operation, base_version, data)

    if operation == "delete":
        entity.push.delete(user, instance)
    else:
        _require(entity, "update")
        entity.push.update(user, instance, data)
    return Outcome(MutationStatus.APPLIED, _current_version(model, entity_id))


def _require(entity, operation):
    if getattr(entity.push, operation) is None:
        raise PushError(
            "operation_not_allowed", f"{entity.entity_type} does not accept {operation}."
        )


def _current_version(model, entity_id):
    # Instances are stale after save (D-029), so read the version the trigger wrote.
    return model._base_manager.filter(pk=entity_id).values_list("server_version", flat=True).get()


def _creation_version(model, pk):
    """server_version of the row's first history row, or None (no history)."""
    history = getattr(model, "history", None)
    if history is None:
        return None
    return (
        history.filter(id=pk, history_type="+")
        .order_by("history_id")
        .values_list("server_version", flat=True)
        .first()
    )


def _history_at(model, pk, version):
    """The history row the row had at `version` (D-040), or None."""
    history = getattr(model, "history", None)
    if history is None or version is None:
        return None
    return history.filter(id=pk, server_version=version).order_by("-history_id").first()


def _json(value):
    """A serializer value in plain JSON types (UUID -> str, Decimal -> str, ...)."""
    return json.loads(JSONRenderer().render(value))


def _snapshot(entity, instance):
    # Always the sync serializer (D-049), so snapshots, the row and the payload share one form.
    return _json(entity.serializer(instance).data)


def _normalise(field, value):
    """A payload value the way the serializer would show it, to compare it with a snapshot."""
    if value is None:
        return None
    try:
        return _json(field.to_representation(field.to_internal_value(value)))
    except (
        exceptions.ValidationError,
        DjangoValidationError,
        TypeError,
        ValueError,
    ):
        # Counts as changed; the handler rejects it if it is applied.
        return value


def _client_changed(entity, data, base):
    """Payload keys that are writable fields of the sync serializer and differ from `base`."""
    fields = entity.serializer().fields
    return {
        key
        for key, value in data.items()
        if key in fields
        and not fields[key].read_only
        and _normalise(fields[key], value) != base.get(key)
    }


def _client_changed_values(entity, data, base):
    """The part of `data` the client changed: what a handler's `update` gets."""
    return {key: data[key] for key in _client_changed(entity, data, base)}


def _merge(user, entity, instance, operation, base_version, data):
    """Three-way merge of a stale update/delete: snapshot at `base_version`, current row, payload.

    Changes that do not overlap are applied (merged); an overlap, a stale delete or a missing
    snapshot becomes a SyncConflict and nothing is applied.
    """
    model = type(instance)
    current = _snapshot(entity, instance)
    stripped = _strip(current, entity)
    row = _history_at(model, instance.pk, base_version)
    base = _snapshot(entity, row.instance) if row is not None else None

    if base is None:
        fields = sorted(stripped)  # no snapshot: the whole record conflicts
    else:
        server_changed = {key for key, value in stripped.items() if value != base.get(key)}
        if operation == "delete":
            fields = sorted(server_changed)  # always a conflict, even with no field changed
        else:
            client_changes = _client_changed_values(entity, data, base)
            client_changed = client_changes.keys()
            fields = sorted(server_changed & client_changed)
            if not fields:
                if not client_changed:
                    return Outcome(MutationStatus.MERGED, instance.server_version)
                _require(entity, "update")
                # Only what the client changed: it may send unchanged fields with old values.
                entity.push.update(user, instance, client_changes)
                return Outcome(MutationStatus.MERGED, _current_version(model, instance.pk))

    return Outcome(
        MutationStatus.CONFLICT,
        instance.server_version,
        conflict={
            "project": entity.push.project_of(instance),
            "entity_type": entity.entity_type,
            "entity_id": instance.pk,
            "operation": operation,
            "base_version": base_version or 0,
            "server_version_at_conflict": instance.server_version,
            "client_payload": data,
            "server_snapshot": current,
            "base_snapshot": base,
            "conflicting_fields": fields,
        },
    )


CONFLICT_RESOLVED_SERVER = "conflict resolved: server"
CONFLICT_RESOLVED_CLIENT = "conflict resolved: client"


class ResolutionError(Exception):
    """A conflict cannot be resolved this way. `message` is shown to the admin."""

    def __init__(self, message):
        super().__init__(message)
        self.message = message


def _handler_message(exc):
    body = error_body(_as_api_error(exc))
    if body["code"] == "visit_locked":  # raised by the visit services from T042
        return "The visit is locked. Unlock it first (Unlock action), then accept the client again."
    message = body["detail"]
    for field, problem in body["fields"].items():
        message += f" {field}: {problem}"
    return message


def resolve_conflict(conflict_id, side, user, note):
    """Settle an open SyncConflict for `side` ("server" or "client"). Raises ResolutionError.

    server: keep the row as it is and touch it (a save with a reason), so it gets a new
    server_version and the phone pulls it. client: run the stored change through the entity's
    push handler as `user`, with only the fields the client changed, and no conflict check.
    Either way the conflict is closed with the note; any failure rolls everything back.
    """
    note = (note or "").strip()
    if not note:
        raise ResolutionError("A note is required.")
    with transaction.atomic():
        conflict = SyncConflict._base_manager.select_for_update().filter(pk=conflict_id).first()
        if conflict is None:
            raise ResolutionError("This conflict no longer exists.")
        if conflict.status != ConflictStatus.OPEN:
            raise ResolutionError("This conflict is already resolved.")
        entity = entity_for(conflict.entity_type)
        if entity is None:
            raise ResolutionError(f"Unknown entity type {conflict.entity_type!r}.")
        model = entity.serializer.Meta.model
        # Base manager: a soft-deleted row still counts as existing.
        instance = model._base_manager.select_for_update().filter(pk=conflict.entity_id).first()
        if instance is None:
            raise ResolutionError(f"{entity.entity_type} {conflict.entity_id} does not exist.")

        if side == "server":
            reason, status = CONFLICT_RESOLVED_SERVER, ConflictStatus.RESOLVED_SERVER
            save_with_reason(instance, user, reason)
        else:
            reason, status = CONFLICT_RESOLVED_CLIENT, ConflictStatus.RESOLVED_CLIENT
            _apply_client(entity, instance, conflict, user, reason)

        conflict.status = status
        conflict.resolved_by = user
        conflict.resolved_at = timezone.now()
        conflict.resolution_note = note
        save_with_reason(conflict, user, reason)


def _apply_client(entity, instance, conflict, user, reason):
    operation = conflict.operation
    if entity.push is None:
        raise ResolutionError(
            f"{entity.entity_type} cannot be changed by the app, so the client change cannot "
            "be applied. Accept the server instead."
        )
    if getattr(entity.push, operation) is None:
        raise ResolutionError(f"{entity.entity_type} does not accept {operation}.")
    if instance.deleted_at is not None:
        if operation == "delete":
            return  # already what the client wanted
        raise ResolutionError(
            f"The {entity.entity_type} was deleted since. Restore it first, then accept the client."
        )
    try:
        with transaction.atomic(), push_reason(reason):
            if operation == "delete":
                entity.push.delete(user, instance)
            else:
                payload = conflict.client_payload
                base = conflict.base_snapshot
                # No snapshot: nothing to compare with, so the whole payload applies.
                fields = payload if base is None else _client_changed_values(entity, payload, base)
                entity.push.update(user, instance, fields)
    except (*HANDLER_ERRORS, ValueError) as exc:
        # ValueError (an unstorable value) is rejected here like `_as_api_error` maps it; in a
        # push it stays a bug that rolls the batch back (D-050).
        raise ResolutionError(_handler_message(exc)) from exc
