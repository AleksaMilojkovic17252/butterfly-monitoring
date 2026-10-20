from django.urls import path

from apps.sync import views

urlpatterns = [
    path("sync/pull", views.pull, name="sync-pull"),
    path("sync/push", views.push, name="sync-push"),
]
