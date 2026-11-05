from django import forms
from django.utils.translation import gettext_lazy as _

from apps.transects.services import (
    MAX_GENERATED_SECTIONS,
    MIN_REJECT_NOTE_LENGTH,
    transect_code_taken,
)


class LineImportForm(forms.Form):
    file = forms.FileField(label=_("GPX, KML or GeoJSON file"))


class GenerateSectionsForm(forms.Form):
    parts = forms.IntegerField(
        label=_("Number of sections"),
        min_value=1,
        max_value=MAX_GENERATED_SECTIONS,
        help_text=_("The line is cut into this many sections of equal length."),
    )
    prefix = forms.CharField(
        label=_("Code prefix"),
        max_length=15,
        initial="S",
        help_text=_("Section codes are the prefix plus the number: S1, S2, ..."),
    )
    replace = forms.BooleanField(
        label=_("Replace existing sections"),
        required=False,
        help_text=_("Soft-deletes the sections this transect has now. Needed when it has any."),
    )


class CreateTransectFromProposalForm(forms.Form):
    """The admin's choices when a route proposal becomes a transect (T108)."""

    code = forms.CharField(
        label=_("Transect code"),
        max_length=20,
        strip=True,
        help_text=_("Unique in the project. A deleted transect keeps its code."),
    )
    name = forms.CharField(label=_("Transect name"), max_length=200, strip=True)
    deactivate_replaced = forms.BooleanField(
        label=_("Deactivate the replaced transect"),
        required=False,
        initial=True,
        help_text=_("Its line stays as it is, so its past visits keep their route."),
    )

    def __init__(self, *args, proposal, **kwargs):
        super().__init__(*args, **kwargs)
        self.proposal = proposal
        self.fields["name"].initial = proposal.name
        if proposal.replaces_transect_id is None:
            del self.fields["deactivate_replaced"]

    def clean_code(self):
        code = self.cleaned_data["code"]
        if transect_code_taken(self.proposal.project_id, code):
            raise forms.ValidationError(
                _("The project already has a transect with this code (deleted ones count).")
            )
        return code


class RejectProposalForm(forms.Form):
    note = forms.CharField(
        label=_("Reason"),
        widget=forms.Textarea(attrs={"rows": 4}),
        min_length=MIN_REJECT_NOTE_LENGTH,
        strip=True,
        help_text=_("Shown to the researcher on the phone. At least %(n)d characters.")
        % {"n": MIN_REJECT_NOTE_LENGTH},
    )
