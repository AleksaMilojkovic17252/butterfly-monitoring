"""T007 walking skeleton: store a ping idempotently. Throwaway: deleted in T044."""

from django.contrib.gis.geos import Point
from rest_framework import serializers

from apps.core.models_skeleton import SkeletonPing


class PingSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    observed_at = serializers.DateTimeField()
    lat = serializers.FloatField(min_value=-90, max_value=90)
    lon = serializers.FloatField(min_value=-180, max_value=180)
    note = serializers.CharField(max_length=200, allow_blank=True, default="")


def save_ping(data) -> tuple[SkeletonPing, bool]:
    """Create the ping, or return the existing row when the id was already received."""
    return SkeletonPing.objects.get_or_create(
        id=data["id"],
        defaults={
            "observed_at": data["observed_at"],
            "geometry": Point(data["lon"], data["lat"], srid=4326),
            "note": data["note"],
        },
    )
