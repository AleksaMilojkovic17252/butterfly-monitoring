import json

from django import forms
from django.contrib import admin, messages
from django.contrib.gis.forms.widgets import OSMWidget
from django.db import transaction
from django.template.loader import render_to_string
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException, ValidationError

from apps.core.admin import HistoryAdmin, SyncableAdmin, add_validation_errors
from apps.surveys import services
from apps.surveys.models import CancelReason, SurveyVisit
from apps.surveys.state import VisitLocked, ensure_unlocked


def _label(field_name):
    return str(SurveyVisit._meta.get_field(field_name).verbose_name).capitalize()


def _explain_rule(visit, field, rule_id):
    """The form field to mark and the sentence for a visit rule that refused an admin edit."""
    if rule_id == "V05":
        return field, _(
            "{label} is required for a finished visit. Fill it in, or write why the weather "
            "is missing in 'Weather missing reason'."
        ).format(label=_label(field))
    if rule_id == "V06":
        return field, _(
            "This visit has butterfly records, so 'Zero observation confirmed' must stay "
            "unticked. Tick it only for a visit in which no butterfly was seen."
        )
    if rule_id == "V09":
        # The cancel reason is read-only here, so the field to change is the start time.
        reason = CancelReason(visit.cancel_reason).label
        if visit.cancel_reason == CancelReason.NOT_CONDUCTED:
            text = _(
                "The cancel reason is '{reason}', which means the visit was never started, so "
                "'Started at' must be empty."
            )
        else:
            text = _(
                "The cancel reason is '{reason}', which means the visit was started, so "
                "'Started at' cannot be empty."
            )
        return "started_at", text.format(reason=reason)
    return field, _("'{label}' is not one of the allowed choices.").format(label=_label(field))


class SurveyVisitAdminForm(forms.ModelForm):
    """Runs the service's checks for an admin edit (`services.check_admin_edit`), so a locked
    visit, or a transect or observer that does not fit the project, shows as a form error.

    The form remembers the `server_version` it was opened with. If the visit changed since (a push
    from the phone, a lock, another admin), Save is refused and the admin reloads the page: the
    form would otherwise write its old values over that change.
    """

    opened_version = forms.IntegerField(widget=forms.HiddenInput, required=False)
    admin_user = None  # set by SurveyVisitAdmin.get_form

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["opened_version"].initial = self.instance.server_version

    def clean(self):
        cleaned_data = super().clean()
        # Django admin validates and saves in one transaction, so this lock holds until the save.
        visit = SurveyVisit.objects.select_for_update().get(pk=self.instance.pk)
        try:
            # Checked first, so a lock that landed while the form was open says so.
            ensure_unlocked(visit)
        except VisitLocked as error:
            raise forms.ValidationError(str(error.detail)) from error
        if cleaned_data.get("opened_version") != visit.server_version:
            raise forms.ValidationError(
                _(
                    "This visit was changed after you opened it (on the phone or by another "
                    "admin). Reload the page and make your change again."
                )
            )
        for field_name in self.changed_data:
            if field_name in cleaned_data and field_name != "opened_version":
                setattr(visit, field_name, cleaned_data[field_name])
        # The table's constraints are checked by the ModelForm itself (none of them mixes an
        # editable field with a read-only one), and again by save_visit.
        try:
            services.check_admin_edit(self.admin_user, visit, self.changed_data)
        except ValidationError as error:
            add_validation_errors(
                self, error, lambda field, rule_id: _explain_rule(visit, field, rule_id)
            )
        except APIException as error:
            self.add_error(None, str(error.detail))
        self.visit_to_save = visit
        return cleaned_data


@admin.register(SurveyVisit)
class SurveyVisitAdmin(HistoryAdmin, SyncableAdmin):
    """Visits are recorded on the phone. An admin may correct an unlocked visit (saved through
    `services.admin_save_visit`, T042); its status moves only through actions: "Mark as reviewed"
    here, Lock and Unlock with a reason in T043. A locked visit opens read-only with a banner
    saying who locked it and why. The page ends with the route drawn from the track points (T036).
    """

    form = SurveyVisitAdminForm
    change_form_template = "admin/surveys/surveyvisit/change_form.html"
    # Never edited in the admin: the status and the cancel reason move through the lifecycle, a
    # visit cannot change project (D-058), the distance comes from the track (T036), the lock
    # fields belong to T043's actions, the flags to T056, the pauses and the point count come from
    # the phone (T040), and the device and offline flag record where the visit came from.
    fixed_fields = [
        "id",
        "project",
        "status",
        "cancel_reason",
        "distance_walked_m",
        "pauses",
        "track_point_count",
        "locked_at",
        "locked_by",
        "lock_reason",
        "quality_flags",
        "device_id",
        "created_offline",
        "deleted_at",
    ]

    list_display = [
        "transect",
        "observer",
        "started_at",
        "status",
        "outcome",
        "project",
        "last_modified",
    ]
    list_filter = ["status", "project"]
    search_fields = ["transect__code", "transect__name", "observer__email", "notes"]
    ordering = ["-started_at"]
    list_select_related = ["transect", "observer", "project"]
    actions = ["mark_reviewed_selected"]

    def get_fields(self, request, obj=None):
        # Model order, editable or not, so the form reads like the read-only page did.
        fields = [field.name for field in SurveyVisit._meta.fields]
        fields.insert(fields.index("cancel_reason") + 1, "outcome")
        fields.append("route_map")
        if obj is not None and self.has_change_permission(request, obj):
            fields.append("opened_version")  # the form's own hidden field, only on an edit form
        return fields

    def get_readonly_fields(self, request, obj=None):
        return [
            *super().get_readonly_fields(request, obj),
            *self.fixed_fields,
            "outcome",
            "route_map",
        ]

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        form.admin_user = request.user
        return form

    def save_model(self, request, obj, form, change):
        # The row loaded and checked in the form's clean(), with only the changed fields set.
        services.admin_save_visit(
            form.visit_to_save, request.user, self.get_change_reason(request), form.changed_data
        )

    @property
    def media(self):
        # OpenLayers as Django's own map widget loads it, so the version stays Django's.
        route_media = forms.Media(
            css={"all": ["surveys/route_map.css"]}, js=["surveys/route_map.js"]
        )
        return super().media + OSMWidget().media + route_media

    @admin.display(description=_("Outcome"))
    def outcome(self, visit):
        return visit.outcome

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
        # A locked visit opens read-only until T043's Unlock action (T042). Its records follow
        # the same rule: a child admin (T044+) checks `services.is_locked(obj.survey_visit)`.
        if obj is not None and services.is_locked(obj):
            return False
        return super().has_change_permission(request, obj)

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
