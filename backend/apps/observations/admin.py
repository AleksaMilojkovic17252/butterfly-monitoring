from django import forms
from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException, ValidationError

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin, add_validation_errors
from apps.observations import services
from apps.observations.models import Behaviour, ButterflyObservation
from apps.surveys.state import VisitLocked


def _explain_rule(observation, field, rule_id):
    """The form field to mark and the sentence for an observation rule that refused an edit."""
    label = str(ButterflyObservation._meta.get_field(field).verbose_name).capitalize()
    visit = observation.survey_visit if observation.survey_visit_id else None
    status = visit.get_status_display().lower() if visit else "missing"
    texts = {
        "V01": _("The count must be at least 1."),
        "V02": _("{label} is required.").format(label=label),
        "V03": _(
            "A butterfly record can only be on a visit that is in progress, finished, or "
            "cancelled after it was started. This visit is {status}."
        ).format(status=status),
        "V04": _(
            "The observation time is outside the time of its visit (from start to end, "
            "plus the protocol's tolerance)."
        ),
        "V06": _(
            "This visit is confirmed as having no butterflies, so it cannot have butterfly "
            "records. Untick 'Zero observation confirmed' on the visit first."
        ),
        "V08": _(
            "The position is not a valid point. Longitude must be between -180 and 180 and "
            "latitude between -90 and 90."
        ),
    }
    default = _("'{label}' is not one of the allowed choices.").format(label=label)
    return field, texts.get(rule_id, default)


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
            add_validation_errors(
                self, error, lambda field, rule_id: _explain_rule(self.instance, field, rule_id)
            )
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
