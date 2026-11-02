from django.urls import path

from apps.accounts import views

urlpatterns = [
    path("login", views.LoginView.as_view(), name="auth-login"),
    path("refresh", views.RefreshView.as_view(), name="auth-refresh"),
    path("logout", views.LogoutView.as_view(), name="auth-logout"),
    path("verify", views.OgcVerifyView.as_view(), name="auth-verify"),
    path("me", views.MeView.as_view(), name="auth-me"),
]
