from django.contrib import admin
from django.contrib.gis.admin import GISModelAdmin
from django.utils.translation import gettext_lazy as _


class DeletedFilter(admin.SimpleListFilter):
    title = _("deleted")
    parameter_name = "deleted"

    def lookups(self, request, model_admin):
        return [("no", _("No")), ("yes", _("Yes"))]

    def queryset(self, request, queryset):
        if self.value() == "yes":
            return queryset.filter(deleted_at__isnull=False)
        if self.value() == "no":
            return queryset.filter(deleted_at__isnull=True)
        return queryset


class SyncableAdmin(admin.ModelAdmin):
    """Admin base for synced models: no hard delete, soft delete as a bulk action.

    Combine with history by putting it second: `class XAdmin(SimpleHistoryAdmin, SyncableAdmin)`
    (T018). The sync bookkeeping fields are read-only.
    """

    sync_readonly_fields = (
        "server_version",
        "created_at",
        "created_by",
        "updated_at",
        "updated_by",
    )

    def get_readonly_fields(self, request, obj=None):
        fields = list(super().get_readonly_fields(request, obj))
        return fields + [f for f in self.sync_readonly_fields if f not in fields]

    def get_list_filter(self, request):
        return [*super().get_list_filter(request), DeletedFilter]

    def has_delete_permission(self, request, obj=None):
        return False

    def get_actions(self, request):
        actions = super().get_actions(request)
        actions.pop("delete_selected", None)
        return actions

    actions = ["soft_delete_selected"]

    @admin.action(description=_("Soft delete selected"), permissions=["change"])
    def soft_delete_selected(self, request, queryset):
        # One save per row (not QuerySet.update) so the sync trigger and history both fire.
        count = 0
        for obj in queryset.filter(deleted_at__isnull=True):
            obj.soft_delete(request.user)
            count += 1
        self.message_user(request, _("Soft deleted %(count)d row(s).") % {"count": count})


class MapAdmin(GISModelAdmin):
    """Admin base with an OSM map widget, centred on the project area when it is known.

    Subclasses with a project link can override `get_map_center`; the default looks for
    `obj.project.area` (MultiPolygon, T016) and uses its centroid.
    """

    gis_widget_kwargs = {"attrs": {"default_zoom": 13}}

    def get_map_center(self, request, obj):
        area = getattr(getattr(obj, "project", None), "area", None)
        if area is None or area.empty:
            return None
        return area.centroid.x, area.centroid.y

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        center = self.get_map_center(request, obj) if obj is not None else None
        if center:
            for field in form.base_fields.values():
                widget = field.widget
                if hasattr(widget, "default_lon"):
                    widget.attrs["default_lon"], widget.attrs["default_lat"] = center
        return form
