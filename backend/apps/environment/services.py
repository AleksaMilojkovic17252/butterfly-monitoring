"""Manual environmental snapshots (T063, D-076): derived from a finished visit's own weather."""

from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from apps.environment.models import EnvironmentalSnapshot, SnapshotMoment, SourceType

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
