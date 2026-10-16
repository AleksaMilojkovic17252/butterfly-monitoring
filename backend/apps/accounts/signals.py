from django.contrib.auth import get_user_model
from django.db.models.signals import m2m_changed, post_migrate
from django.dispatch import receiver

from apps.accounts.services import ADMIN_GROUP, sync_admin_group_permissions


@receiver(post_migrate)
def grant_admin_permissions(sender, **kwargs):
    # Fires once per app; only act after the accounts app, whose migration creates the groups.
    if sender.name == "apps.accounts":
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
