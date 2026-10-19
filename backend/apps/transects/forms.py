from django import forms
from django.utils.translation import gettext_lazy as _

from apps.transects.services import MAX_GENERATED_SECTIONS


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
