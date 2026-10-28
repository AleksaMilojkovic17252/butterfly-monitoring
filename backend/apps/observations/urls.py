from django.urls import path

from apps.observations import views

urlpatterns = [
    path("observations", views.ButterflyObservationCreate.as_view(), name="observation-create"),
    path(
        "observations/<uuid:observation_id>",
        views.ButterflyObservationDetail.as_view(),
        name="observation-detail",
    ),
]
