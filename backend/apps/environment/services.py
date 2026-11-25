"""Manual environmental snapshots (T063, D-076), derived from a finished visit's own weather, and
sensor stations (T078): their scopes, input rules and registration in FROST.
"""

from decimal import Decimal

from django.db import connection, transaction
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

from apps.core.history import save_with_reason
from apps.environment import frost
from apps.environment.models import (
    HABITAT_POLYGON_TYPES,
    EnvironmentalSnapshot,
    SensorStationLink,
    SnapshotMoment,
    SourceType,
)
from apps.projects.services import projects_for

# Advisory lock key: one registration in FROST at a time (727274 and 727275 belong to sync).
REGISTER_LOCK_KEY = 727276

# Midpoint in m/s of each Beaufort force's WMO range (force 3: 3.4-5.4 -> 4.4). Force 12 has no
# upper bound ("32.7 and over"), so it takes the lower bound.
BEAUFORT_MIDPOINT_M_S = {
    0: Decimal("0.1"),
    1: Decimal("0.9"),
    2: Decimal("2.45"),
    3: Decimal("4.4"),
    4: Decimal("6.7"),
    5: Decimal("9.35"),
    6: Decimal("12.3"),
    7: Decimal("15.5"),
    8: Decimal("18.95"),
    9: Decimal("22.6"),
    10: Decimal("26.45"),
    11: Decimal("30.55"),
    12: Decimal("32.7"),
}

# The fields a manual snapshot takes from the visit; a change in any of them rewrites the row.
VALUE_FIELDS = [
    "phenomenon_time_start",
    "temperature_c",
    "wind_speed_m_s",
    "cloud_cover_pct",
    "raw_payload_json",
]


def _manual_snapshot(visit, moment, time, temperature, beaufort, cloud):
    """One unsaved snapshot, or None when the time is missing or the weather is all empty."""
    if time is None or (temperature is None and beaufort is None and cloud is None):
        return None
    return EnvironmentalSnapshot(
        survey_visit=visit,
        source_type=SourceType.MANUAL,
        moment=moment,
        phenomenon_time_start=time,
        temperature_c=temperature,
        wind_speed_m_s=None if beaufort is None else BEAUFORT_MIDPOINT_M_S[beaufort],
        cloud_cover_pct=cloud,
        # The visit's precipitation is a category, not millimetres, so it stays in the payload.
        raw_payload_json={"wind_beaufort": beaufort, "precipitation": visit.precipitation},
    )


def refresh_manual_snapshots(visit):
    """Bring the visit's manual start and end snapshots in line with its weather fields.

    A row is created when missing, updated (with a new `retrieved_at`) only when a value
    changed, and deleted when its moment no longer has weather. A save that changes nothing,
    such as Mark as reviewed or a new distance, leaves the rows, their ids and `retrieved_at`
    alone, and there is never more than one row per moment (D-076).
    """
    wanted = {
        snapshot.moment: snapshot
        for snapshot in (
            _manual_snapshot(
                visit,
                SnapshotMoment.START,
                visit.started_at,
                visit.temperature_start_c,
                visit.wind_beaufort_start,
                visit.cloud_cover_start_pct,
            ),
            _manual_snapshot(
                visit,
                SnapshotMoment.END,
                visit.ended_at,
                visit.temperature_end_c,
                visit.wind_beaufort_end,
                visit.cloud_cover_end_pct,
            ),
        )
        if snapshot is not None
    }
    with transaction.atomic():
        existing = {
            snapshot.moment: snapshot
            for snapshot in visit.environmental_snapshots.filter(
                source_type=SourceType.MANUAL, observation__isnull=True
            )
        }
        for moment, snapshot in existing.items():
            new = wanted.get(moment)
            if new is None:
                snapshot.delete()
            elif any(getattr(snapshot, name) != getattr(new, name) for name in VALUE_FIELDS):
                for name in VALUE_FIELDS:
                    setattr(snapshot, name, getattr(new, name))
                snapshot.retrieved_at = timezone.now()
                snapshot.save(update_fields=[*VALUE_FIELDS, "retrieved_at"])
        EnvironmentalSnapshot.objects.bulk_create(
            [snapshot for moment, snapshot in wanted.items() if moment not in existing]
        )


def stations_for(user):
    """Stations in the user's projects (all for admins), deleted ones included, for the admin."""
    return SensorStationLink.objects.filter(project__in=projects_for(user))


