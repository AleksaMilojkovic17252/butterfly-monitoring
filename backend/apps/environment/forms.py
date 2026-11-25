from django import forms
from django.utils.translation import gettext_lazy as _

from apps.environment import services
from apps.projects.services import projects_for


class CopyStationForm(forms.Form):
    """Where a copy of a station goes (T078)."""

    project = forms.ModelChoiceField(label=_("Copy to project"), queryset=None)
    code = forms.CharField(
        label=_("Code"),
        max_length=20,
        help_text=_("Must not be in use in that project."),
    )

    def __init__(self, *args, station, user, **kwargs):
        super().__init__(*args, initial={"code": station.code}, **kwargs)
        others = projects_for(user).exclude(pk=station.project_id)
        self.fields["project"].queryset = others.order_by("name")

    def clean(self):
        data = super().clean()
        project, code = data.get("project"), data.get("code")
        if project and code and services.station_code_taken(project, code):
            self.add_error(
                "code",
                _("This project already has a station with this code (it may be soft-deleted)."),
            )
        return data
