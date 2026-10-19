from drf_spectacular.utils import extend_schema
from rest_framework.decorators import api_view
from rest_framework.response import Response

from apps.sync import services
from apps.sync.serializers import PullRequestSerializer, PullResponseSerializer


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