def pull_stations(_user, project):
    """The project's stations, deleted rows included, so tombstones reach the phone."""
    return SensorStationLink.objects.filter(project=project).prefetch_related("transects")


def station_link_errors(project, habitat_feature, transects):
    """What is wrong with a station's links, as `{field: message}`; empty when they are fine.

    The habitat polygon and the transects must belong to the station's own project.
    """
    errors = {}
    if habitat_feature is not None:
        if habitat_feature.project_id != project.pk:
            errors["habitat_feature"] = _("This habitat polygon belongs to another project.")
        elif habitat_feature.geometry.geom_type not in HABITAT_POLYGON_TYPES:
            errors["habitat_feature"] = _("Choose a polygon, not a point or a line.")
    foreign = sorted(t.code for t in transects if t.project_id != project.pk)
    if foreign:
        errors["transects"] = _("These transects belong to another project: %(codes)s.") % {
            "codes": ", ".join(foreign)
        }
    return errors


def fill_habitat_type(station):
    """Take the habitat polygon's type when the station has none. A differing type is allowed."""
    if station.habitat_type_id is None and station.habitat_feature_id is not None:
        station.habitat_type = station.habitat_feature.habitat_type


def _frost_ids(station):
    return (
        station.sensorthings_thing_id,
        station.sensorthings_datastream_ids,
        station.metadata_json.get(frost.FOI_KEY),
    )


def _set_frost_ids(station, ids):
    thing_id, datastream_ids, foi_id = ids
    station.sensorthings_thing_id = thing_id
    station.sensorthings_datastream_ids = datastream_ids
    if foi_id:
        station.metadata_json = {**station.metadata_json, frost.FOI_KEY: foi_id}


def keep_stored_frost_ids(station):
    """Call before saving an edited station, in the same transaction: locks the row and takes the
    FROST ids from it. A registration may have replaced them since the station was loaded, and
    only a registration writes them."""
    stored = SensorStationLink.objects.select_for_update().get(pk=station.pk)
    station.sensorthings_thing_id = stored.sensorthings_thing_id
    station.sensorthings_datastream_ids = stored.sensorthings_datastream_ids
    station.metadata_json = stored.metadata_json


def register_station(station_id, user):
    """Create or update the station's entities in FROST and save the ids it gets (T078).

    Returns the station and whether a stored Thing was missing, or not the station's, so that it
    was registered anew. The ids are saved even when a later request fails, so the next run
    updates what was created instead of making it a second time. Raises `frost.FrostError`.
    """
    failure, recreated = None, False
    with transaction.atomic():
        # Held to the end of the transaction. Two runs at once would both find no Thing (or no
        # shared Sensor) and both create one.
        with connection.cursor() as cursor:
            cursor.execute("SELECT pg_advisory_xact_lock(%s)", [REGISTER_LOCK_KEY])
        # Read after the lock, so the ids of a run that just ended are here. The row itself is not
        # locked while FROST is called: an admin can still edit the station.
        station = SensorStationLink.objects.select_related("habitat_type", "habitat_feature").get(
            pk=station_id
        )
        before = _frost_ids(station)
        try:
            recreated = frost.register(station)
        except frost.FrostError as error:
            failure = error  # raised below, so that the ids are committed first
        ids = _frost_ids(station)
        if ids != before:
            # Only the ids go onto the row as it is now: it may have been edited meanwhile.
            station = SensorStationLink.objects.select_for_update().get(pk=station_id)
            _set_frost_ids(station, ids)
            save_with_reason(station, user, "Registered in FROST")
    if failure is not None:
        raise failure
    return station, recreated


def copy_station(station, project, code, user):
    """A new station in `project` with the same place and description (T078). A station stays in
    its project, so this is how one gets into another.

    The habitat polygon and the transects belong to the source project and the FROST ids to the
    source station, so none of them are copied.
    """
    copy = SensorStationLink(
        project=project,
        code=code,
        name=station.name,
        geometry=station.geometry.clone(),
        habitat_type=station.habitat_type,
        is_simulated=station.is_simulated,
        active=station.active,
        created_by=user,
    )
    save_with_reason(copy, user, f"Copied from station {station.code} of {station.project}")
    return copy


def station_code_taken(project, code):
    """Whether a station of the project, a deleted one included, already has the code."""
    return SensorStationLink.objects.filter(project=project, code=code).exists()
