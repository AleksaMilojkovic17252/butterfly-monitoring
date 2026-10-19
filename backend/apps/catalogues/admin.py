from django import forms
from django.contrib import admin, messages
from django.core.exceptions import PermissionDenied
from django.db import transaction
from django.http import HttpResponseRedirect
from django.template.response import TemplateResponse
from django.urls import path, reverse
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from import_export.admin import ImportExportMixin
from import_export.formats.base_formats import CSV

from apps.catalogues.models import (
    HabitatType,
    ManagementType,
    PlantTaxon,
    Taxon,
    TaxonListVersion,
)
from apps.catalogues.resources import (
    HabitatTypeResource,
    ManagementTypeResource,
    PlantTaxonResource,
    TaxonResource,
)
from apps.catalogues.services import (
    TaxonError,
    clear_other_current,
    current_list_version,
    publish_list_version,
    retire_and_replace_taxon,
    synonymise_taxon,
)
from apps.core.admin import HistoryAdmin, SyncableAdmin
from apps.projects.models import Project


class CatalogueAdminMixin(ImportExportMixin):
    """CSV import/export plus list editing for the catalogue admins (T023).

    Import creates and updates rows, so it needs both the add and the change permission.
    Soft-deleted rows are shown read-only in a list_editable changelist.
    """

    import_formats = [CSV]
    export_formats = [CSV]

    def has_import_permission(self, request):
        return self.has_add_permission(request) and self.has_change_permission(request)

    def get_changelist_form(self, request, **kwargs):
        form_class = super().get_changelist_form(request, **kwargs)

        class ChangelistForm(form_class):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs)
                if self.instance.deleted_at is not None:
                    for field in self.fields.values():
                        field.disabled = True

        return ChangelistForm


class RetiredFilter(admin.SimpleListFilter):
    title = _("retired")
    parameter_name = "retired"

    def lookups(self, request, model_admin):
        return [("no", _("No")), ("yes", _("Yes"))]

    def queryset(self, request, queryset):
        if self.value() == "yes":
            return queryset.filter(retired_in__isnull=False)
        if self.value() == "no":
            return queryset.filter(retired_in__isnull=True)
        return queryset


class ReplaceTaxonForm(forms.Form):
    new_scientific_name = forms.CharField(
        max_length=200,
        label=_("New scientific name"),
        help_text=_("The accepted name after the rename, or the name it is synonymised into."),
    )
    new_version = forms.ModelChoiceField(
        queryset=TaxonListVersion.objects.none(),
        label=_("List release"),
        help_text=_("The release that introduces the new name and retires the old one."),
    )
    reason = forms.CharField(required=False, label=_("Reason"), max_length=200)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["new_version"].queryset = TaxonListVersion.objects.alive().order_by(
            "-published_at"
        )


class SynonymiseTaxonForm(forms.Form):
    accepted = forms.ModelChoiceField(
        queryset=Taxon.objects.none(),
        label=_("Accepted taxon"),
        help_text=_("The existing taxon the selected names are synonyms of."),
    )
    new_version = forms.ModelChoiceField(
        queryset=TaxonListVersion.objects.none(),
        label=_("List release"),
        help_text=_("The release that retires the selected names."),
    )
    reason = forms.CharField(required=False, label=_("Reason"), max_length=200)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["accepted"].queryset = (
            Taxon.objects.alive().filter(retired_in__isnull=True).order_by("scientific_name")
        )
        self.fields["new_version"].queryset = TaxonListVersion.objects.alive().order_by(
            "-published_at"
        )
        self.fields["new_version"].initial = current_list_version()


