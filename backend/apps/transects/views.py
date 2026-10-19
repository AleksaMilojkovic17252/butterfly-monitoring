from django.shortcuts import get_object_or_404
from rest_framework import generics

from apps.projects.services import projects_for
from apps.transects.models import Transect
from apps.transects.serializers import TransectDetailSerializer, TransectSerializer
from apps.transects.services import transects_for, with_sections, with_stats


class ProjectTransectList(generics.ListAPIView):
    """Transects of one project. A project the caller cannot see is a 404, not a 403."""

    serializer_class = TransectSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):  # schema generation has no user
            return Transect.objects.none()
        user = self.request.user
        project = get_object_or_404(projects_for(user), pk=self.kwargs["project_id"])
        return with_stats(transects_for(user).filter(project=project), user).order_by("code")


class TransectDetail(generics.RetrieveAPIView):
    """One transect with its live sections. Outside the caller's projects it is a 404."""

    serializer_class = TransectDetailSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Transect.objects.none()
        user = self.request.user
        return with_sections(with_stats(transects_for(user), user))
