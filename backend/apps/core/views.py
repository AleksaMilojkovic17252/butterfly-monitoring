from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.core.health import check_db, check_storage
from apps.core.skeleton import PingSerializer, save_ping


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


@api_view(["POST"])
@authentication_classes([])
@permission_classes([AllowAny])
def skeleton_pings(request):
    """T007 throwaway endpoint, no auth until T011. Removed in T044."""
    serializer = PingSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    _, created = save_ping(serializer.validated_data)
    return Response(
        {"id": str(serializer.validated_data["id"]), "created": created},
        status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
    )
