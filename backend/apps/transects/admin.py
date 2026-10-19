import json
import uuid

from django.contrib import admin, messages
from django.contrib.admin.utils import unquote
from django.contrib.gis.db.models import LineStringField
from django.core.exceptions import PermissionDenied
from django.forms.formsets import DELETION_FIELD_NAME
from django.forms.models import BaseInlineFormSet
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect
from django.template.response import TemplateResponse
from django.urls import path, reverse
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.core.history import save_with_reason
from apps.core.widgets import LineMapWidget
from apps.transects.forms import GenerateSectionsForm, LineImportForm
from apps.transects.models import Transect, TransectSection
from apps.transects.services import (
    SECTION_TOLERANCE_M,
    LineFileError,
    SectionGenerationError,
    generate_sections,
    linestring_from_file,
    section_length_mismatch,
    with_stats,
)

# Section lines are drawn solid in this colour, as wide as the dashed transect line under them.
SECTION_COLOR = "#c2255c"


def line_widget_kwargs(note, feature_color=None):
    """MapAdmin's map settings plus a line of field-specific help in the "?" popup."""
    attrs = {**MapAdmin.gis_widget_kwargs["attrs"], "help_note": note}
    if feature_color:
        attrs["feature_color"] = feature_color
    return {"attrs": attrs}


class SectionFormSet(BaseInlineFormSet):
    def clean(self):
        """Refuse a code or number that two kept rows share.

        The unique constraints only cover live rows, which Django's form validation does not
        check, so a clash would reach the database as an IntegrityError. Rows ticked "Remove"
        are skipped: they are soft-deleted before the others are saved.
        """
        super().clean()
        seen = {"section_code": {}, "sequence_number": {}}
        for form in self.forms:
            data = getattr(form, "cleaned_data", None)
            if not data or self._should_delete_form(form):
                continue
            for field, used in seen.items():
                value = data.get(field)
                if value in (None, ""):
                    continue
                if value in used:
                    form.add_error(
                        field,
                        _("Another section of this transect already uses “%(value)s”.")
                        % {"value": value},
                    )
                else:
                    used[value] = form

    def add_fields(self, form, index):
        super().add_fields(form, index)
        if DELETION_FIELD_NAME in form.fields:
            # The row is soft-deleted on save (TransectAdmin.save_formset), not erased.
            form.fields[DELETION_FIELD_NAME].label = _("Remove")


class TransectSectionInline(admin.StackedInline):
    """The transect's live sections, collapsed. Rows are added with "Add another" (the map of the
    new row is started by transect_inline_maps.js) or the "Generate" action. Ticking "Remove" on
    a row soft-deletes it when the transect is saved; "Restore selected" on the section list
    brings it back."""

    model = TransectSection
    formset = SectionFormSet
    extra = 0
    classes = ["collapse"]
    ordering = ["sequence_number"]
    fields = [
        "section_code",
        "sequence_number",
        "habitat_type",
        "management_type",
        "notes",
        "geometry",
    ]
    autocomplete_fields = ["habitat_type", "management_type"]
    show_change_link = True

    def get_queryset(self, request):
        return super().get_queryset(request).alive()

    def formfield_for_dbfield(self, db_field, request, **kwargs):
        if isinstance(db_field, LineStringField):
            kwargs["widget"] = LineMapWidget(
                **line_widget_kwargs(
                    _("The section must lie within %(m)g m of the transect line.")
                    % {"m": SECTION_TOLERANCE_M},
                    SECTION_COLOR,
                )
            )
        return super().formfield_for_dbfield(db_field, request, **kwargs)


