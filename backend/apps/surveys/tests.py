"""Tests that need no database (SimpleTestCase). An exception to D-021, asked for by the tickets.

- The server's visit lifecycle must match the shared spec the app also reads (T034). The app has
  the same check in `mobile/test/visit_status_test.dart`.
- The input rules of a visit (T055), at the end of this file.

Run: `python manage.py test apps.surveys`.
"""

import json
from datetime import UTC, date, datetime, time
from decimal import Decimal

from django.conf import settings
from django.test import SimpleTestCase

from apps.projects.models import ProjectProtocol
from apps.surveys.models import CancelReason, VisitStatus
from apps.surveys.rules import VisitRuleContext, validate_visit, visit_warnings
from apps.surveys.state import TRANSITIONS

# docs/ sits next to backend/ in the repo; in the container it is mounted at /docs.
SPEC_PATH = settings.BASE_DIR.parent / "docs" / "requirements" / "visit-states.json"


class VisitStatesMatchSpecTest(SimpleTestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.spec = json.loads(SPEC_PATH.read_text())

    def test_statuses(self):
        self.assertEqual(self.spec["statuses"], VisitStatus.values)

    def test_cancel_reasons(self):
        self.assertEqual(self.spec["cancel_reasons"], CancelReason.values)

    def test_transitions(self):
        spec_transitions = {(row["from"], row["to"]): row["by"] for row in self.spec["transitions"]}
        self.assertEqual(len(spec_transitions), len(self.spec["transitions"]), "duplicate rows")
        server_transitions = {
            (str(from_status), str(to_status)): actor
            for (from_status, to_status), actor in TRANSITIONS.items()
        }
        self.assertEqual(spec_transitions, server_transitions)


# The input rules of a visit (T055). The app has the same cases in
# `mobile/test/validation/visit_rules_test.dart`.


def make_protocol(**changes):
    values = {
        "time_zone": "Europe/Belgrade",
        "season_start": date(2026, 4, 1),
        "season_end": date(2026, 9, 30),
        "day_start_time": time(10, 0),
        "day_end_time": time(17, 0),
        "min_temperature_c": Decimal("13.0"),
        "sunny_temperature_c": Decimal("17.0"),
        "max_cloud_cover_pct_if_cool": 40,
        "max_wind_beaufort": 5,
        "allow_precipitation": False,
    }
    return ProjectProtocol(**{**values, **changes})


def make_context(**changes):
    values = {"protocol": make_protocol(), "transect_observation_count": 0}
    return VisitRuleContext(**{**values, **changes})


def make_data(**changes):
    values = {
        "status": "completed",
        "survey_method": "pollard_walk",
        "precipitation": "none",
        "cancel_reason": "",
        "started_at": datetime(2026, 6, 1, 10, 0, tzinfo=UTC),  # 12:00 in Belgrade (UTC+2)
        "zero_observation_confirmed": False,
        "weather_missing_reason": "",
        "temperature_start_c": Decimal("20.0"),
        "temperature_end_c": Decimal("22.0"),
        "wind_beaufort_start": 2,
        "wind_beaufort_end": 2,
        "cloud_cover_start_pct": 20,
        "cloud_cover_end_pct": 20,
    }
    return {**values, **changes}


class VisitRulesTest(SimpleTestCase):
    def test_a_good_visit_has_no_errors_or_warnings(self):
        self.assertEqual(validate_visit(make_data(), make_context()), {})
        self.assertEqual(visit_warnings(make_data(), make_context()), [])

    def test_v05_finished_visit_needs_weather_or_a_reason(self):
        data = make_data(temperature_end_c=None, wind_beaufort_end=None)
        expected = {"temperature_end_c": ["V05"], "wind_beaufort_end": ["V05"]}
        for status in ["completed", "synced", "reviewed", "locked"]:
            data["status"] = status
            self.assertEqual(validate_visit(data, make_context()), expected, status)
        data["weather_missing_reason"] = "Thermometer broke"
        self.assertEqual(validate_visit(data, make_context()), {})

    def test_v05_does_not_apply_before_the_visit_is_completed(self):
        data = make_data(temperature_end_c=None, cloud_cover_start_pct=None)
        for status in ["draft", "in_progress", "cancelled"]:
            data["status"] = status
            if status == "cancelled":
                data["cancel_reason"] = "aborted_weather"
            self.assertEqual(validate_visit(data, make_context()), {}, status)

    def test_v05_a_blank_reason_does_not_count(self):
        data = make_data(cloud_cover_end_pct=None, weather_missing_reason="  ")
        self.assertEqual(validate_visit(data, make_context()), {"cloud_cover_end_pct": ["V05"]})

    def test_v06_confirmed_zero_with_observations(self):
        data = make_data(zero_observation_confirmed=True)
        self.assertEqual(validate_visit(data, make_context()), {})
        context = make_context(transect_observation_count=2)
        self.assertEqual(validate_visit(data, context), {"zero_observation_confirmed": ["V06"]})

    def test_v06_observations_without_the_tick_are_fine(self):
        context = make_context(transect_observation_count=2)
        self.assertEqual(validate_visit(make_data(), context), {})

    def test_v06_completed_with_no_observations_is_not_checked_by_the_server(self):
        # The other direction is the app's (see docs/requirements/validation-rules.md).
        self.assertEqual(
            validate_visit(make_data(zero_observation_confirmed=False), make_context()), {}
        )

    def test_v07_choices(self):
        data = make_data(status="x", survey_method="x", precipitation="x", cancel_reason="x")
        errors = validate_visit(data, make_context())
        for field in ["status", "survey_method", "precipitation", "cancel_reason"]:
            self.assertEqual(errors[field], ["V07"], field)

    def test_w06_start_weather_outside_the_protocol(self):
        cold = make_data(temperature_start_c=Decimal("10.0"))
        self.assertEqual(visit_warnings(cold, make_context()), ["W06"])
        cool_and_cloudy = make_data(temperature_start_c=Decimal("15.0"), cloud_cover_start_pct=80)
        self.assertEqual(visit_warnings(cool_and_cloudy, make_context()), ["W06"])
        windy = make_data(wind_beaufort_start=6)
        self.assertEqual(visit_warnings(windy, make_context()), ["W06"])
        rain = make_data(precipitation="rain")
        self.assertEqual(visit_warnings(rain, make_context()), ["W06"])

    def test_w06_cool_and_clear_or_warm_and_cloudy_is_fine(self):
        cool_and_clear = make_data(temperature_start_c=Decimal("15.0"), cloud_cover_start_pct=40)
        self.assertEqual(visit_warnings(cool_and_clear, make_context()), [])
        warm_and_cloudy = make_data(temperature_start_c=Decimal("17.0"), cloud_cover_start_pct=100)
        self.assertEqual(visit_warnings(warm_and_cloudy, make_context()), [])

    def test_w06_rain_is_fine_when_the_protocol_allows_it(self):
        context = make_context(protocol=make_protocol(allow_precipitation=True))
        self.assertEqual(visit_warnings(make_data(precipitation="rain"), context), [])

    def test_w06_end_weather_outside_the_protocol(self):
        data = make_data(temperature_end_c=Decimal("9.0"))
        self.assertEqual(visit_warnings(data, make_context()), ["W06"])

    def test_w06_unrecorded_end_weather_is_skipped(self):
        data = make_data(temperature_end_c=None, wind_beaufort_end=None, cloud_cover_end_pct=None)
        self.assertEqual(visit_warnings(data, make_context()), [])

    def test_w07_season(self):
        for day in [date(2026, 4, 1), date(2026, 9, 30)]:
            started = datetime(day.year, day.month, day.day, 10, 0, tzinfo=UTC)
            self.assertEqual(visit_warnings(make_data(started_at=started), make_context()), [])
        for day in [date(2026, 3, 31), date(2026, 10, 1)]:
            started = datetime(day.year, day.month, day.day, 10, 0, tzinfo=UTC)
            self.assertEqual(visit_warnings(make_data(started_at=started), make_context()), ["W07"])

    def test_w07_season_uses_the_belgrade_date(self):
        # 22:30 UTC on 30 September is already 1 October in Belgrade (UTC+2).
        started = datetime(2026, 9, 30, 22, 30, tzinfo=UTC)
        self.assertEqual(visit_warnings(make_data(started_at=started), make_context()), ["W07"])

    def test_w07_daily_window(self):
        # Belgrade is UTC+2 in June, so 08:00 UTC is 10:00 and 15:00 UTC is 17:00.
        for hour, minute in [(8, 0), (12, 0), (15, 0)]:
            started = datetime(2026, 6, 1, hour, minute, tzinfo=UTC)
            self.assertEqual(visit_warnings(make_data(started_at=started), make_context()), [])
        for hour, minute in [(7, 59), (15, 1)]:
            started = datetime(2026, 6, 1, hour, minute, tzinfo=UTC)
            self.assertEqual(visit_warnings(make_data(started_at=started), make_context()), ["W07"])

    def test_w07_a_utc_time_inside_the_window_in_belgrade(self):
        # 08:30 UTC reads as before 10:00 on a UTC clock, but it is 10:30 in Belgrade.
        started = datetime(2026, 6, 1, 8, 30, tzinfo=UTC)
        self.assertEqual(visit_warnings(make_data(started_at=started), make_context()), [])

    def test_w07_reads_the_time_zone_of_the_protocol(self):
        # 08:30 UTC is 10:30 in Belgrade but 17:30 in Tokyo (UTC+9), after the window ends.
        started = datetime(2026, 6, 1, 8, 30, tzinfo=UTC)
        data = make_data(started_at=started)
        self.assertEqual(visit_warnings(data, make_context()), [])
        tokyo = make_context(protocol=make_protocol(time_zone="Asia/Tokyo"))
        self.assertEqual(visit_warnings(data, tokyo), ["W07"])

    def test_w07_a_visit_not_started_has_no_warning(self):
        self.assertEqual(visit_warnings(make_data(started_at=None), make_context()), [])
