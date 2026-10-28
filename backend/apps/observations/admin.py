from django import forms
from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException, ValidationError

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.observations import services
from apps.observations.models import Behaviour, ButterflyObservation
from apps.surveys.state import VisitLocked


class ButterflyObservationAdminForm(forms.ModelForm):
    """Runs the service's checks for an admin edit (`services.check_admin_edit`), so a locked
    visit, or a section, taxon or recorder that does not fit, shows as a form error."""

    behaviour = forms.TypedMultipleChoiceField(
        choices=Behaviour.choices, widget=forms.CheckboxSelectMultiple, required=False
    )
    admin_user = None  # set by ButterflyObservationAdmin.get_form

    def clean(self):
        cleaned_data = super().clean()
        try:
            services.check_admin_edit(self.admin_user, self.instance, self.changed_data)
        except VisitLocked as error:
            raise forms.ValidationError(str(error.detail)) from error
        except ValidationError as error:
            if isinstance(error.detail, dict):
                for field_name, messages_ in error.detail.items():
                    self.add_error(field_name if field_name in self.fields else None, messages_)
            else:
                self.add_error(None, error.detail)
        except APIException as error:
            self.add_error(None, str(error.detail))
        return cleaned_data


@admin.register(ButterflyObservation)
class ButterflyObservationAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    """Observations are recorded on the phone. An admin may correct one of an unlocked visit
    (saved through `services.admin_save_observation`, T044). The validation fields are read-only
    until T057, and an observation of a locked visit opens read-only (T042)."""

    form = ButterflyObservationAdminForm
    # Never edited in the admin: the project and visit cannot change (T044), the validation fields
    # and flags belong to T055-T057.
    fixed_fields = [
        "id",
        "project",
        "survey_visit",
        "validation_status",
        "validated_taxon",
        "validated_by",
        "validated_at",
        "validation_comment",
        "quality_flags",
        "deleted_at",
        "photo_count",
    ]

    list_display = [
        "observed_at",
        "taxon",
        "count",
        "project",
        "survey_visit",
        "recorded_by",
        "validation_status",
        "photo_count",
    ]
    list_filter = ["project", "validation_status", "source", "identification_confidence"]
    search_fields = ["taxon__scientific_name", "recorded_by__email", "notes"]
    ordering = ["-observed_at"]
    list_select_related = ["taxon", "project", "survey_visit__transect", "recorded_by"]
    raw_id_fields = ["taxon", "transect_section"]

    def get_fields(self, request, obj=None):
        # Model order, editable or not; photo_count is computed, so it is added by name.
        return [field.name for field in ButterflyObservation._meta.fields] + ["photo_count"]

    def get_readonly_fields(self, request, obj=None):
        return [*super().get_readonly_fields(request, obj), *self.fixed_fields]

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        form.admin_user = request.user
        return form

    def save_model(self, request, obj, form, change):
        services.admin_save_observation(
            obj, request.user, self.get_change_reason(request), form.changed_data
        )

    @admin.display(description=_("Photos"))
    def photo_count(self, observation):
        return services.photo_count(observation)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        # An observation of a locked visit opens read-only until T043's Unlock action (T042).
        if obj is not None and services.is_locked(obj):
            return False
        return super().has_change_permission(request, obj)
