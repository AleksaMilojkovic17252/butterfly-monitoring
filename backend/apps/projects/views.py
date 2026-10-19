from django.db.models import Count, Q
from rest_framework import viewsets

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
