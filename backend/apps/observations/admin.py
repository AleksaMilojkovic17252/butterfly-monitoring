from django import forms
from django.contrib import admin, messages
from django.core.validators import MinValueValidator
from django.db import transaction
from django.template.response import TemplateResponse
from django.urls import reverse
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException, ValidationError

from apps.core.admin import (
    _RULE_ID,
    HistoryAdmin,
    MapAdmin,
    SyncableAdmin,
    add_validation_errors,
)
from apps.exports.admin_actions import ExportActionsMixin
from apps.observations import services
from apps.observations.models import (
    Behaviour,
    ButterflyObservation,
    Photo,
    UploadStatus,
)
from apps.projects.services import projects_for
from apps.surveys.state import VisitLocked
from apps.validation.filters import FlagFilter
from apps.validation.inlines import ValidationEventInline
from apps.validation.models import Decision
from apps.validation.services import DECIDED_STATUSES, decide, recompute_observation


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


def _refusal_text(observation, error):
    """What the action says when it refused `observation`: a rule ID becomes its sentence."""
    if not isinstance(error.detail, dict):
        return str(error.detail)
    sentences = []
    for field, messages_ in error.detail.items():
        if isinstance(messages_, str):  # DRF keeps a lone string as it is
            messages_ = [messages_]
        for message in messages_:
            if _RULE_ID.match(str(message)):
                message = _explain_rule(observation, field, str(message))[1]
            sentences.append(str(message))
    return " ".join(sentences)


class SendBackForm(forms.Form):
    comment = forms.CharField(
        label=_("Comment"),
        widget=forms.Textarea(attrs={"rows": 3}),
        help_text=_("Why the record goes back to the queue. It is kept in the validation history."),
    )


class ButterflyObservationAdminForm(forms.ModelForm):
    """Runs the service's checks for an admin add (`services.check_admin_add`) or edit
    (`services.check_admin_edit`), so a locked visit, or a section, taxon or recorder that does
    not fit, shows as a form error. They run in `_post_clean`: `clean()` comes before the form's
    values are put on the instance, so it would check the old ones (D-106, D-108)."""

    behaviour = forms.TypedMultipleChoiceField(
        choices=Behaviour.choices, widget=forms.CheckboxSelectMultiple, required=False
    )
    clear_zero_flag = forms.BooleanField(
        label=_("Clear the visit's zero-observation flag"),
        required=False,
        help_text=_(
            "Needed when the visit is confirmed as having no butterflies: ticking it clears "
            "that confirmation."
        ),
    )
    admin_user = None  # set by ButterflyObservationAdmin.get_form

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.adding = self.instance._state.adding
        if "count" in self.fields:  # V01 on the field, not as a table constraint message
            self.fields["count"].validators.append(
                MinValueValidator(1, _("The count must be at least 1."))
            )
        if self.adding:
            self.fields["survey_visit"].required = True
            self.fields["recorded_by"].required = False
            self.fields["recorded_by"].help_text = _("Leave empty: the visit's researcher.")

    def _post_clean(self):
        super()._post_clean()
        if self.errors:
            return  # the instance may be incomplete; the field errors are shown first
        explain = lambda field, rule_id: _explain_rule(self.instance, field, rule_id)  # noqa: E731
        try:
            if self.adding:
                services.check_admin_add(
                    self.admin_user,
                    self.instance,
                    clear_zero_flag=self.cleaned_data.get("clear_zero_flag", False),
                )
            else:
                services.check_admin_edit(self.admin_user, self.instance, self.changed_data)
        except VisitLocked as error:
            self.add_error("survey_visit" if self.adding else None, str(error.detail))
        except ValidationError as error:
            add_validation_errors(self, error, explain)
        except APIException as error:
            self.add_error(None, str(error.detail))


def _thumbnail_link(photo, max_width=400):
    """The thumbnail of an uploaded photo, linking to the original. Both load through the API
    views, which accept the admin's session login."""
    if photo.upload_status != UploadStatus.UPLOADED:
        return "-"
    return format_html(
        '<a href="{}"><img src="{}" class="photo-thumbnail" style="max-width:{}px"></a>',
        reverse("photo-content", args=[photo.pk]),
        reverse("photo-thumbnail", args=[photo.pk]),
        max_width,
    )


class PhotoInlineForm(forms.ModelForm):
    """A row of an existing photo: two ticks, applied by `PhotoInlinesMixin.save_formset`. The
    row itself is never saved by the formset."""

    make_primary = forms.BooleanField(label=_("Make primary"), required=False)
    remove = forms.BooleanField(label=_("Soft delete"), required=False)

    class Meta:
        model = Photo
        fields = []

    def _post_clean(self):
        pass


