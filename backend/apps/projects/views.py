from django.core.files.storage import default_storage
from django.db.models import Count, Q
from django.http import FileResponse, Http404
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import viewsets
from rest_framework.decorators import action

from apps.projects.models import Project
from apps.projects.serializers import ProjectSerializer
from apps.projects.services import projects_for


class ProjectViewSet(viewsets.ReadOnlyModelViewSet):
    """The caller's projects. A project the caller cannot see is a 404, not a 403."""

    serializer_class = ProjectSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):  # schema generation has no user
            return Project.objects.none()
        live = Q(transects__deleted_at__isnull=True)
        return (
            projects_for(self.request.user)
            .annotate(transect_count=Count("transects", filter=live))
            .order_by("name")
        )

    @extend_schema(
        responses={(200, "application/vnd.sqlite3"): OpenApiTypes.BINARY, 404: OpenApiResponse()}
    )
    @action(detail=True, methods=["get"], pagination_class=None)
    def basemap(self, request, pk=None):
        """The project's MBTiles file (T060, D-102). Through Django, never a presigned URL."""
        project = self.get_object()  # a non-member gets 404 (D-036)
        if not project.basemap:
            raise Http404("This project has no basemap.")
        response = FileResponse(
            default_storage.open(project.basemap.name, "rb"),
            content_type="application/vnd.sqlite3",
        )
        # dio's progress bar needs the length up front.
        # (basemap_size is set by the admin; the storage knows it too if it is ever missing).
        response["Content-Length"] = project.basemap_size or project.basemap.size
        return response
