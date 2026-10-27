"""The server's visit lifecycle must match the shared spec the app also reads (T034).

Run: `python manage.py test apps.surveys` (no database needed). An exception to D-021, asked for
by the ticket: the app has the same check in `mobile/test/visit_status_test.dart`.
"""

import json

from django.conf import settings
from django.test import SimpleTestCase

from apps.surveys.models import CancelReason, VisitStatus
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
