"""Audit log helpers on top of django-simple-history (T018, D-009)."""

from django.dispatch import receiver
from simple_history.signals import pre_create_historical_record

from apps.core.models import SyncableModel


def save_with_reason(obj, user, reason):
    """Save `obj` and record `reason` and `user` on its history row.

    Use for changes that need a stated reason (lock/unlock T043, validation T057). Works
    outside a request too, since the user is set on the instance, not taken from middleware.
    """
    obj._change_reason = reason
    obj._history_user = user
    if isinstance(obj, SyncableModel):
        obj.updated_by = user
    obj.save()


@receiver(pre_create_historical_record)
def copy_fresh_server_version(sender, instance, history_instance, **kwargs):
    """Store the server_version the trigger just wrote, not the stale value on the instance.

    simple-history builds the history row in post_save, after the row is written, so the
    BEFORE trigger (T005) has already set the new version in the database. T027 reads past
    row states by (id, server_version), so the history row must carry the real value.
    """
    if not isinstance(instance, SyncableModel):
        return
    version = (
        type(instance)
        ._base_manager.filter(pk=instance.pk)
        .values_list("server_version", flat=True)
        .first()
    )
    if version is not None:
        history_instance.server_version = version
