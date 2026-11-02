from rest_framework import exceptions
from rest_framework.authentication import BasicAuthentication

from apps.accounts import services

SCOPE = "ogc"


class OgcBasicAuthentication(BasicAuthentication):
    """Basic auth for desktop tools, with its own failed-login counter (T011, D-080).

    A locked email answers 401, not 429: auth_request turns any status but 2xx/401/403 into a 500.
    """

    www_authenticate_realm = "ogc"

    def authenticate_credentials(self, userid, password, request=None):
        if services.is_locked(userid, SCOPE):
            raise exceptions.AuthenticationFailed(
                "Too many failed logins. Try again in 15 minutes."
            )
        try:
            result = super().authenticate_credentials(userid, password, request)
        except exceptions.AuthenticationFailed:
            services.record_failure(userid, SCOPE)
            raise
        services.reset_failures(userid, SCOPE)
        return result
