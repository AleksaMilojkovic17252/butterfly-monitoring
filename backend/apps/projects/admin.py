from django.contrib import admin
from simple_history.admin import SimpleHistoryAdmin

from apps.core.admin import SyncableAdmin
from apps.projects.models import Project, ProjectMembership


class ProjectMembershipInline(admin.TabularInline):
    model = ProjectMembership
    extra = 1
    autocomplete_fields = ["user"]
    fields = ["user", "added_by", "created_at"]
    readonly_fields = ["added_by", "created_at"]


@admin.register(Project)
class ProjectAdmin(SimpleHistoryAdmin, SyncableAdmin):
    list_display = ["name", "owner", "start_date", "end_date", "active"]
    list_filter = ["active"]
    search_fields = ["name"]
    autocomplete_fields = ["owner"]
    # Explicit order: the inherited sync fields would otherwise come first.
    fields = [
        "name",
        "description",
        "owner",
        "start_date",
        "end_date",
        "default_crs",
        "active",
        "deleted_at",
        "server_version",
        "created_at",
        "created_by",
        "updated_at",
        "updated_by",
    ]
    inlines = [ProjectMembershipInline]

    def get_changeform_initial_data(self, request):
        return {"owner": request.user.pk}

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)

    def save_formset(self, request, form, formset, change):
        instances = formset.save(commit=False)
        for obj in formset.deleted_objects:
            obj.delete()
        for obj in instances:
            if isinstance(obj, ProjectMembership) and obj.added_by_id is None:
                obj.added_by = request.user
            obj.save()
        formset.save_m2m()
