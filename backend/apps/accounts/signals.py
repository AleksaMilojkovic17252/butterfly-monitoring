from django.apps import apps
from django.contrib.auth import get_user_model
from django.contrib.auth.management import create_permissions
from django.db import DEFAULT_DB_ALIAS
from django.db.models.signals import m2m_changed, post_migrate
from django.dispatch import receiver

from apps.accounts.services import ADMIN_GROUP, sync_admin_group_permissions


@receiver(post_migrate)
def grant_admin_permissions(sender, **kwargs):
    # Django sends this once per app that has a models module, in INSTALLED_APPS order, and makes
    # each app's permissions in that app's own signal. So act on the last such app, when every
    # app's permissions can exist, including a model added by this migrate.
    # Apps with no models module are skipped (Django sends them no signal), so the last sender is
    # not always the last entry in INSTALLED_APPS: work it out here instead of naming an app.
    with_models = [c for c in apps.get_app_configs() if c.models_module is not None]
    if sender.label != with_models[-1].label:
        return
    # create_permissions is idempotent. Calling it here for every app means the grant does not
    # depend on the order of INSTALLED_APPS or on the order Django's own receivers run in.
    for config in with_models:
        create_permissions(
            config,
            verbosity=0,
            interactive=False,
            using=kwargs.get("using", DEFAULT_DB_ALIAS),
            apps=kwargs.get("apps", apps),
        )
    sync_admin_group_permissions()


def _set_staff(user_ids):
    """is_staff mirrors membership of the admin group. Superusers keep it."""
    User = get_user_model()
    users = User.objects.filter(pk__in=user_ids, is_superuser=False)
    users.filter(groups__name=ADMIN_GROUP).update(is_staff=True)
    users.exclude(groups__name=ADMIN_GROUP).update(is_staff=False)


@receiver(m2m_changed, sender=get_user_model().groups.through)
def sync_is_staff(sender, instance, action, reverse, pk_set, **kwargs):
    if action == "pre_clear" and reverse:
        # After a reverse clear the member ids are gone, so remember them first.
        instance._cleared_user_ids = list(instance.user_set.values_list("pk", flat=True))
    elif action in ("post_add", "post_remove"):
        _set_staff(pk_set if reverse else [instance.pk])
    elif action == "post_clear":
        _set_staff(getattr(instance, "_cleared_user_ids", []) if reverse else [instance.pk])
