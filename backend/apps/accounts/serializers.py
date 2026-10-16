from rest_framework import exceptions, serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from apps.accounts import services


class UserSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    email = serializers.EmailField()
    name = serializers.CharField()
    organization = serializers.CharField()
    groups = serializers.SerializerMethodField()
    project_ids = serializers.SerializerMethodField()

    def get_groups(self, user) -> list[str]:
        return sorted(user.groups.values_list("name", flat=True))

    def get_project_ids(self, user) -> list[str]:
        from apps.projects.services import projects_for

        return [str(pk) for pk in projects_for(user).values_list("id", flat=True)]


class LoginSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        email = attrs.get(self.username_field, "")
        if services.is_locked(email):
            raise exceptions.Throttled(detail="Too many failed logins. Try again in 15 minutes.")
        try:
            data = super().validate(attrs)
        except exceptions.AuthenticationFailed:
            services.record_failure(email)
            raise
        services.reset_failures(email)
        data["user"] = UserSerializer(self.user).data
        return data
