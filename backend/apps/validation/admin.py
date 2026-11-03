from django import forms
from django.contrib import admin, messages
from django.contrib.admin.widgets import AutocompleteSelect
from django.core.exceptions import PermissionDenied
from django.db.models import Prefetch
from django.http import HttpResponseBadRequest, HttpResponseNotAllowed
from django.shortcuts import redirect
from django.template.response import TemplateResponse
from django.urls import path, reverse
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException

from apps.catalogues.models import Taxon
from apps.core.admin import ReadOnlyMapMixin
from apps.observations import services as observation_services
from apps.observations.admin import PhotoInline, _refusal_text, _thumbnail_link
from apps.observations.models import ButterflyObservation, Photo, UploadStatus
from apps.projects.services import projects_for
from apps.validation.inlines import ValidationEventInline
from apps.validation.models import Decision, ValidationQueueItem
from apps.validation.services import decide, queue_filter

# The decisions the record's page may post directly. Change taxon needs its own form, and reset
# is the observation list's Send back action.
PAGE_DECISIONS = [Decision.CONFIRMED, Decision.UNCONFIRMED, Decision.UNDETERMINABLE]


class FlagFilter(admin.SimpleListFilter):
    title = _("flag")
    parameter_name = "flag"

    def lookups(self, request, model_admin):
        # The codes T056 raises on an observation (docs/requirements/codelists.md).
        return [
            ("outside_project_area", _("Outside project area")),
            ("far_from_transect", _("Far from transect")),
            ("high_count", _("High count")),
        ]

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(quality_flags__contains=[self.value()])
        return queryset


