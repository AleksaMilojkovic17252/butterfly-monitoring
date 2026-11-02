"""Failed-login throttling: 5 failures per email in 15 minutes (T011).

`scope` keeps separate counters: the app login uses "login", Basic auth on /ogc (T069) uses "ogc",
so wrong passwords sent to /ogc cannot lock a person out of the app.
"""

from django.conf import settings
from django.core.cache import cache


def _key(email, scope):
    return f"{scope}-failures:{email.strip().lower()}"


def is_locked(email, scope="login"):
    return cache.get(_key(email, scope), 0) >= settings.LOGIN_MAX_FAILURES


def record_failure(email, scope="login"):
    key = _key(email, scope)
    cache.add(key, 0, settings.LOGIN_FAILURE_WINDOW)
    try:
        cache.incr(key)
    except ValueError:
        cache.set(key, 1, settings.LOGIN_FAILURE_WINDOW)


def reset_failures(email, scope="login"):
    cache.delete(_key(email, scope))


ADMIN_GROUP = "admin"
RESEARCHER_GROUP = "researcher"


def sync_admin_group_permissions():
    """Grant the `admin` group every permission of this project's apps (T013) and of the
    personal API tokens (`authtoken`, T069), so non-superuser admins can manage tokens.

    Run from `post_migrate`, so models added by later migrations are picked up.
    """
    from django.apps import apps
    from django.contrib.auth.models import Group, Permission

    labels = [c.label for c in apps.get_app_configs() if c.name.startswith("apps.")]
    labels.append("authtoken")
    group, _ = Group.objects.get_or_create(name=ADMIN_GROUP)
    group.permissions.set(Permission.objects.filter(content_type__app_label__in=labels))


def is_admin(user):
    """True for users in the `admin` group (superusers too)."""
    if not user or not user.is_authenticated:
        return False
    return user.is_superuser or user.groups.filter(name=ADMIN_GROUP).exists()
