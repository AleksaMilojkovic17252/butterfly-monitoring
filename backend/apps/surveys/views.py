import uuid

from django.db import transaction
from django.db.models import F
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import exceptions, generics, status
from rest_framework.parsers import JSONParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.surveys import services
from apps.surveys.models import SurveyVisit
from apps.surveys.serializers import SurveyVisitSerializer, SurveyVisitSyncSerializer
from apps.transects.services import transects_for

# Outline 14. The app writes through /sync/push; these share its service functions
# (CONVENTIONS A.7). There is no lock endpoint: locking is admin-only (T043).


def _visit_or_404(user, visit_id):
    """The visit, locked for the rest of the transaction. Outside `visits_for(user)` it is a 404."""
    return get_object_or_404(services.visits_for(user).select_for_update(), pk=visit_id)


def _json_object(request):
    """The request body, which must be a JSON object. The views accept JSON only, so the body
    is a plain dict here, or a list or value that is refused."""
    if not isinstance(request.data, dict):
        raise exceptions.ValidationError({"non_field_errors": ["Send a JSON object."]})
    return request.data


def _client_visit_id(data):
    """The client-generated id from the body, or a new one."""
    raw_id = data.get("id")
    if raw_id is None:
        return uuid.uuid4()
    try:
        return uuid.UUID(str(raw_id))
    except ValueError as error:
        raise exceptions.ValidationError({"id": ["Must be a UUID."]}) from error


class SurveyVisitCreate(APIView):
    parser_classes = [JSONParser]

    @extend_schema(request=SurveyVisitSyncSerializer, responses={201: SurveyVisitSerializer})
    def post(self, request):
        """Create a visit. The body may carry the client's `id`; an existing id is a 400."""
        data = _json_object(request)
        visit_id = _client_visit_id(data)
        if SurveyVisit._base_manager.filter(pk=visit_id).exists():
            raise exceptions.ValidationError({"id": ["A visit with this id already exists."]})
        with transaction.atomic():
            visit = services.create_visit(request.user, visit_id, data)
        return Response(SurveyVisitSerializer(visit).data, status=status.HTTP_201_CREATED)


class SurveyVisitDetail(APIView):
    parser_classes = [JSONParser]

    @extend_schema(responses=SurveyVisitSerializer)
    def get(self, request, visit_id):
        visit = get_object_or_404(services.visits_for(request.user), pk=visit_id)
        return Response(SurveyVisitSerializer(visit).data)

    @extend_schema(request=SurveyVisitSyncSerializer, responses=SurveyVisitSerializer)
    def patch(self, request, visit_id):
        """Change some fields. A new `status` goes through the visit lifecycle."""
        with transaction.atomic():
            visit = _visit_or_404(request.user, visit_id)
            services.update_visit(request.user, visit, _json_object(request))
        return Response(SurveyVisitSerializer(visit).data)


class SurveyVisitComplete(APIView):
    parser_classes = [JSONParser]

    @extend_schema(request=SurveyVisitSyncSerializer, responses=SurveyVisitSerializer)
    def post(self, request, visit_id):
        """Finish a visit in progress. End fields (`ended_at`, end weather) may come in the body."""
        with transaction.atomic():
            visit = _visit_or_404(request.user, visit_id)
            services.complete_visit(request.user, visit, _json_object(request))
        return Response(SurveyVisitSerializer(visit).data)


class TransectVisitList(generics.ListAPIView):
    """Visits of one transect, newest first: the caller's own, all of them for admins. A transect
    the caller cannot see is a 404."""

    serializer_class = SurveyVisitSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):  # schema generation has no user
            return SurveyVisit.objects.none()
        user = self.request.user
        transect = get_object_or_404(transects_for(user), pk=self.kwargs["transect_id"])
        return (
            services.visits_for(user)
            .filter(transect=transect)
            # Visits not started yet (drafts) last, as on the phone; PostgreSQL would put
            # NULL first in a descending order.
            .order_by(F("started_at").desc(nulls_last=True), "-created_at")
        )
