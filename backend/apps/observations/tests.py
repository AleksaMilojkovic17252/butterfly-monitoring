"""One or more tests per observation rule (T055), no database: the rules are pure functions.

Run: `python manage.py test apps.observations`. An exception to D-021, asked for by the ticket;
the app has the same cases in `mobile/test/validation/observation_rules_test.dart`.
"""

from datetime import UTC, datetime, timedelta
from decimal import Decimal

from django.contrib.gis.geos import LineString, Point
from django.test import SimpleTestCase

from apps.observations.rules import (
    ObservationRuleContext,
    observation_warnings,
    photo_missing,
    validate_observation,
)

STARTED = datetime(2026, 6, 1, 8, 0, tzinfo=UTC)
ENDED = datetime(2026, 6, 1, 9, 0, tzinfo=UTC)


def make_context(**changes):
    values = {
        "visit_status": "in_progress",
        "visit_started_at": STARTED,
        "visit_ended_at": None,
        "visit_zero_confirmed": False,
        "tolerance_min": 5,
        "accuracy_warning_m": Decimal("25.0"),
        "taxon_photo_required": False,
        "photo_count": 0,
    }
    return ObservationRuleContext(**{**values, **changes})


def make_data(**changes):
    values = {
        "observed_at": STARTED + timedelta(minutes=10),
        "count": 1,
        "geometry": Point(21.9, 43.3, srid=4326),
        "source": "transect",
        "sex": "unknown",
        "life_stage": "adult",
        "behaviour": [],
        "identification_confidence": "confirmed_in_field",
        "location_accuracy_m": None,
    }
    return {**values, **changes}


class ObservationRulesTest(SimpleTestCase):
    def test_a_good_observation_has_no_errors_or_warnings(self):
        self.assertEqual(validate_observation(make_data(), make_context()), {})
        self.assertEqual(observation_warnings(make_data(), make_context()), [])

    def test_v01_count_below_one(self):
        self.assertEqual(validate_observation(make_data(count=1), make_context()), {})
        self.assertEqual(
            validate_observation(make_data(count=0), make_context()), {"count": ["V01"]}
        )

    def test_v02_missing_observed_at_and_geometry(self):
        errors = validate_observation(make_data(observed_at=None, geometry=None), make_context())
        self.assertEqual(errors, {"observed_at": ["V02"], "geometry": ["V02"]})

    def test_v03_visit_status(self):
        for status in ["in_progress", "completed", "synced", "reviewed"]:
            context = make_context(visit_status=status, visit_ended_at=ENDED)
            self.assertEqual(validate_observation(make_data(), context), {}, status)
        for status in ["draft", "locked", None]:
            context = make_context(visit_status=status)
            self.assertEqual(
                validate_observation(make_data(), context), {"survey_visit": ["V03"]}, status
            )
        # T041: a cancelled visit takes observations only if it was started.
        started = make_context(visit_status="cancelled", visit_started_at=STARTED)
        self.assertEqual(validate_observation(make_data(), started), {})
        not_started = make_context(visit_status="cancelled", visit_started_at=None)
        self.assertEqual(validate_observation(make_data(), not_started), {"survey_visit": ["V03"]})

    def test_v03_does_not_apply_to_an_incidental_observation(self):
        data = make_data(source="incidental")
        self.assertEqual(validate_observation(data, make_context(visit_status=None)), {})

    def test_v04_observed_at_within_the_visit(self):
        context = make_context(visit_ended_at=ENDED)
        inside = [STARTED - timedelta(minutes=5), STARTED, ENDED, ENDED + timedelta(minutes=5)]
        for observed_at in inside:
            data = make_data(observed_at=observed_at)
            self.assertEqual(validate_observation(data, context), {}, observed_at)
        outside = [STARTED - timedelta(minutes=6), ENDED + timedelta(minutes=6)]
        for observed_at in outside:
            data = make_data(observed_at=observed_at)
            self.assertEqual(
                validate_observation(data, context), {"observed_at": ["V04"]}, observed_at
            )

    def test_v04_without_ended_at_only_the_lower_bound_applies(self):
        late = make_data(observed_at=ENDED + timedelta(days=1))
        self.assertEqual(validate_observation(late, make_context()), {})
        early = make_data(observed_at=STARTED - timedelta(minutes=6))
        self.assertEqual(validate_observation(early, make_context()), {"observed_at": ["V04"]})

    def test_v06_no_transect_observation_on_a_true_zero_visit(self):
        context = make_context(visit_zero_confirmed=True)
        self.assertEqual(validate_observation(make_data(), context), {"survey_visit": ["V06"]})
        incidental = make_data(source="incidental")
        self.assertEqual(validate_observation(incidental, context), {})

    def test_v07_choices(self):
        data = make_data(sex="x", life_stage="x", source="x", identification_confidence="x")
        errors = validate_observation(data, make_context())
        for field in ["sex", "life_stage", "source", "identification_confidence"]:
            self.assertEqual(errors[field], ["V07"], field)

    def test_v07_behaviour_items(self):
        ok = make_data(behaviour=["flying", "resting"])
        self.assertEqual(validate_observation(ok, make_context()), {})
        bad = make_data(behaviour=["flying", "dancing"])
        self.assertEqual(validate_observation(bad, make_context()), {"behaviour": ["V07"]})

    def test_v08_geometry(self):
        for geometry in [Point(-180, -90), Point(180, 90)]:
            self.assertEqual(validate_observation(make_data(geometry=geometry), make_context()), {})
        bad = [
            Point(181, 0),
            Point(0, 91),
            Point(),  # empty
            LineString((0, 0), (1, 1)),
        ]
        for geometry in bad:
            self.assertEqual(
                validate_observation(make_data(geometry=geometry), make_context()),
                {"geometry": ["V08"]},
                geometry.wkt,
            )

    def test_w01_photo_required_and_missing(self):
        self.assertTrue(photo_missing(True, 0))
        self.assertFalse(photo_missing(True, 1))
        self.assertFalse(photo_missing(False, 0))
        context = make_context(taxon_photo_required=True)
        self.assertEqual(observation_warnings(make_data(), context), ["W01"])
        context = make_context(taxon_photo_required=True, photo_count=1)
        self.assertEqual(observation_warnings(make_data(), context), [])

    def test_w02_poor_accuracy(self):
        poor = make_data(location_accuracy_m=Decimal("25.1"))
        self.assertEqual(observation_warnings(poor, make_context()), ["W02"])
        for accuracy in [Decimal("25.0"), Decimal("5.0"), None]:
            data = make_data(location_accuracy_m=accuracy)
            self.assertEqual(observation_warnings(data, make_context()), [], accuracy)

    def test_w03_oviposition(self):
        data = make_data(behaviour=["flying", "oviposition"])
        self.assertEqual(observation_warnings(data, make_context()), ["W03"])
        self.assertEqual(observation_warnings(make_data(behaviour=["flying"]), make_context()), [])

    def test_w04_larva(self):
        data = make_data(life_stage="larva")
        self.assertEqual(observation_warnings(data, make_context()), ["W04"])
        self.assertEqual(observation_warnings(make_data(life_stage="pupa"), make_context()), [])
