import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class SyncableQuerySet(models.QuerySet):
    def alive(self):
        return self.filter(deleted_at__isnull=True)

    def changed_since(self, cursor: int):
        return self.filter(server_version__gt=cursor).order_by("server_version")

    def delete(self):
        raise NotImplementedError("Synced rows are never hard-deleted; use soft_delete().")

    delete.queryset_only = True


class SyncableModel(models.Model):
    """Base for every synced table. Pair it with AttachSyncTrigger(table) in the migration."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # Set by the DB trigger bump_server_version(); the value on the instance is stale after
    # save(). Call refresh_from_db(fields=["server_version"]) when the new value is needed.
    server_version = models.BigIntegerField(default=0, editable=False, db_index=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
    )
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
    )

    objects = SyncableQuerySet.as_manager()

    class Meta:
        abstract = True

    def delete(self, *args, **kwargs):
        raise NotImplementedError("Synced rows are never hard-deleted; use soft_delete().")

    def soft_delete(self, user=None):
        self.deleted_at = timezone.now()
        self.updated_by = user
        self.save(update_fields=["deleted_at", "updated_by", "updated_at"])