@admin.register(Transect)
class TransectAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    list_display = ["code", "name", "project", "active", "length", "sections"]
    list_select_related = ["project"]
    list_filter = ["project", "active"]
    search_fields = ["code", "name"]
    autocomplete_fields = ["project"]
    # Soft delete and restore are list actions, so the field is not edited on the form.
    exclude = ["deleted_at"]
    inlines = [TransectSectionInline]
    actions = [*SyncableAdmin.actions, "generate_equal_sections"]
    change_form_template = "admin/transects/transect_change_form.html"
    gis_widget = LineMapWidget
    gis_widget_kwargs = line_widget_kwargs(
        _(
            "Draw the route in the direction it is walked; sections are numbered along it. "
            "To load a GPX, KML or GeoJSON file, use “Import line” at the top of a saved transect."
        )
    )

    class Media:
        css = {"all": ("transects/section_inline.css",)}
        js = ("transects/transect_inline_maps.js",)

    def get_queryset(self, request):
        return with_stats(super().get_queryset(request), request.user)

    @admin.display(description=_("Length (m)"), ordering="length_m")
    def length(self, transect):
        return round(transect.length_m)

    @admin.display(description=_("Sections"), ordering="section_count")
    def sections(self, transect):
        return transect.section_count

    def get_urls(self):
        import_line = path(
            "<uuid:pk>/import-line/",
            self.admin_site.admin_view(self.import_line_view),
            name="transects_transect_import_line",
        )
        return [import_line, *super().get_urls()]

    def changeform_view(self, request, object_id=None, form_url="", extra_context=None):
        if request.method == "GET" and object_id:
            transect = self.get_object(request, unquote(object_id))
            mismatch = section_length_mismatch(transect) if transect else None
            if mismatch:
                sections_m, transect_m = mismatch
                messages.warning(
                    request,
                    _(
                        "The sections add up to %(sections).0f m but the transect is "
                        "%(transect).0f m long (more than 2 %% apart). Check the section lines."
                    )
                    % {"sections": sections_m, "transect": transect_m},
                )
        return super().changeform_view(request, object_id, form_url, extra_context)

    def import_line_view(self, request, pk):
        transect = get_object_or_404(Transect.objects.alive(), pk=pk)
        if not self.has_change_permission(request, transect):
            raise PermissionDenied
        form = LineImportForm(request.POST or None, request.FILES or None)
        if request.method == "POST" and form.is_valid():
            upload = form.cleaned_data["file"]
            try:
                transect.geometry = linestring_from_file(upload)
            except LineFileError as exc:
                form.add_error("file", str(exc))
            else:
                save_with_reason(transect, request.user, f"Line imported from {upload.name}")
                self.message_user(
                    request,
                    _("The line of %(t)s was replaced. Check that its sections still follow it.")
                    % {"t": transect},
                )
                return redirect("admin:transects_transect_change", transect.pk)
        context = {
            **self.admin_site.each_context(request),
            "title": _("Import line"),
            "opts": self.model._meta,
            "transect": transect,
            "form": form,
        }
        return TemplateResponse(request, "admin/transects/import_line.html", context)

    @admin.action(description=_("Generate N equal sections…"), permissions=["change"])
    def generate_equal_sections(self, request, queryset):
        if queryset.count() != 1:
            self.message_user(request, _("Select exactly one transect."), messages.ERROR)
            return None
        transect = queryset.get()
        if transect.deleted_at is not None:
            self.message_user(request, _("Restore the transect first."), messages.ERROR)
            return None
        applying = "apply" in request.POST
        form = GenerateSectionsForm(request.POST if applying else None)
        # The changelist posts the action; the confirm page posts back with "apply".
        if applying and form.is_valid():
            try:
                sections = generate_sections(transect, user=request.user, **form.cleaned_data)
            except SectionGenerationError as exc:
                form.add_error(None, str(exc))
            else:
                self.message_user(
                    request,
                    _("Created %(n)d sections for %(t)s.") % {"n": len(sections), "t": transect},
                )
                return None
        context = {
            **self.admin_site.each_context(request),
            "title": _("Generate equal sections"),
            "opts": self.model._meta,
            "transect": transect,
            "form": form,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/transects/generate_sections.html", context)

    def save_formset(self, request, form, formset, change):
        # commit=False leaves removed rows in `deleted_objects` instead of erasing them. They go
        # first so that a code or number they held can be reused by a row saved in the same form.
        # `save` must run before the loop: it fills `deleted_objects`.
        sections = formset.save(commit=False)
        for section in formset.deleted_objects:
            section.soft_delete(request.user)
        for section in sections:
            if section._state.adding:
                section.created_by = request.user
            section.updated_by = request.user
            section.save()
        formset.save_m2m()

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(TransectSection)
class TransectSectionAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    list_display = [
        "section_code",
        "transect",
        "sequence_number",
        "habitat_type",
        "active_transect",
    ]
    list_select_related = ["transect", "habitat_type"]
    list_filter = ["transect__project", "transect", "habitat_type"]
    search_fields = ["section_code", "transect__code", "transect__name"]
    autocomplete_fields = ["transect", "habitat_type", "management_type"]
    exclude = ["deleted_at"]
    gis_widget = LineMapWidget
    gis_widget_kwargs = line_widget_kwargs(
        _(
            "Pick the transect first: its line is shown dashed, and new points snap to it. "
            "The section must lie within %(m)g m of that line along its whole length."
        )
        % {"m": SECTION_TOLERANCE_M},
        SECTION_COLOR,
    )

    class Media:
        js = ("transects/section_map.js",)

    def get_urls(self):
        line = path(
            "transect-line/<uuid:pk>/",
            self.admin_site.admin_view(self.transect_line),
            name="transects_transectsection_transect_line",
        )
        return [line, *super().get_urls()]

    def transect_line(self, request, pk):
        """The transect's line as GeoJSON, for the reference line on the section map."""
        if not self.has_view_or_change_permission(request):
            raise PermissionDenied
        transect = get_object_or_404(Transect.objects.alive(), pk=pk)
        return JsonResponse(
            {"code": transect.code, "geometry": json.loads(transect.geometry.geojson)}
        )

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        field = super().formfield_for_foreignkey(db_field, request, **kwargs)
        if db_field.name == "transect":
            # section_map.js swaps the zero UUID for the chosen transect's id.
            field.widget.attrs["data-line-url"] = reverse(
                "admin:transects_transectsection_transect_line", args=[uuid.UUID(int=0)]
            )
        return field

    @admin.display(boolean=True, description="Transect active")
    def active_transect(self, section):
        return section.transect.active

    def get_map_center(self, request, obj):
        line = obj.transect.geometry
        return line.centroid.x, line.centroid.y

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)
