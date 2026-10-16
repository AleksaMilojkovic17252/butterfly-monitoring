"""Failed-login throttling: 5 failures per email in 15 minutes (T011)."""

from django.conf import settings
from django.core.cache import cache


def _key(email):
    return f"login-failures:{email.strip().lower()}"


def is_locked(email):
    return cache.get(_key(email), 0) >= settings.LOGIN_MAX_FAILURES


def record_failure(email):
    key = _key(email)
    cache.add(key, 0, settings.LOGIN_FAILURE_WINDOW)
    try:
        cache.incr(key)
    except ValueError:
        cache.set(key, 1, settings.LOGIN_FAILURE_WINDOW)


def reset_failures(email):
    cache.delete(_key(email))


ADMIN_GROUP = "admin"
RESEARCHER_GROUP = "researcher"


def sync_admin_group_permissions():
    """Grant the `admin` group every permission of this project's apps (T013).

    Run from `post_migrate`, so models added by later migrations are picked up.
    """
    from django.apps import apps
    from django.contrib.auth.models import Group, Permission

    labels = [c.label for c in apps.get_app_configs() if c.name.startswith("apps.")]
    group, _ = Group.objects.get_or_create(name=ADMIN_GROUP)
    group.permissions.set(Permission.objects.filter(content_type__app_label__in=labels))


def is_admin(user):
    """True for users in the `admin` group (superusers too)."""
    if not user or not user.is_authenticated:
        return False
    return user.is_superuser or user.groups.filter(name=ADMIN_GROUP).exists()
