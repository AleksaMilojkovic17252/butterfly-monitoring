"""Small GBIF API client for the seed commands (T024).

Every response is saved as JSON under `SEEDS_DIR/cache/`. A cached call makes no request, so the
seed commands run again offline. Live calls are limited to 3 per second.
"""

import hashlib
import json
import os
import re
import time
from urllib.parse import urlencode

import requests
from django.conf import settings

API = "https://api.gbif.org/v1"
USER_AGENT = "butterfly-monitoring (master's thesis seed data; github.com/AleksaMilojkovic17252)"
MIN_INTERVAL_S = 1 / 3
TIMEOUT_S = 30


class GbifError(RuntimeError):
    pass


class GbifClient:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers["User-Agent"] = USER_AGENT
        if not settings.SEEDS_DIR.is_dir():
            raise GbifError(
                f"Seeds folder {settings.SEEDS_DIR} not found. "
                "compose.dev.yaml mounts database/seeds there; set SEEDS_DIR to use another."
            )
        self.cache_dir = settings.SEEDS_DIR / "cache"
        self.live_requests = 0
        self._last_request = 0.0

    def get(self, path, **params):
        """GET `API + path` and return the parsed JSON, from the cache when it is there."""
        cache_file = self._cache_file(path, params)
        if cache_file.exists():
            return json.loads(cache_file.read_text(encoding="utf-8"))
        wait = MIN_INTERVAL_S - (time.monotonic() - self._last_request)
        if wait > 0:
            time.sleep(wait)
        try:
            response = self.session.get(API + path, params=params, timeout=TIMEOUT_S)
            response.raise_for_status()
            data = response.json()
        except (requests.RequestException, ValueError) as error:
            raise GbifError(f"GBIF request failed for {path}: {error}") from error
        finally:
            self._last_request = time.monotonic()
        self.live_requests += 1
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        # Write and rename, so an interrupted run never leaves a half-written file that the
        # next run would fail to read.
        temp_file = cache_file.with_suffix(".tmp")
        temp_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8"
        )
        os.replace(temp_file, cache_file)
        return data

    def _cache_file(self, path, params):
        query = urlencode(sorted(params.items()))
        slug = re.sub(r"[^A-Za-z0-9]+", "_", path).strip("_")
        # The hash keeps names short and unique when the query is long (species keys, names).
        digest = hashlib.sha1(query.encode()).hexdigest()[:10]
        return self.cache_dir / f"{slug}-{digest}.json"

    def match(self, name, rank=None, kingdom=None):
        """`/species/match`: the backbone record for a name. `usageKey` is missing when no match."""
        params = {"name": name}
        if rank:
            params["rank"] = rank
        if kingdom:
            params["kingdom"] = kingdom
        return self.get("/species/match", **params)

    def species_counts(self, country, taxon_key):
        """Occurrence records per species key in a country: `{speciesKey: record_count}`."""
        data = self.get(
            "/occurrence/search",
            country=country,
            taxonKey=taxon_key,
            facet="speciesKey",
            facetLimit=1000,
            limit=0,
        )
        facets = [f for f in data.get("facets", []) if f["field"] == "SPECIES_KEY"]
        return {int(c["name"]): c["count"] for f in facets for c in f["counts"]}

    def species(self, key):
        return self.get(f"/species/{key}")

    def vernacular_names(self, key):
        """Vernacular names as `{"srp": "...", "eng": "..."}`, the first one of each language."""
        data = self.get(f"/species/{key}/vernacularNames", limit=100)
        names = {}
        for item in data.get("results", []):
            language = item.get("language")
            if language in ("srp", "eng") and language not in names and item.get("vernacularName"):
                names[language] = item["vernacularName"]
        return names
