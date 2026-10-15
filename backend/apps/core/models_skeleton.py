"""T007 walking-skeleton table. Throwaway: deleted in T044."""

from django.contrib.gis.db import models


class SkeletonPing(models.Model):
    id = models.UUIDField(primary_key=True)
    observed_at = models.DateTimeField()
    geometry = models.PointField(srid=4326)
    note = models.CharField(max_length=200, blank=True)
    received_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "skeleton_ping"
