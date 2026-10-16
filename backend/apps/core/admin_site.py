from django.contrib.admin import AdminSite

# Sidebar order from T014. Several app labels can share one slot; labels that are not listed
# (third-party apps such as the token blacklist) go last.
APP_ORDER = [
    "projects",
    "transects",
    "surveys",
    "observations",
    "resources",
    "validation",
    "sync",
    "catalogues",
    "accounts",
    "auth",
]


class ButterflyAdminSite(AdminSite):
    site_header = "Butterfly Monitoring"
    site_title = "Butterfly Monitoring"
    index_title = "Administration"

    def get_app_list(self, request, app_label=None):
        app_list = super().get_app_list(request, app_label)
        rank = {label: i for i, label in enumerate(APP_ORDER)}
        return sorted(app_list, key=lambda app: rank.get(app["app_label"], len(APP_ORDER)))
