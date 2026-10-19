from django import forms
from django.contrib import admin, messages
from django.db import transaction
from django.template.response import TemplateResponse
from django.utils.translation import gettext_lazy as _

from apps.catalogues.models import Taxon, TaxonListVersion
from apps.catalogues.services import (
    TaxonError,
    clear_other_current,
    retire_and_replace_taxon,
)
from apps.core.admin import HistoryAdmin, SyncableAdmin


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


@admin.register(TaxonListVersion)
class TaxonListVersionAdmin(HistoryAdmin, SyncableAdmin):
    list_display = ["version_label", "source", "published_at", "is_current"]
    list_filter = ["is_current"]
    search_fields = ["version_label", "source"]
    # Soft delete and restore are list actions, so the field is not edited on the form.
    exclude = ["deleted_at"]
    ordering = ["-published_at"]

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        with transaction.atomic():
            if obj.is_current:
                clear_other_current(obj, request.user)
            super().save_model(request, obj, form, change)


@admin.register(Taxon)
class TaxonAdmin(HistoryAdmin, SyncableAdmin):
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
    list_filter = ["rank", "family", "active", "photo_required", RetiredFilter, "introduced_in"]
    search_fields = ["scientific_name", "vernacular_name_sr", "vernacular_name_en"]
    autocomplete_fields = ["accepted_name"]
    # Soft delete and restore are list actions, so the field is not edited on the form.
    exclude = ["deleted_at"]
    # A name never changes after creation: rename through the action, which adds a new row.
    readonly_fields_after_create = ["scientific_name"]
    actions = [*SyncableAdmin.actions, "replace_taxon"]

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