class PhotoInlineFormSet(forms.BaseInlineFormSet):
    photo_rows = "existing"

    def clean(self):
        super().clean()
        if any(self.errors):
            return
        ticked = [f for f in self.forms if f.cleaned_data.get("make_primary")]
        if len(ticked) > 1:
            raise forms.ValidationError(_("Make only one photo primary."))
        if any(f.cleaned_data.get("remove") for f in ticked):
            raise forms.ValidationError(_("A photo cannot be made primary and deleted at once."))


class PhotoInline(admin.TabularInline):
    """The live photos of an observation or a plant record. Editable (make primary, soft delete)
    unless the parent is deleted or its visit locked (T113, D-108)."""

    model = Photo
    form = PhotoInlineForm
    formset = PhotoInlineFormSet
    readonly_fields = ["preview", "upload_status", "captured_at", "is_primary"]
    extra = 0
    can_delete = False

    def get_fields(self, request, obj=None):
        if obj is None or services.photo_parent_read_only(obj):
            return list(self.readonly_fields)
        return [*self.readonly_fields, "make_primary", "remove"]

    def get_queryset(self, request):
        return super().get_queryset(request).filter(deleted_at__isnull=True).order_by("created_at")

    @admin.display(description=_("Photo"))
    def preview(self, photo):
        return _thumbnail_link(photo)

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return obj is not None and not services.photo_parent_read_only(obj)

    def has_delete_permission(self, request, obj=None):
        return False


