import json

from django import forms
from django.contrib import admin, messages
from django.contrib.gis.forms.widgets import OSMWidget
from django.db import connection, transaction
from django.db.models import Count, Q
from django.template.loader import render_to_string
from django.template.response import TemplateResponse
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException, ValidationError

from apps.core.admin import _RULE_ID, HistoryAdmin, SyncableAdmin, add_validation_errors
from apps.observations.models import ButterflyObservation
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


def _refusal_text(visit, error):
    """What an action says when it refused `visit`: a rule ID becomes its sentence."""
    if not isinstance(error.detail, dict):
        return str(error.detail)
    sentences = []
    for field, messages_ in error.detail.items():
        if isinstance(messages_, str):  # DRF keeps a lone string as it is
            messages_ = [messages_]
        for message in messages_:
            if _RULE_ID.match(str(message)):
                message = _explain_rule(visit, field, str(message))[1]
            sentences.append(str(message))
    return " ".join(sentences)


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


class VisitReasonForm(forms.Form):
    """The reason the Lock and Unlock actions ask for. It becomes the visit's history reason."""

    reason = forms.CharField(
        label=_("Reason"),
        min_length=10,
        strip=True,
        widget=forms.Textarea(attrs={"rows": 3}),
        help_text=_("At least 10 characters. It is kept in the visit's history."),
    )


class LockVisitForm(VisitReasonForm):
    allow_missing_points = forms.BooleanField(
        required=False,
        label=_("Lock even if track points are missing"),
        help_text=_(
            "Tick it only when the phone will not send the rest (it was lost or wiped). "
            "Points it still has are refused once the visit is locked."
        ),
    )


class QualityFlagFilter(admin.SimpleListFilter):
    title = _("flag")
    parameter_name = "flag"

    def lookups(self, request, model_admin):
        # The flags in use on live visits, so the list needs no change when T056 adds one.
        with connection.cursor() as db:
            db.execute(
                "SELECT DISTINCT unnest(quality_flags) FROM survey_visit "
                "WHERE deleted_at IS NULL ORDER BY 1"
            )
            return [(flag, flag) for (flag,) in db.fetchall()]

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(quality_flags__contains=[self.value()])
        return queryset


