from django.contrib.admin.apps import AdminConfig


class CoreAdminConfig(AdminConfig):
    """Replaces django.contrib.admin so the default site is our branded one (T014)."""

    default_site = "apps.core.admin_site.ButterflyAdminSite"
