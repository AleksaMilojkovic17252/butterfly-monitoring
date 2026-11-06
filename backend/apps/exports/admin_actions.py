from django.contrib import admin
from django.http import StreamingHttpResponse
from django.utils.translation import gettext_lazy as _

from apps.exports import service


class ExportActionsMixin:
    """Export selected as CSV / GeoJSON through the export service (T065, D-101).

    The selected rows go to `service.export` as `selected`, so scoping, live rows only, columns
    and ordering are the API's. The admin offers no options: API defaults.
    """

    export_dataset = None  # a name in exports.datasets.DATASETS
    export_actions = ["export_selected_csv", "export_selected_geojson"]

    def export_response(self, request, queryset, fmt):
        filters = service.parse_filters({})
        chunks, content_type, filename = service.export(
            request.user, self.export_dataset, fmt, filters, selected=queryset
        )
        response = StreamingHttpResponse(chunks, content_type=content_type)
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        return response

    @admin.action(description=_("Export selected as CSV"), permissions=["view"])
    def export_selected_csv(self, request, queryset):
        return self.export_response(request, queryset, "csv")

    @admin.action(description=_("Export selected as GeoJSON"), permissions=["view"])
    def export_selected_geojson(self, request, queryset):
        return self.export_response(request, queryset, "geojson")
