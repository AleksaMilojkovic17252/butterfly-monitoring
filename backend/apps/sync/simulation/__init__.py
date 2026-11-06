"""Simulated field days for `simulate_season` (T071, D-109). Dev only."""

import sys

from django.conf import settings

# simulator/ holds `simweather`, shared with the sensor simulator (T079). In the dev stack it is
# mounted at /simulator (infrastructure/compose.dev.yaml); on the host it sits next to backend/.
for _folder in (settings.BASE_DIR.parent / "simulator", "/simulator"):
    if str(_folder) not in sys.path:
        sys.path.append(str(_folder))
