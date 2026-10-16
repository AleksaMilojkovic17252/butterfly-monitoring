from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from apps.accounts.permissions import IsAdminGroup
from apps.accounts.serializers import LoginSerializer, UserSerializer


class LoginView(TokenObtainPairView):
    serializer_class = LoginSerializer


class RefreshView(TokenRefreshView):
    pass


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class LogoutView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    @extend_schema(request=LogoutSerializer, responses={205: None})
    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            RefreshToken(serializer.validated_data["refresh"]).blacklist()
        except TokenError as exc:
            raise serializers.ValidationError({"refresh": str(exc)}) from exc
        return Response(status=status.HTTP_205_RESET_CONTENT)


class MeView(APIView):
    @extend_schema(responses=UserSerializer)
    def get(self, request):
        return Response(UserSerializer(request.user).data)


class AdminCheckView(APIView):
    """200 for admins, 403 for researchers. Stand-in for the admin-only endpoints (T064, T069)."""

    permission_classes = [IsAdminGroup]

    @extend_schema(responses={200: None})
    def get(self, request):
        return Response({"admin": True})
