"""The station's transect links are not a synced table, so a change re-saves the station: it gets a
new `server_version` and the phone pulls the new list (T078).
"""

from django.db.models.signals import m2m_changed
from django.dispatch import receiver

from apps.environment.models import SensorStationLink


def _bump(station):
    # An instance save, never QuerySet.update(), so the sync trigger and history both run.
    station.save(update_fields=["updated_at"])


@receiver(m2m_changed, sender=SensorStationLink.transects.through)
def bump_station_on_transect_change(sender, instance, action, reverse, pk_set, **kwargs):
    if action == "pre_clear" and reverse:
        # `instance` is a transect; after the clear its stations can no longer be found.
        instance._cleared_stations = list(instance.sensor_stations.all())
    elif action in ("post_add", "post_remove") and pk_set:
        stations = SensorStationLink.objects.filter(pk__in=pk_set) if reverse else [instance]
        for station in stations:
            _bump(station)
    elif action == "post_clear":
        for station in getattr(instance, "_cleared_stations", []) if reverse else [instance]:
            _bump(station)