class ChangeTaxonForm(forms.Form):
    new_taxon = forms.ModelChoiceField(
        label=_("Taxon"),
        queryset=Taxon.objects.none(),
        widget=AutocompleteSelect(
            ButterflyObservation._meta.get_field("validated_taxon"), admin.site
        ),
    )
    comment = forms.CharField(
        label=_("Comment"),
        widget=forms.Textarea(attrs={"rows": 3}),
        help_text=_("Why the species is changed. It is kept in the validation history."),
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # A retired taxon still shows in the search box (it goes through TaxonAdmin) but is
        # refused here: the validator must pick the current name.
        self.fields["new_taxon"].queryset = Taxon.objects.alive().filter(retired_in__isnull=True)


class PhotoGalleryInline(PhotoInline):
    """Every photo of the record at full size, read-only (T057)."""

    template = "admin/edit_inline/stacked.html"
    fields = ["full_size", "upload_status", "is_primary", "captured_at"]
    readonly_fields = fields

    @admin.display(description=_("Photo"))
    def full_size(self, photo):
        """The original, linking to itself. The width is not a percentage: the admin puts
        read-only values in a flex box, where a percentage collapses."""
        if photo.upload_status != UploadStatus.UPLOADED:
            return _("Not uploaded yet")
        url = reverse("photo-content", args=[photo.pk])
        return format_html(
            '<a href="{}"><img src="{}" style="max-height: 80vh; '
            'max-width: clamp(320px, calc(100vw - 640px), 960px);"></a>',
            url,
            url,
        )


@admin.register(ValidationQueueItem)
class ValidationQueueItemAdmin(ReadOnlyMapMixin, admin.ModelAdmin):
    """The observations that wait for an expert (T057, D-091).

    A plain `ModelAdmin` on a proxy: `HistoryAdmin` cannot work on a proxy, and the soft delete
    of `SyncableAdmin` has no place here. A decision goes through `validation.services.decide`,
    which loads the real `ButterflyObservation`: never save a proxy instance, it writes no
    history row. The page is view-only; the decision buttons are forms outside the main one.
    """

    location_map_height = "240px"
    change_form_template = "admin/validation/validationqueueitem/change_form.html"

    list_display = [
        "thumbnail",
        "taxon",
        "count",
        "life_stage",
        "observed_at",
        "recorded_by",
        "identification_confidence",
        "flags",
        "project",
    ]
    list_display_links = ["taxon"]
    list_select_related = ["taxon", "recorded_by", "project"]
    ordering = ["-observed_at"]
    list_filter = [
        "project",
        "taxon__family",
        "identification_confidence",
        FlagFilter,
        "observed_at",
    ]
    search_fields = [
        "taxon__scientific_name",
        "taxon__vernacular_name_sr",
        "taxon__vernacular_name_en",
    ]
    fields = [
        "observation_link",
        "project",
        "survey_visit",
        "taxon",
        "count",
        "observed_at",
        "recorded_by",
        "identification_confidence",
        "sex",
        "life_stage",
        "behaviour",
        "microhabitat",
        "notes",
        "location_accuracy_m",
        "location_map",
        "validation_status",
        "quality_flags",
    ]
    readonly_fields = fields
    inlines = [PhotoGalleryInline, ValidationEventInline]
    actions = [
        "confirm_selected",
        "mark_unconfirmed_selected",
        "mark_undeterminable_selected",
        "change_taxon",
    ]

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .alive()
            .filter(queue_filter(), project__in=projects_for(request.user))
            .prefetch_related(
                Prefetch(
                    "photos",
                    queryset=Photo.objects.alive()
                    .filter(upload_status=UploadStatus.UPLOADED)
                    .order_by("-is_primary", "created_at"),
                    to_attr="shown_photos",
                )
            )
        )

    @admin.display(description=_("Photo"))
    def thumbnail(self, observation):
        """The primary uploaded photo, else the oldest uploaded one."""
        if not observation.shown_photos:
            return "-"
        return _thumbnail_link(observation.shown_photos[0], max_width=80)

    @admin.display(description=_("Flags"))
    def flags(self, observation):
        return ", ".join(observation.quality_flags) or "-"

    @admin.display(description=_("Observation"))
    def observation_link(self, observation):
        """The observation's own page, which has its change history."""
        return format_html(
            '<a href="{}">{}</a>',
            reverse("admin:observations_butterflyobservation_change", args=[observation.pk]),
            _("Open the observation (change history)"),
        )

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        # With no object this answers for the actions, which need it to be True. With one the
        # page is view-only: the decisions are forms of their own, not part of this one.
        if obj is not None:
            return False
        return super().has_change_permission(request)

    def render_change_form(self, request, context, *args, obj=None, **kwargs):
        context["visit_locked"] = obj is not None and observation_services.is_locked(obj)
        return super().render_change_form(request, context, *args, obj=obj, **kwargs)

    def get_urls(self):
        # Before the admin's own URLs: its `<path:object_id>/` would take this one.
        return [
            path(
                "<uuid:object_id>/decide/",
                self.admin_site.admin_view(self.decide_view),
                name="validation_validationqueueitem_decide",
            ),
            *super().get_urls(),
        ]

    def decide_view(self, request, object_id):
        """The buttons on the record's page: Confirm, Mark unconfirmed, Mark undeterminable."""
        if request.method != "POST":
            return HttpResponseNotAllowed(["POST"])
        if not self.has_change_permission(request):
            raise PermissionDenied
        try:
            decision = Decision(request.POST.get("decision"))
        except ValueError:
            return HttpResponseBadRequest("Unknown decision.")
        if decision not in PAGE_DECISIONS:
            return HttpResponseBadRequest("Unknown decision.")
        if not self.get_queryset(request).filter(pk=object_id).exists():
            self.message_user(
                request, _("That record is no longer in the validation queue."), messages.ERROR
            )
        else:
            self._decide_each(
                request, [object_id], decision, comment=request.POST.get("comment", "").strip()
            )
        return redirect("admin:validation_validationqueueitem_changelist")

    def _decide_each(self, request, ids, decision, new_taxon=None, comment=""):
        """Decide each record in its own transaction, so a refused one (a locked visit) is named
        and the others still change."""
        done = 0
        refused = []
        for observation_id in ids:
            try:
                if decide(observation_id, decision, request.user, new_taxon, comment) is not None:
                    done += 1
            except APIException as error:
                observation = ButterflyObservation.objects.filter(pk=observation_id).first()
                refused.append(f"{observation} ({_refusal_text(observation, error)})")
        if done or not refused:
            self.message_user(
                request,
                _("%(decision)s: %(count)d record(s).")
                % {"decision": Decision(decision).label, "count": done},
            )
        if refused:
            self.message_user(
                request,
                _("Not changed: %(records)s") % {"records": "; ".join(refused)},
                messages.ERROR,
            )

    def _decide_selected(self, request, queryset, decision):
        ids = list(queryset.values_list("pk", flat=True))
        self._decide_each(request, ids, decision)

    @admin.action(description=_("Confirm"), permissions=["change"])
    def confirm_selected(self, request, queryset):
        self._decide_selected(request, queryset, Decision.CONFIRMED)

    @admin.action(description=_("Mark unconfirmed"), permissions=["change"])
    def mark_unconfirmed_selected(self, request, queryset):
        self._decide_selected(request, queryset, Decision.UNCONFIRMED)

    @admin.action(description=_("Mark undeterminable"), permissions=["change"])
    def mark_undeterminable_selected(self, request, queryset):
        self._decide_selected(request, queryset, Decision.UNDETERMINABLE)

    @admin.action(description=_("Change taxon…"), permissions=["change"])
    def change_taxon(self, request, queryset):
        """The page between the list and the change: the selected records, a taxon and a required
        comment. The list posts the action; this page posts back with "apply"."""
        observations = list(queryset.select_related("taxon", "recorded_by"))
        if not observations:
            self.message_user(request, _("Select at least one record."), messages.ERROR)
            return None
        form = ChangeTaxonForm(request.POST if "apply" in request.POST else None)
        if "apply" in request.POST and form.is_valid():
            self._decide_each(
                request,
                [observation.pk for observation in observations],
                Decision.CHANGED_TAXON,
                new_taxon=form.cleaned_data["new_taxon"],
                comment=form.cleaned_data["comment"],
            )
            return None
        context = {
            **self.admin_site.each_context(request),
            "title": _("Change taxon"),
            "opts": self.model._meta,
            "observations": observations,
            "form": form,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(
            request, "admin/validation/validationqueueitem/change_taxon.html", context
        )
