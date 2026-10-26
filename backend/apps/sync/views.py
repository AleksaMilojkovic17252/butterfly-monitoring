from drf_spectacular.utils import extend_schema
from rest_framework.decorators import api_view
from rest_framework.response import Response

from apps.sync import services
from apps.sync.serializers import (
    OfflinePackageResponseSerializer,
    OfflinePackageStatusSerializer,
    PullRequestSerializer,
    PullResponseSerializer,
    PushMutationsSerializer,
    PushRequestSerializer,
    PushResponseSerializer,
)


@extend_schema(
    request=PullRequestSerializer,
    responses=PullResponseSerializer,
    description=(
        "Rows that changed after `cursor`, per entity type, ordered by `server_version`, at most "
        "`limit` rows in all. Scope: the project, its protocol and transects, the catalogues "
        "(global, retired taxa included) and the taxon list releases. A project the caller "
        "cannot see is a 404. A soft-deleted row comes back as a tombstone "
        "`{id, deleted_at, server_version}` instead of a record. Types with no changes give an "
        "empty list. Cursor 0 is the full initial package. Repeat with `cursor = next_cursor` "
        "until `has_more` is false."
    ),
)
@api_view(["POST"])
def pull(request):
    params = PullRequestSerializer(data=request.data)
    params.is_valid(raise_exception=True)
    data = params.validated_data
    result = services.pull(request.user, data["project_id"], data["cursor"], data["limit"])
    return Response(result)


@extend_schema(
    responses=OfflinePackageResponseSerializer,
    description=(
        "Alias of the first pull page from cursor 0 (same body as `POST /sync/pull`), plus "
        "`reference_version`: the max `server_version` over the reference tables in the pull "
        "scope (project, protocol, catalogues, taxon list releases, transects and sections; "
        "deleted rows included), 0 when there are none. The app compares it with its pull "
        "cursor. A project the caller cannot see is a 404."
    ),
)
@api_view(["GET"])
def offline_package(request, project_id):
    return Response(services.offline_package(request.user, project_id))


@extend_schema(
    responses=OfflinePackageStatusSerializer,
    description=(
        "`reference_version`: the max `server_version` over the reference tables in the pull "
        "scope, deleted rows included, 0 when there are none. The app compares it with its pull "
        "cursor to show `update available`. A project the caller cannot see is a 404."
    ),
)
@api_view(["GET"])
def offline_package_status(request, project_id):
    return Response(services.offline_package_status(request.user, project_id))


@extend_schema(
    request=PushMutationsSerializer,
    responses=PushResponseSerializer,
    description=(
        "Applies a batch of mutations (at most 1000) from the phone. The response is always 200 "
        "when the envelope is valid, with one result per mutation in input order: `applied`, "
        "`duplicate`, `rejected` (`errors` holds `{code, detail, fields}`), later also `merged` "
        "and `conflict`. A `mutation_id` seen before changes nothing: an applied one returns its "
        "stored result as `duplicate`, a rejected one returns the same rejection again (to retry "
        "it, send it under a new `mutation_id`), so a batch can be resent. `server_version` "
        "is the row's new "
        "version, null for `create_batch` and for rejections. `base_version` is the version the "
        "phone last pulled; a mismatch on `update` or `delete` is rejected as `stale_version` "
        "until conflict handling (T027). `create` of an existing id acts as `update`. "
        "`create_batch` sends `entity_id` = the parent record and `payload.rows` = 1 to 1000 "
        "rows with their own `id`; rows that already exist are skipped. Server-owned fields "
        "(`id`, `server_version`, `created_by`, `updated_by`, `updated_at`, `deleted_at`, "
        "`quality_flags`, `validation_*`, `locked_*`) in a payload are ignored. Datetimes need "
        "a UTC offset. No entity type accepts pushes yet (first: T034); until then every "
        "mutation is rejected with `read_only_entity`."
    ),
)
@api_view(["POST"])
def push(request):
    envelope = PushRequestSerializer(data=request.data)
    envelope.is_valid(raise_exception=True)
    data = envelope.validated_data
    result = services.push(request.user, data["device_id"], data["mutations"])
    return Response(result)