class ObservationInline(admin.TabularInline):
    """The visit's butterfly records as a read-only summary, each with a link to its own page."""

    model = ButterflyObservation
    fk_name = "survey_visit"
    fields = [
        "observed_at",
        "taxon",
        "count",
        "source",
        "identification_confidence",
        "transect_section",
        "validation_status",
    ]
    readonly_fields = fields
    show_change_link = True
    extra = 0
    can_delete = False

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .filter(deleted_at__isnull=True)
            .select_related("taxon", "transect_section")
            .order_by("observed_at")
        )

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(SurveyVisit)
class SurveyVisitAdmin(HistoryAdmin, SyncableAdmin):
    """Visits are recorded on the phone. An admin may correct an unlocked visit (saved through
    `services.admin_save_visit`, T042); its status moves only through actions: Mark as reviewed,
    and Lock and Unlock, which ask for a reason (T043). A locked visit opens read-only with a
    banner saying who locked it and why. The page lists the visit's observations and ends with
    the route drawn from the track points (T036).
    """

    form = SurveyVisitAdminForm
    change_form_template = "admin/surveys/surveyvisit/change_form.html"
    # Never edited in the admin: the status and the cancel reason move through the lifecycle, a
    # visit cannot change project (D-058), the distance comes from the track (T036), the lock
    # fields belong to the Lock and Unlock actions, the flags to T056, the pauses and the point
    # count come from the phone (T040), and the device and offline flag record where the visit
    # came from.
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
        "duration",
        "distance",
        "observation_count",
        "status",
        "flags",
        "outcome",
        "project",
        "last_modified",
    ]
    list_filter = [
        "project",
        ("transect", admin.RelatedOnlyFieldListFilter),
        "status",
        ("observer", admin.RelatedOnlyFieldListFilter),
        "started_at",
        QualityFlagFilter,
    ]
    search_fields = ["transect__code", "transect__name", "observer__email", "notes"]
    ordering = ["-started_at"]
    list_select_related = ["transect", "observer", "project"]
    inlines = [ObservationInline]
    actions = ["mark_reviewed_selected", "lock_selected", "unlock_selected"]

    def get_queryset(self, request):
        queryset = super().get_queryset(request)
        # The list's observation count, on the list only (the change and history pages do not
        # need the join). The actions load each visit again before changing it: the GROUP BY of
        # this count does not combine with FOR UPDATE.
        if getattr(request.resolver_match, "url_name", None) != "surveys_surveyvisit_changelist":
            return queryset
        return queryset.annotate(
            observation_count=Count("observations", filter=Q(observations__deleted_at__isnull=True))
        )

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

    @admin.display(description=_("Duration"), ordering="duration_seconds")
    def duration(self, visit):
        if visit.duration_seconds is None:
            return ""
        return f"{visit.duration_seconds // 3600}:{visit.duration_seconds % 3600 // 60:02d}"

    @admin.display(description=_("Distance"), ordering="distance_walked_m")
    def distance(self, visit):
        if visit.distance_walked_m is None:
            return ""
        return f"{visit.distance_walked_m} m"

    @admin.display(description=_("Observations"), ordering="observation_count")
    def observation_count(self, visit):
        return visit.observation_count

    @admin.display(description=_("Flags"))
    def flags(self, visit):
        return ", ".join(visit.quality_flags)

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
        # A locked visit opens read-only until the Unlock action (T042, T043). Its records follow
        # the same rule: a child admin (T044+) checks `services.is_locked(obj.survey_visit)`.
        if obj is not None and services.is_locked(obj):
            return False
        return super().has_change_permission(request, obj)

    def _apply_to_each(self, request, visit_ids, change, done_message):
        """Run `change(visit)` on each visit in its own transaction, so a refused visit is named
        in an error message and the others still change."""
        done_count = 0
        refused_visits = []
        for visit_id in visit_ids:
            try:
                with transaction.atomic():
                    # Load it again, locked: a push may have changed it since the list was
                    # shown, and saving an older copy would undo that change.
                    visit = (
                        SurveyVisit.objects.alive().select_for_update().filter(pk=visit_id).first()
                    )
                    if visit is None:
                        continue  # deleted in the meantime
                    change(visit)
            except APIException as error:
                refused_visits.append(f"{visit} ({_refusal_text(visit, error)})")
                continue
            done_count += 1
        if done_count or not refused_visits:
            self.message_user(request, done_message % {"count": done_count})
        if refused_visits:
            self.message_user(
                request,
                _("Not changed: %(visits)s") % {"visits": "; ".join(refused_visits)},
                messages.ERROR,
            )

    def _ask_for_reason(
        self,
        request,
        queryset,
        action,
        title,
        intro,
        form_class,
        change_for,
        note_short_tracks=False,
    ):
        """The page between the list and the change: the selected visits and a reason form.

        The list posts the action; this page posts back with "apply". `change_for(cleaned_data)`
        gives the `change(visit)` for `_apply_to_each` and the success text. With
        `note_short_tracks` each visit that lacks track points carries `missing_points`.
        """
        visits = list(queryset.filter(deleted_at__isnull=True).order_by("started_at"))
        if not visits:
            self.message_user(request, _("Select at least one visit."), messages.ERROR)
            return None
        if note_short_tracks:
            for visit in visits:
                visit.missing_points = services.missing_track_points(visit)
        form = form_class(request.POST if "apply" in request.POST else None)
        if "apply" in request.POST and form.is_valid():
            change, done_message = change_for(form.cleaned_data)
            self._apply_to_each(request, [visit.pk for visit in visits], change, done_message)
            return None
        context = {
            **self.admin_site.each_context(request),
            "title": title,
            "intro": intro,
            "opts": self.model._meta,
            "visits": visits,
            "form": form,
            "action": action,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/surveys/surveyvisit/visit_reason.html", context)

    @admin.action(description=_("Mark as reviewed"), permissions=["change"])
    def mark_reviewed_selected(self, request, queryset):
        visit_ids = list(queryset.filter(deleted_at__isnull=True).values_list("pk", flat=True))
        self._apply_to_each(
            request,
            visit_ids,
            lambda visit: services.mark_reviewed(visit, request.user),
            _("Marked %(count)d visit(s) reviewed."),
        )

    @admin.action(description=_("Lock…"), permissions=["change"])
    def lock_selected(self, request, queryset):
        def change_for(cleaned_data):
            return (
                lambda visit: services.lock_visit(
                    visit,
                    request.user,
                    cleaned_data["reason"],
                    allow_missing_points=cleaned_data["allow_missing_points"],
                ),
                _("Locked %(count)d visit(s)."),
            )

        return self._ask_for_reason(
            request,
            queryset,
            "lock_selected",
            _("Lock visits"),
            _(
                "Locking a visit makes it read-only: the phones can no longer change it or its "
                "records, and neither can the admin. The reason is kept in its history."
            ),
            LockVisitForm,
            change_for,
            note_short_tracks=True,
        )

    @admin.action(description=_("Unlock…"), permissions=["change"])
    def unlock_selected(self, request, queryset):
        def change_for(cleaned_data):
            return (
                lambda visit: services.unlock_visit(visit, request.user, cleaned_data["reason"]),
                _("Unlocked %(count)d visit(s)."),
            )

        return self._ask_for_reason(
            request,
            queryset,
            "unlock_selected",
            _("Unlock visits"),
            _(
                "An unlocked visit becomes 'reviewed' and can be changed again. The reason is "
                "kept in its history."
            ),
            VisitReasonForm,
            change_for,
        )
