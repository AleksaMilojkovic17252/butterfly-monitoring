from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from core.health import check_db, check_storage


@api_view(["GET"])
@authentication_classes([])
@permission_classes([AllowAny])
def health(request):
    db_ok = check_db()
    storage_ok = check_storage()
    ok = db_ok and storage_ok
    return Response(
        {"status": "ok" if ok else "degraded", "db": db_ok, "storage": storage_ok},
        status=status.HTTP_200_OK if ok else status.HTTP_503_SERVICE_UNAVAILABLE,
    )
