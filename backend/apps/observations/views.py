import uuid

from django.db import transaction
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import exceptions, status
from rest_framework.parsers import JSONParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.observations import services
from apps.observations.models import ButterflyObservation
from apps.observations.serializers import (
    ButterflyObservationSerializer,
    ButterflyObservationSyncSerializer,
)

# Outline 14. The app writes through /sync/push; these share its service functions
# (CONVENTIONS A.7). There is no list endpoint: the app pulls, and the map reads pygeoapi.


def _observation_or_404(user, observation_id):
    """The observation, locked for the rest of the transaction. Outside `observations_for(user)`
    it is a 404."""
    return get_object_or_404(services.observations_for(user).select_for_update(), pk=observation_id)


def _json_object(request):
    """The request body, which must be a JSON object. The views accept JSON only, so the body
    is a plain dict here, or a list or value that is refused."""
    if not isinstance(request.data, dict):
        raise exceptions.ValidationError({"non_field_errors": ["Send a JSON object."]})
    return request.data


def _client_observation_id(data):
    """The client-generated id from the body, or a new one."""
    raw_id = data.get("id")
    if raw_id is None:
        return uuid.uuid4()
    try:
        return uuid.UUID(str(raw_id))
    except ValueError as error:
        raise exceptions.ValidationError({"id": ["Must be a UUID."]}) from error


class ButterflyObservationCreate(APIView):
    parser_classes = [JSONParser]

    @extend_schema(
        request=ButterflyObservationSyncSerializer, responses={201: ButterflyObservationSerializer}
    )
    def post(self, request):
        """Create an observation. The body may carry the client's `id`; an existing id is a 400."""
        data = _json_object(request)
        observation_id = _client_observation_id(data)
        if ButterflyObservation._base_manager.filter(pk=observation_id).exists():
            raise exceptions.ValidationError(
                {"id": ["An observation with this id already exists."]}
            )
        with transaction.atomic():
            observation = services.create_observation(request.user, observation_id, data)
        return Response(
            ButterflyObservationSerializer(observation).data, status=status.HTTP_201_CREATED
        )


class ButterflyObservationDetail(APIView):
    parser_classes = [JSONParser]

    @extend_schema(responses=ButterflyObservationSerializer)
    def get(self, request, observation_id):
        observation = get_object_or_404(services.observations_for(request.user), pk=observation_id)
        return Response(ButterflyObservationSerializer(observation).data)

    @extend_schema(
        request=ButterflyObservationSyncSerializer, responses=ButterflyObservationSerializer
    )
    def patch(self, request, observation_id):
        """Change some fields. The validation status is not recomputed."""
        with transaction.atomic():
            observation = _observation_or_404(request.user, observation_id)
            services.update_observation(request.user, observation, _json_object(request))
        return Response(ButterflyObservationSerializer(observation).data)

    @extend_schema(responses={204: None})
    def delete(self, request, observation_id):
        """Soft delete. The row is no longer visible here, so a second call is a 404."""
        with transaction.atomic():
            observation = _observation_or_404(request.user, observation_id)
            services.remove_observation(request.user, observation)
        return Response(status=status.HTTP_204_NO_CONTENT)
