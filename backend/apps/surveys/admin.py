import json

from django import forms
from django.contrib import admin, messages
from django.contrib.gis.forms.widgets import OSMWidget
from django.db import transaction
from django.template.loader import render_to_string
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException

from apps.core.admin import HistoryAdmin, SyncableAdmin
from apps.surveys import services
from apps.surveys.models import SurveyVisit


@admin.register(SurveyVisit)
class SurveyVisitAdmin(HistoryAdmin, SyncableAdmin):
    """Visits are recorded on the phone, so the admin only reads them (T034). The one change is
    the "Mark as reviewed" action, which goes through `surveys.state.transition()`. Lock and
    unlock with a reason, and the review screen, are T043. The page ends with the route drawn
    from the track points (T036).
    """

    list_display = ["transect", "observer", "started_at", "status", "project", "last_modified"]
    list_filter = ["status", "project"]
    search_fields = ["transect__code", "transect__name", "observer__email", "notes"]
    ordering = ["-started_at"]
    list_select_related = ["transect", "observer", "project"]
    actions = ["mark_reviewed_selected"]

    def get_readonly_fields(self, request, obj=None):
        return [field.name for field in SurveyVisit._meta.fields] + ["route_map"]

    @property
    def media(self):
        # OpenLayers as Django's own map widget loads it, so the version stays Django's.
        route_media = forms.Media(
            css={"all": ["surveys/route_map.css"]}, js=["surveys/route_map.js"]
        )
        return super().media + OSMWidget().media + route_media

    @admin.display(description=_("Route"))
    def route_map(self, visit):
        route, point_count = services.route_geojson(visit)
        return render_to_string(
            "admin/surveys/surveyvisit/route_map.html",
            {
                "route": route,
                "point_count": point_count,
                "transect_line": json.loads(visit.transect.geometry.geojson),
                "route_id": f"route-{visit.pk}",
                "transect_id": f"transect-{visit.pk}",
            },
        )

    @admin.display(description=_("Last modified"), ordering="updated_at")
    def last_modified(self, visit):
        # The last save on the server (push, REST or admin), not the time of the edit on the phone.
        return visit.updated_at

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        # No edit form: a single visit opens read-only. Without an object Django asks whether
        # actions may run, and the "Mark as reviewed" action needs that.
        return obj is None and super().has_change_permission(request)

    @admin.action(description=_("Mark as reviewed"), permissions=["change"])
    def mark_reviewed_selected(self, request, queryset):
        reviewed_count = 0
        refused_visits = []
        selected_ids = list(queryset.filter(deleted_at__isnull=True).values_list("pk", flat=True))
        for visit_id in selected_ids:
            try:
                with transaction.atomic():
                    # Load it again, locked: a push may have changed it since the list was
                    # shown, and saving an older copy would undo that change.
                    visit = (
                        SurveyVisit.objects.alive().select_for_update().filter(pk=visit_id).first()
                    )
                    if visit is None:
                        continue  # deleted in the meantime
                    services.mark_reviewed(visit, request.user)
            except APIException as error:
                refused_visits.append(f"{visit} ({error.detail})")
                continue
            reviewed_count += 1
        self.message_user(
            request, _("Marked %(count)d visit(s) reviewed.") % {"count": reviewed_count}
        )
        if refused_visits:
            self.message_user(
                request,
                _("Not changed: %(visits)s") % {"visits": "; ".join(refused_visits)},
                messages.ERROR,
            )
