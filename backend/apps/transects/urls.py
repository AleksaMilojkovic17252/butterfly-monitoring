from django.urls import path

from apps.transects import views

urlpatterns = [
    path(
        "projects/<uuid:project_id>/transects",
        views.ProjectTransectList.as_view(),
        name="project-transects",
    ),
    path("transects/<uuid:pk>", views.TransectDetail.as_view(), name="transect-detail"),
]
