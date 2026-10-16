from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from apps.accounts.models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    """Admins create accounts here (D-033). Also provides the user autocomplete for memberships."""

    ordering = ["email"]
    list_display = ["email", "name", "organization", "is_active", "is_staff"]
    search_fields = ["email", "name"]
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Profile", {"fields": ("name", "organization")}),
        ("Permissions", {"fields": ("is_active", "is_superuser", "groups")}),
        ("Dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("email", "name", "password1", "password2")}),
    )
    readonly_fields = ["last_login", "date_joined"]
    filter_horizontal = ["groups"]
