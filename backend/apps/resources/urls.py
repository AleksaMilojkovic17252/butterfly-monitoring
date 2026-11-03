from django.urls import path

from apps.resources import views

urlpatterns = [
    path("plant-resources", views.PlantResourceCreate.as_view(), name="plant-resource-create"),
    path(
        "plant-resources/<uuid:plant_id>",
        views.PlantResourceDetail.as_view(),
        name="plant-resource-detail",
    ),
    path("habitat-features", views.HabitatFeatureCreate.as_view(), name="habitat-feature-create"),
    path(
        "habitat-features/<uuid:feature_id>",
        views.HabitatFeatureDetail.as_view(),
        name="habitat-feature-detail",
    ),
]
