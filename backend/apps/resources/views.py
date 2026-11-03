import uuid

from django.db import transaction
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import exceptions, status
from rest_framework.parsers import JSONParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.resources import services
from apps.resources.models import HabitatFeature, PlantResourceObservation
from apps.resources.serializers import (
    HabitatFeatureSyncSerializer,
    PlantResourceSyncSerializer,
)

# Outline 14. The app writes through /sync/push; these share its service functions
# (CONVENTIONS A.7). POST and PATCH only: there is no list, read or delete endpoint, the app
# pulls and the map reads pygeoapi.


def _plant_or_404(user, plant_id):
    """The plant record, locked for the rest of the transaction. Outside
    `plant_resources_for(user)` it is a 404."""
    return get_object_or_404(services.plant_resources_for(user).select_for_update(), pk=plant_id)


def _habitat_feature_or_404(user, feature_id):
    """The habitat feature, locked for the rest of the transaction. Outside
    `habitat_features_for(user)` it is a 404."""
    return get_object_or_404(services.habitat_features_for(user).select_for_update(), pk=feature_id)


def _json_object(request):
    """The request body, which must be a JSON object. The views accept JSON only, so the body
    is a plain dict here, or a list or value that is refused."""
    if not isinstance(request.data, dict):
        raise exceptions.ValidationError({"non_field_errors": ["Send a JSON object."]})
    return request.data


def _client_record_id(data):
    """The client-generated id from the body, or a new one."""
    raw_id = data.get("id")
    if raw_id is None:
        return uuid.uuid4()
    try:
        return uuid.UUID(str(raw_id))
    except ValueError as error:
        raise exceptions.ValidationError({"id": ["Must be a UUID."]}) from error


class PlantResourceCreate(APIView):
    parser_classes = [JSONParser]

    @extend_schema(
        request=PlantResourceSyncSerializer, responses={201: PlantResourceSyncSerializer}
    )
    def post(self, request):
        """Create a plant record. The body may carry the client's `id`; an existing id is a 400.
        A polygon sent without `patch_area_m2` gets the area the server works out."""
        data = _json_object(request)
        plant_id = _client_record_id(data)
        if PlantResourceObservation._base_manager.filter(pk=plant_id).exists():
            raise exceptions.ValidationError(
                {"id": ["A plant record with this id already exists."]}
            )
        with transaction.atomic():
            plant = services.create_plant_resource(request.user, plant_id, data)
        return Response(PlantResourceSyncSerializer(plant).data, status=status.HTTP_201_CREATED)


class PlantResourceDetail(APIView):
    parser_classes = [JSONParser]

    @extend_schema(request=PlantResourceSyncSerializer, responses=PlantResourceSyncSerializer)
    def patch(self, request, plant_id):
        """Change some fields. A changed polygon without a new `patch_area_m2` gets its area
        worked out again."""
        with transaction.atomic():
            plant = _plant_or_404(request.user, plant_id)
            services.update_plant_resource(request.user, plant, _json_object(request))
        return Response(PlantResourceSyncSerializer(plant).data)


class HabitatFeatureCreate(APIView):
    parser_classes = [JSONParser]

    @extend_schema(
        request=HabitatFeatureSyncSerializer, responses={201: HabitatFeatureSyncSerializer}
    )
    def post(self, request):
        """Create a habitat feature. The body may carry the client's `id`; an existing id is a
        400."""
        data = _json_object(request)
        feature_id = _client_record_id(data)
        if HabitatFeature._base_manager.filter(pk=feature_id).exists():
            raise exceptions.ValidationError(
                {"id": ["A habitat feature with this id already exists."]}
            )
        with transaction.atomic():
            feature = services.create_habitat_feature(request.user, feature_id, data)
        return Response(HabitatFeatureSyncSerializer(feature).data, status=status.HTTP_201_CREATED)


class HabitatFeatureDetail(APIView):
    parser_classes = [JSONParser]

    @extend_schema(request=HabitatFeatureSyncSerializer, responses=HabitatFeatureSyncSerializer)
    def patch(self, request, feature_id):
        """Change some fields. `project` and `survey_visit` cannot change."""
        with transaction.atomic():
            feature = _habitat_feature_or_404(request.user, feature_id)
            services.update_habitat_feature(request.user, feature, _json_object(request))
        return Response(HabitatFeatureSyncSerializer(feature).data)
