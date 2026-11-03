from django.contrib import admin

from apps.validation.models import ValidationEvent


class ValidationEventInline(admin.TabularInline):
    """The validation decisions on an observation, newest first, read-only (T058).

    Events are written only by `validation.services.record_decision`. There is no ModelAdmin;
    T057 adds the Validation section.
    """

    model = ValidationEvent
    fields = [
        "decided_at",
        "decision",
        "previous_status",
        "new_status",
        "previous_taxon",
        "new_taxon",
        "comment",
        "decided_by",
    ]
    readonly_fields = fields
    extra = 0
    can_delete = False

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .select_related("previous_taxon", "new_taxon", "decided_by")
        )

    def has_add_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
