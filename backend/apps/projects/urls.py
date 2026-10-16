from rest_framework.routers import SimpleRouter

from apps.projects import views

router = SimpleRouter(trailing_slash=False)
router.register("projects", views.ProjectViewSet, basename="project")

urlpatterns = router.urls
