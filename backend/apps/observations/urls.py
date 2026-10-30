from django.urls import path

from apps.observations import views

urlpatterns = [
    path("observations", views.ButterflyObservationCreate.as_view(), name="observation-create"),
    path(
        "observations/<uuid:observation_id>",
        views.ButterflyObservationDetail.as_view(),
        name="observation-detail",
    ),
    path("attachments/init", views.PhotoUploadInit.as_view(), name="photo-upload-init"),
    path(
        "attachments/<uuid:photo_id>/content",
        views.PhotoUploadContent.as_view(),
        name="photo-upload-content",
    ),
    path(
        "attachments/<uuid:photo_id>/complete",
        views.PhotoUploadComplete.as_view(),
        name="photo-upload-complete",
    ),
    path("photos/<uuid:photo_id>/content", views.PhotoContent.as_view(), name="photo-content"),
    path(
        "photos/<uuid:photo_id>/thumbnail", views.PhotoThumbnail.as_view(), name="photo-thumbnail"
    ),
]
