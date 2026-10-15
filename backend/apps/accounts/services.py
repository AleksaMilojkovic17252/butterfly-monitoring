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
