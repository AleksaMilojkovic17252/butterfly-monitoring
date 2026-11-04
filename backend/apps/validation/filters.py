from django.contrib import admin
from django.utils.translation import gettext_lazy as _

from apps.validation.flags import OBSERVATION_FLAGS


class FlagFilter(admin.SimpleListFilter):
    """Observations with one quality flag (T056). The title stays "flag": Django shows it as
    "By flag"."""

    title = _("flag")
    parameter_name = "flag"

    def lookups(self, request, model_admin):
        return list(OBSERVATION_FLAGS.items())

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(quality_flags__contains=[self.value()])
        return queryset
