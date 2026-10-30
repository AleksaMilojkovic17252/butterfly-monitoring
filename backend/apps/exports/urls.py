from django.urls import path

from apps.exports import views

urlpatterns = [
    # `bundle` must come first, or <dataset> would take it.
    path("exports/bundle", views.ExportBundleView.as_view(), name="export-bundle"),
    path("exports/<str:dataset>", views.ExportDatasetView.as_view(), name="export-dataset"),
]
