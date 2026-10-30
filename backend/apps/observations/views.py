import uuid

from django.db import transaction
from django.http import FileResponse
from django.shortcuts import get_object_or_404
from django.urls import reverse
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiResponse, extend_schema, inline_serializer
from rest_framework import exceptions, serializers, status
from rest_framework.authentication import SessionAuthentication
from rest_framework.parsers import JSONParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication

from apps.observations import photo_storage, services
from apps.observations.models import ButterflyObservation, UploadStatus
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


# Photos (T049). The metadata syncs through /sync/push; these are the three upload steps and the
# downloads. The phone never talks to MinIO (D-013).


class UploadInit(serializers.Serializer):
    photo_id = serializers.UUIDField()
    sha256 = serializers.CharField(max_length=64)
    file_size = serializers.IntegerField(min_value=0)
    mime_type = serializers.CharField(max_length=50)


def _photo_or_404(user, photo_id):
    """The photo, locked for the rest of the transaction. Outside `photos_for(user)` it is a 404."""
    return get_object_or_404(services.photos_for(user).select_for_update(), pk=photo_id)


class PhotoUploadInit(APIView):
    parser_classes = [JSONParser]

    @extend_schema(
        request=UploadInit,
        responses=inline_serializer(
            "UploadInitResult",
            {
                "status": serializers.ChoiceField(["exists", "upload_required"]),
                "upload_url": serializers.CharField(required=False),
                "server_version": serializers.IntegerField(),
            },
        ),
    )
    def post(self, request):
        """Step 1. `exists`: the bytes are already stored and the photo is linked to them.
        `upload_required`: PUT them to the relative `upload_url`."""
        serializer = UploadInit(data=request.data)
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        with transaction.atomic():
            photo = _photo_or_404(request.user, values["photo_id"])
            result = services.init_upload(
                request.user, photo, values["sha256"], values["file_size"], values["mime_type"]
            )
        if result["status"] == "upload_required":
            # Relative: the phone reaches the laptop under different host names (D-013).
            result["upload_url"] = reverse("photo-upload-content", args=[photo.pk])
        return Response(result)


class PhotoUploadContent(APIView):
    parser_classes = []  # the body is streamed from request.stream, never parsed

    @extend_schema(
        request={"image/jpeg": OpenApiTypes.BINARY, "image/png": OpenApiTypes.BINARY},
        responses={204: None},
    )
    def put(self, request, photo_id):
        """Step 2. The raw file; its SHA-256 and size must equal the photo record's (422).
        Repeating the PUT is fine until `complete`."""
        # No transaction around the stream: the photo is only read.
        photo = get_object_or_404(services.photos_for(request.user), pk=photo_id)
        services.store_content(
            photo,
            request.stream,
            request.content_type,
            request.META.get("CONTENT_LENGTH"),
        )
        return Response(status=status.HTTP_204_NO_CONTENT)


class PhotoUploadComplete(APIView):
    @extend_schema(
        request=None,
        responses=inline_serializer(
            "UploadCompleteResult",
            {
                "status": serializers.CharField(),
                "server_version": serializers.IntegerField(),
                "uploaded_at": serializers.DateTimeField(),
            },
        ),
    )
    def post(self, request, photo_id):
        """Step 3. Makes the thumbnail and marks the photo uploaded. Safe to repeat."""
        with transaction.atomic():
            photo = _photo_or_404(request.user, photo_id)
            result = services.complete_upload(request.user, photo)
        return Response(result)


class PhotoDownload(APIView):
    """An uploaded photo's file, for its owner or an admin. Session login is accepted next to the
    JWT, so the admin pages can show the images (GET only, so CSRF does not matter)."""

    authentication_classes = [JWTAuthentication, SessionAuthentication]
    thumbnail = False

    def get(self, request, photo_id):
        photo = get_object_or_404(
            services.photos_for(request.user), pk=photo_id, upload_status=UploadStatus.UPLOADED
        )
        if self.thumbnail:
            return FileResponse(photo_storage.open_thumbnail(photo), content_type="image/jpeg")
        return FileResponse(photo_storage.open_original(photo), content_type=photo.mime_type)


@extend_schema(responses={(200, "image/*"): OpenApiTypes.BINARY, 404: OpenApiResponse()})
class PhotoContent(PhotoDownload):
    pass


@extend_schema(responses={(200, "image/jpeg"): OpenApiTypes.BINARY, 404: OpenApiResponse()})
class PhotoThumbnail(PhotoDownload):
    thumbnail = True
