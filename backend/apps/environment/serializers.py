from rest_framework import serializers

from apps.core.serializers import GeoJSONField
from apps.environment.models import SensorStationLink


class SensorStationLinkSyncSerializer(serializers.ModelSerializer):
    """A station row as pulled to the phone (T078), read-only. The FROST ids and `metadata_json`
    stay on the server: the phone never calls FROST."""

    geometry = GeoJSONField()
    transects = serializers.PrimaryKeyRelatedField(many=True, read_only=True)

    class Meta:
        model = SensorStationLink
        exclude = [
            "created_by",
            "updated_by",
            "sensorthings_thing_id",
            "sensorthings_datastream_ids",
            "metadata_json",
        ]
