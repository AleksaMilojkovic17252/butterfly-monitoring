from django.urls import path

from apps.surveys import views

urlpatterns = [
    path("survey-visits", views.SurveyVisitCreate.as_view(), name="survey-visit-create"),
    path(
        "survey-visits/<uuid:visit_id>",
        views.SurveyVisitDetail.as_view(),
        name="survey-visit-detail",
    ),
    path(
        "survey-visits/<uuid:visit_id>/complete",
        views.SurveyVisitComplete.as_view(),
        name="survey-visit-complete",
    ),
    path(
        "transects/<uuid:transect_id>/visits",
        views.TransectVisitList.as_view(),
        name="transect-visits",
    ),
]