class PublishListVersionForm(forms.Form):
    version_label = forms.CharField(max_length=30, label=_("Version label"))
    source = forms.CharField(max_length=200, label=_("Source"))
    published_at = forms.SplitDateTimeField(
        label=_("Published at"),
        initial=timezone.now,
        widget=admin.widgets.AdminSplitDateTime,
    )
    notes = forms.CharField(required=False, widget=forms.Textarea, label=_("Notes"))
    projects = forms.ModelMultipleChoiceField(
        queryset=Project.objects.none(),
        widget=forms.CheckboxSelectMultiple,
        required=False,
        label=_("Projects to switch"),
        help_text=_("Unticked projects stay on the release they use now."),
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        projects = Project.objects.alive().order_by("name")
        self.fields["projects"].queryset = projects
        current = current_list_version()
        self.fields["projects"].initial = [
            p.pk
            for p in projects
            if p.taxon_list_version_id is None
            or (current is not None and p.taxon_list_version_id == current.pk)
        ]

    def clean_version_label(self):
        label = self.cleaned_data["version_label"].strip()
        # The column is unique across soft-deleted rows too.
        if TaxonListVersion.objects.filter(version_label=label).exists():
            raise forms.ValidationError(_("A release with this label already exists."))
        return label


@admin.register(TaxonListVersion)
class TaxonListVersionAdmin(HistoryAdmin, SyncableAdmin):
    list_display = ["version_label", "source", "published_at", "is_current"]
    list_filter = ["is_current"]
    search_fields = ["version_label", "source"]
    # Soft delete and restore are list actions, so the field is not edited on the form.
    exclude = ["deleted_at"]
    ordering = ["-published_at"]

    def get_urls(self):
        publish = path(
            "publish/",
            self.admin_site.admin_view(self.publish_view),
            name="catalogues_taxonlistversion_publish",
        )
        return [publish, *super().get_urls()]

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        with transaction.atomic():
            if obj.is_current:
                clear_other_current(obj, request.user)
            super().save_model(request, obj, form, change)

    def can_publish(self, request):
        return self.has_add_permission(request) and self.has_change_permission(request)

    def changelist_view(self, request, extra_context=None):
        extra_context = {**(extra_context or {}), "can_publish": self.can_publish(request)}
        return super().changelist_view(request, extra_context)

    def publish_view(self, request):
        if not self.can_publish(request):
            raise PermissionDenied
        form = PublishListVersionForm(request.POST or None)
        if request.method == "POST" and form.is_valid():
            data = form.cleaned_data
            projects = list(data["projects"])
            version = publish_list_version(
                data["version_label"],
                data["source"],
                data["published_at"],
                data["notes"],
                projects,
                request.user,
            )
            self.message_user(
                request,
                _("%(version)s published and made current; %(count)d project(s) switched.")
                % {"version": version, "count": len(projects)},
            )
            return HttpResponseRedirect(reverse("admin:catalogues_taxonlistversion_changelist"))
        context = {
            **self.admin_site.each_context(request),
            "title": _("Publish new release"),
            "opts": self.model._meta,
            "form": form,
        }
        return TemplateResponse(request, "admin/catalogues/publish_list_version.html", context)


@admin.register(Taxon)
class TaxonAdmin(CatalogueAdminMixin, HistoryAdmin, SyncableAdmin):
    resource_classes = [TaxonResource]
    list_display = [
        "scientific_name",
        "vernacular_name_sr",
        "vernacular_name_en",
        "rank",
        "family",
        "introduced_in",
        "retired_in",
        "active",
        "photo_required",
    ]
    list_filter = [
        "rank",
        "family",
        "active",
        "photo_required",
        "taxon_source",
        RetiredFilter,
        "introduced_in",
    ]
    list_editable = ["active", "photo_required"]
    # The CSV export reads these three columns for every row.
    list_select_related = ["introduced_in", "retired_in", "accepted_name"]
    search_fields = ["scientific_name", "vernacular_name_sr", "vernacular_name_en"]
    autocomplete_fields = ["accepted_name"]
    # Soft delete and restore are list actions, so the field is not edited on the form.
    exclude = ["deleted_at"]
    # A name never changes after creation: rename through the action, which adds a new row.
    readonly_fields_after_create = ["scientific_name"]
    actions = [*SyncableAdmin.actions, "replace_taxon", "synonymise_into_existing"]

    def get_readonly_fields(self, request, obj=None):
        fields = list(super().get_readonly_fields(request, obj))
        if obj is not None:
            fields += [f for f in self.readonly_fields_after_create if f not in fields]
        return fields

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)

    @admin.action(description=_("Rename / synonymise…"), permissions=["change"])
    def replace_taxon(self, request, queryset):
        if queryset.count() != 1:
            self.message_user(request, _("Select exactly one taxon."), messages.ERROR)
            return None
        old = queryset.get()
        form = ReplaceTaxonForm(request.POST if "apply" in request.POST else None)
        # The changelist posts the action; the confirm page posts back with "apply".
        if "apply" in request.POST and form.is_valid():
            try:
                new = retire_and_replace_taxon(
                    old,
                    form.cleaned_data["new_scientific_name"],
                    form.cleaned_data["new_version"],
                    request.user,
                    form.cleaned_data["reason"],
                )
            except TaxonError as exc:
                form.add_error(None, str(exc))
            else:
                self.message_user(
                    request,
                    _("%(old)s retired; %(new)s added.") % {"old": old, "new": new},
                )
                return None
        context = {
            **self.admin_site.each_context(request),
            "title": _("Rename / synonymise taxon"),
            "opts": self.model._meta,
            "taxon": old,
            "form": form,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/catalogues/replace_taxon.html", context)

    @admin.action(description=_("Synonymise into existing…"), permissions=["change"])
    def synonymise_into_existing(self, request, queryset):
        taxa = list(queryset.order_by("scientific_name"))
        form = SynonymiseTaxonForm(request.POST if "apply" in request.POST else None)
        # The changelist posts the action; the confirm page posts back with "apply".
        if "apply" in request.POST and form.is_valid():
            accepted = form.cleaned_data["accepted"]
            version = form.cleaned_data["new_version"]
            reason = form.cleaned_data["reason"]
            try:
                with transaction.atomic():
                    for taxon in taxa:
                        synonymise_taxon(taxon, accepted, version, request.user, reason)
            except TaxonError as exc:
                form.add_error(None, str(exc))
            else:
                self.message_user(
                    request,
                    _("%(count)d taxon/taxa retired as synonyms of %(accepted)s.")
                    % {"count": len(taxa), "accepted": accepted},
                )
                return None
        context = {
            **self.admin_site.each_context(request),
            "title": _("Synonymise into existing taxon"),
            "opts": self.model._meta,
            "taxa": taxa,
            "form": form,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/catalogues/synonymise_taxon.html", context)


@admin.register(PlantTaxon)
class PlantTaxonAdmin(CatalogueAdminMixin, HistoryAdmin, SyncableAdmin):
    resource_classes = [PlantTaxonResource]
    list_display = ["scientific_name", "vernacular_name", "vernacular_name_en", "family", "active"]
    list_filter = ["active", "family", "taxon_source"]
    list_editable = ["active"]
    search_fields = ["scientific_name", "vernacular_name", "vernacular_name_en"]
    # Soft delete and restore are list actions, so the field is not edited on the form.
    exclude = ["deleted_at"]

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)


class CodelistAdmin(CatalogueAdminMixin, HistoryAdmin, SyncableAdmin):
    list_display = ["name_en", "name_sr", "code", "sort_order", "active"]
    list_filter = ["active"]
    list_editable = ["sort_order", "active"]
    search_fields = ["code", "name_en", "name_sr"]
    exclude = ["deleted_at"]

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(HabitatType)
class HabitatTypeAdmin(CodelistAdmin):
    resource_classes = [HabitatTypeResource]
    list_display = [*CodelistAdmin.list_display, "eunis_code"]


@admin.register(ManagementType)
class ManagementTypeAdmin(CodelistAdmin):
    resource_classes = [ManagementTypeResource]
