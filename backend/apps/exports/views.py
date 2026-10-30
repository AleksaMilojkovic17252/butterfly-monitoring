"""Admin-only export endpoints (T064). The work is in `exports.service`."""

from django.http import FileResponse, StreamingHttpResponse
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.negotiation import BaseContentNegotiation
from rest_framework.permissions import IsAuthenticated
from rest_framework.renderers import JSONRenderer
from rest_framework.views import APIView

from apps.accounts.permissions import IsAdminGroup
from apps.exports import service


class JSONOnlyNegotiation(BaseContentNegotiation):
    """Always the JSON renderer, which only draws error bodies here.

    DRF reads `?format=` as its own renderer override, so `format=csv` would be a 404. These
    views use `format` for the file format instead.
    """

    def select_parser(self, request, parsers):
        return parsers[0]

    def select_renderer(self, request, renderers, format_suffix=None):
        renderer = JSONRenderer()
        return renderer, renderer.media_type


class ExportView(APIView):
    renderer_classes = [JSONRenderer]
    content_negotiation_class = JSONOnlyNegotiation
    permission_classes = [IsAuthenticated, IsAdminGroup]


PROJECT = OpenApiParameter("project", OpenApiTypes.UUID, description="Only this project")
FROM = OpenApiParameter(
    "from", OpenApiTypes.DATE, description="First day to include (UTC); not for transects"
)
TO = OpenApiParameter(
    "to", OpenApiTypes.DATE, description="Last day to include (UTC); not for transects"
)
NA = OpenApiParameter(
    "na", OpenApiTypes.STR, description="Missing-value code in CSV (default NA, may be empty)"
)
EXCEL = OpenApiParameter(
    "excel", OpenApiTypes.BOOL, description="CSV starts with a byte order mark, for Excel"
)
FORMAT = OpenApiParameter(
    "format",
    OpenApiTypes.STR,
    enum=["csv", "geojson", "json"],
    description="File format (default csv)",
)
TRACK_POINTS = OpenApiParameter(
    "track_points", OpenApiTypes.BOOL, description="Add the (large) track points to the bundle"
)


class ExportDatasetView(ExportView):
    @extend_schema(
        parameters=[FORMAT, PROJECT, FROM, TO, NA, EXCEL],
        responses={
            (200, "text/csv"): OpenApiTypes.BINARY,
            (200, "application/geo+json"): OpenApiTypes.BINARY,
            (200, "application/json"): OpenApiTypes.BINARY,
        },
        description="One dataset as a file, streamed. Datasets: survey_visits, "
        "butterfly_observations, transects, transect_sections, environmental_snapshots, "
        "track_points. Admins only.",
    )
    def get(self, request, dataset):
        fmt = service.parse_format(request.query_params)
        filters = service.parse_filters(request.query_params)
        chunks, content_type, filename = service.export(request.user, dataset, fmt, filters)
        response = StreamingHttpResponse(chunks, content_type=content_type)
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        return response


class ExportBundleView(ExportView):
    @extend_schema(
        parameters=[PROJECT, FROM, TO, NA, EXCEL, TRACK_POINTS],
        responses={(200, "application/zip"): OpenApiTypes.BINARY},
        description="A ZIP of one project's CSV files and metadata.json. `project` is required. "
        "Admins only.",
    )
    def get(self, request):
        filters = service.parse_filters(request.query_params)
        file, filename = service.bundle(request.user, filters)
        return FileResponse(file, as_attachment=True, filename=filename)
