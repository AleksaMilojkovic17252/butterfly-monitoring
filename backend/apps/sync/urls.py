from django.urls import path

from apps.sync import views

urlpatterns = [
    path("sync/pull", views.pull, name="sync-pull"),
    path("sync/push", views.push, name="sync-push"),
    path(
        "projects/<uuid:project_id>/offline-package",
        views.offline_package,
        name="offline-package",
    ),
    path(
        "projects/<uuid:project_id>/offline-package/status",
        views.offline_package_status,
        name="offline-package-status",
    ),
]