class PhotoAddForm(forms.ModelForm):
    """A row that adds a photo: the file is checked and stored in `clean()` through
    `services.admin_store_photo_file`; the row is saved by `PhotoInlinesMixin.save_formset`."""

    upload = forms.FileField(
        label=_("File"),
        required=False,
        # Only filters the browser's file dialog; the bytes are checked by the service.
        widget=forms.ClearableFileInput(attrs={"accept": "image/jpeg,image/png"}),
    )
    is_primary = forms.BooleanField(label=_("Make primary"), required=False)

    class Meta:
        model = Photo
        fields = ["captured_at"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.stored = None
        self.fields["captured_at"].required = False

    def clean(self):
        cleaned_data = super().clean()
        upload = cleaned_data.get("upload")
        if upload is None:
            if cleaned_data.get("captured_at") or cleaned_data.get("is_primary"):
                self.add_error("upload", _("Choose a file, or clear the other fields of this row."))
            return cleaned_data
        try:
            self.stored = services.admin_store_photo_file(upload)
        except ValidationError as error:
            detail = error.detail.get("upload") if isinstance(error.detail, dict) else error.detail
            self.add_error("upload", " ".join(str(d) for d in detail))
        except APIException as error:
            self.add_error("upload", str(error.detail))
        return cleaned_data

    def _post_clean(self):
        pass  # the model's constraints would check an instance that has no parent yet


class PhotoAddFormSet(forms.BaseInlineFormSet):
    photo_rows = "add"


class PhotoAddInline(admin.TabularInline):
    """Rows to add photos to an observation or a plant record (T113, D-108)."""

    model = Photo
    form = PhotoAddForm
    formset = PhotoAddFormSet
    verbose_name_plural = _("Add photos")
    fields = ["upload", "captured_at", "is_primary"]
    extra = 1
    can_delete = False
    # The proxy's limit is 20 MB per request, and a photo may be 15 MB.
    help_text = _("At most 15 MB per photo, JPEG or PNG. Add large photos one at a time.")

    def get_queryset(self, request):
        return super().get_queryset(request).none()

    def get_formset(self, request, obj=None, **kwargs):
        formset = super().get_formset(request, obj, **kwargs)
        formset.help_text = self.help_text
        return formset

    def has_add_permission(self, request, obj=None):
        return obj is None or not services.photo_parent_read_only(obj)

    def has_view_permission(self, request, obj=None):
        # No empty "Add photos" block on a read-only page.
        return obj is None or not services.photo_parent_read_only(obj)

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


class PhotoInlinesMixin:
    """Applies the photo inlines' rows through the photo services. List `PhotoInline` before
    `PhotoAddInline`: removals then run before adds, so "first photo is primary" counts right."""

    def save_formset(self, request, form, formset, change):
        rows = getattr(formset, "photo_rows", None)
        if rows is None:
            return super().save_formset(request, form, formset, change)
        # Django's change message reads these; the formset's own save() is never called.
        formset.new_objects, formset.changed_objects, formset.deleted_objects = [], [], []
        if rows == "existing":
            for inline_form in formset.forms:
                if not inline_form.has_changed() or not inline_form.instance.pk:
                    continue
                if inline_form.cleaned_data.get("remove"):
                    services.admin_soft_delete_photo(inline_form.instance, request.user)
                    formset.deleted_objects.append(inline_form.instance)
                elif inline_form.cleaned_data.get("make_primary"):
                    services.admin_make_primary_photo(inline_form.instance, request.user)
                    formset.changed_objects.append((inline_form.instance, ["is_primary"]))
            return None
        for inline_form in formset.forms:
            if inline_form.stored is None:
                continue
            photo = services.admin_add_photo(
                formset.instance,
                request.user,
                inline_form.stored,
                captured_at=inline_form.cleaned_data.get("captured_at"),
                make_primary=inline_form.cleaned_data.get("is_primary", False),
            )
            formset.new_objects.append(photo)
        return None


@admin.register(Photo)
class PhotoAdmin(HistoryAdmin, SyncableAdmin):
    """Photos are recorded on the phone and uploaded through the API, so this page only shows
    them (T049): the thumbnail opens the original."""

    list_display = [
        "preview",
        "observation",
        "plant_resource",
        "upload_status",
        "mime_type",
        "file_size",
        "captured_at",
        "uploaded_at",
        "is_primary",
    ]
    list_filter = ["upload_status", "mime_type"]
    list_select_related = ["observation__taxon", "plant_resource__plant_taxon"]
    ordering = ["-captured_at"]

    def get_fields(self, request, obj=None):
        # Model order; the preview comes first, and the sha256 and key are shown as text.
        return ["preview", *[field.name for field in Photo._meta.fields]]

    def get_readonly_fields(self, request, obj=None):
        return [*self.get_fields(request, obj)]

    @admin.display(description=_("Photo"))
    def preview(self, photo):
        return _thumbnail_link(photo)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def get_actions(self, request):
        return {}


@admin.register(ButterflyObservation)
class ButterflyObservationAdmin(
    PhotoInlinesMixin, ExportActionsMixin, HistoryAdmin, SyncableAdmin, MapAdmin
):
    """Observations are recorded on the phone. An admin may correct one of an unlocked visit
    (saved through `services.admin_save_observation`, T044). The validation fields are read-only
    here: decisions go through the validation queue (T057), and **Send back to queue** undoes
    one. An observation of a locked visit opens read-only (T042)."""

    form = ButterflyObservationAdminForm
    inlines = [PhotoInline, PhotoAddInline, ValidationEventInline]
    # Never edited in the admin: the project and visit cannot change (T044), the validation fields
    # change only through the validation queue (T057) and the flags are the server's (T056).
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
    list_filter = [
        "project",
        "validation_status",
        "source",
        "identification_confidence",
        FlagFilter,
    ]
    search_fields = ["taxon__scientific_name", "recorded_by__email", "notes"]
    ordering = ["-observed_at"]
    list_select_related = ["taxon", "project", "survey_visit__transect", "recorded_by"]
    raw_id_fields = [
        "survey_visit",
        "taxon",
        "transect_section",
        "host_plant_record",
        "nectar_plant_record",
    ]
    add_fields = [
        "survey_visit",
        "recorded_by",
        "taxon",
        "count",
        "observed_at",
        "geometry",
        "transect_section",
        "clear_zero_flag",
        "identification_confidence",
        "sex",
        "life_stage",
        "behaviour",
        "microhabitat",
        "flight_direction_deg",
        "location_accuracy_m",
        "notes",
        "host_plant_record",
        "nectar_plant_record",
    ]
    export_dataset = "butterfly_observations"
    actions = [
        *SyncableAdmin.actions,
        *ExportActionsMixin.export_actions,
        "reassign_sections",
        "send_back_to_queue",
        "recompute_flags",
    ]

    def get_fields(self, request, obj=None):
        if obj is None:
            return list(self.add_fields)
        # Model order, editable or not; photo_count is computed, so it is added by name.
        return [field.name for field in ButterflyObservation._meta.fields] + ["photo_count"]

    def get_readonly_fields(self, request, obj=None):
        if obj is None:  # the add page: only the bookkeeping fields are fixed
            return super().get_readonly_fields(request, obj)
        return [*super().get_readonly_fields(request, obj), *self.fixed_fields]

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        form.admin_user = request.user
        return form

    def save_model(self, request, obj, form, change):
        if change:
            services.admin_save_observation(
                obj, request.user, self.get_change_reason(request), form.changed_data
            )
        else:  # the reason dialog is only on the change page: an add is always "admin add"
            services.admin_add_observation(
                obj,
                request.user,
                clear_zero_flag=form.cleaned_data.get("clear_zero_flag", False),
            )

    @admin.display(description=_("Photos"))
    def photo_count(self, observation):
        return services.photo_count(observation)

    @admin.action(description=_("Reassign sections"), permissions=["change"])
    def reassign_sections(self, request, queryset):
        """Recompute each selected observation's section from its position (T048). Each one is
        saved on its own, so history applies and a refused one is named, not fatal to the rest."""
        changed = unchanged = skipped = 0
        refused = []
        for observation_id in list(
            queryset.filter(deleted_at__isnull=True).values_list("pk", flat=True)
        ):
            try:
                with transaction.atomic():
                    # Load it again, locked: a push may have changed it since the list was shown.
                    observation = (
                        ButterflyObservation.objects.alive()
                        .select_for_update()
                        .filter(pk=observation_id)
                        .first()
                    )
                    if observation is None:
                        continue  # deleted in the meantime
                    if observation.survey_visit_id is None:
                        skipped += 1
                        continue
                    if services.reassign_section(observation, request.user):
                        changed += 1
                    else:
                        unchanged += 1
            except APIException as error:
                refused.append(f"{observation} ({_refusal_text(observation, error)})")
        self.message_user(
            request,
            _("Reassigned %(changed)d, unchanged %(unchanged)d, without a visit %(skipped)d.")
            % {"changed": changed, "unchanged": unchanged, "skipped": skipped},
        )
        if refused:
            self.message_user(
                request,
                _("Not changed: %(observations)s") % {"observations": "; ".join(refused)},
                messages.ERROR,
            )

    @admin.action(description=_("Recompute flags"), permissions=["change"])
    def recompute_flags(self, request, queryset):
        """Work the quality flags out again for the selected observations (T056, D-093). Each one
        is saved on its own, and only when its flags change; one of a locked visit is skipped."""
        ids = list(
            queryset.filter(
                deleted_at__isnull=True, project__in=projects_for(request.user)
            ).values_list("pk", flat=True)
        )
        counts = {"changed": 0, "unchanged": 0, "locked": 0}
        for observation_id in ids:
            outcome = recompute_observation(observation_id, request.user)
            if outcome is not None:
                counts[outcome] += 1
        self.message_user(
            request,
            _(
                "Flags recomputed: %(changed)d changed, %(unchanged)d unchanged, "
                "%(locked)d skipped (locked visit)."
            )
            % counts,
        )

    @admin.action(description=_("Send back to queue…"), permissions=["change"])
    def send_back_to_queue(self, request, queryset):
        """Put decided observations back to `pending` with a required comment (T057, D-091). The
        validated fields are cleared and a `reset` event is written; undecided ones are skipped.
        Each runs on its own, so a refused one (a locked visit) is named, not fatal to the rest."""
        observations = list(
            queryset.filter(
                deleted_at__isnull=True, project__in=projects_for(request.user)
            ).select_related("taxon", "project")
        )
        if not observations:
            self.message_user(request, _("Select at least one observation."), messages.ERROR)
            return None
        form = SendBackForm(request.POST if "apply" in request.POST else None)
        if "apply" in request.POST and form.is_valid():
            sent = skipped = 0
            refused = []
            for observation in observations:
                if observation.validation_status not in DECIDED_STATUSES:
                    skipped += 1
                    continue
                try:
                    decide(
                        observation.pk,
                        Decision.RESET,
                        request.user,
                        comment=form.cleaned_data["comment"],
                    )
                except APIException as error:
                    refused.append(f"{observation} ({_refusal_text(observation, error)})")
                    continue
                sent += 1
            self.message_user(
                request,
                _("Sent back %(sent)d, skipped %(skipped)d (not decided).")
                % {"sent": sent, "skipped": skipped},
            )
            if refused:
                self.message_user(
                    request,
                    _("Not changed: %(observations)s") % {"observations": "; ".join(refused)},
                    messages.ERROR,
                )
            return None
        context = {
            **self.admin_site.each_context(request),
            "title": _("Send back to the validation queue"),
            "opts": self.model._meta,
            "observations": observations,
            "decided_statuses": DECIDED_STATUSES,
            "form": form,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/validation/send_back.html", context)

    def has_change_permission(self, request, obj=None):
        # An observation of a locked visit opens read-only until T043's Unlock action (T042).
        if obj is not None and services.is_locked(obj):
            return False
        return super().has_change_permission(request, obj)
