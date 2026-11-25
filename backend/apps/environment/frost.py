"""FROST-Server (SensorThings API 1.1) calls for sensor stations (T078, D-117).

One station is a Thing with its Location, four Datastreams and a FeatureOfInterest. The Sensor and
the four ObservedProperties are shared by all stations. FROST gives internal clients internal links
(D-118), so entity URLs are built from `settings.FROST_URL`. Admin actions reach this through
`apps.environment.services`.
"""

import json
import re

import requests
from django.conf import settings

TIMEOUT = 10
GEOJSON = "application/geo+json"
OM_MEASUREMENT = "http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement"
# `metadata_json` key of the station's FeatureOfInterest id, which T079 sends with every value.
FOI_KEY = "sensorthings_foi_id"
# Units link to the paragraph of the UCUM specification whose table defines the unit.
_UCUM = "http://unitsofmeasure.org/ucum.html#para-"
_NERC = "https://vocab.nerc.ac.uk/standard_name/"

# The keys are the keys of `sensorthings_datastream_ids`, which T079 and T081 read.
OBSERVED_PROPERTIES = {
    "air_temperature": {
        "name": "Air temperature",
        "definition": f"{_NERC}air_temperature/",
        "description": "Temperature of the air (CF standard name air_temperature)",
        "unit": {"name": "degree Celsius", "symbol": "°C", "definition": f"{_UCUM}30"},
    },
    "relative_humidity": {
        "name": "Relative humidity",
        "definition": f"{_NERC}relative_humidity/",
        "description": "Humidity of the air (CF standard name relative_humidity)",
        "unit": {"name": "percent", "symbol": "%", "definition": f"{_UCUM}29"},
    },
    "wind_speed": {
        "name": "Wind speed",
        "definition": f"{_NERC}wind_speed/",
        "description": "Speed of the wind (CF standard name wind_speed)",
        "unit": {"name": "metre per second", "symbol": "m/s", "definition": f"{_UCUM}28"},
    },
    "solar_radiation": {
        "name": "Global solar radiation",
        "definition": f"{_NERC}surface_downwelling_shortwave_flux_in_air/",
        "description": (
            "Solar radiation reaching the ground "
            "(CF standard name surface_downwelling_shortwave_flux_in_air)"
        ),
        "unit": {"name": "watt per square metre", "symbol": "W/m²", "definition": f"{_UCUM}30"},
    },
}

SENSOR = {
    "name": "Virtual microclimate sensor v1",
    "description": "Simulated sensor of the butterfly monitoring project, not a physical device",
    "encodingType": "text/plain",
    "metadata": (
        "Simulation, not real measurements. Values every 10 minutes of air temperature, relative "
        "humidity, wind speed and global solar radiation, derived from the project's simulated "
        "weather (simweather)."
    ),
}


class FrostError(Exception):
    """FROST could not be reached or refused a request. The message is shown to the admin."""


class FrostUnreachable(FrostError):
    """No answer at all: a refused connection or a timeout. Trying the next station is pointless
    and each try can take TIMEOUT seconds."""


def _url(path):
    return f"{settings.FROST_URL.rstrip('/')}/{path}"


def _entity(entity_set, entity_id):
    return _url(f"{entity_set}({entity_id})")


def _request(method, url, *, missing_ok=False, **kwargs):
    """The response, or None for a 404 when `missing_ok`."""
    try:
        response = requests.request(method, url, timeout=TIMEOUT, **kwargs)
    except requests.RequestException as error:
        raise FrostUnreachable(
            f"FROST at {settings.FROST_URL} cannot be reached ({type(error).__name__})."
        ) from error
    if missing_ok and response.status_code == 404:
        return None
    if not response.ok:
        raise FrostError(
            f"FROST answered {response.status_code} to {method} {url}: {response.text[:200]}"
        )
    return response


def _get(url, **kwargs):
    """The JSON of an entity or a collection, or None when there is no such entity."""
    response = _request("GET", url, missing_ok=True, **kwargs)
    if response is None:
        return None
    try:
        return response.json()
    except ValueError as error:
        raise FrostError(f"FROST sent no JSON for {url}.") from error


def _is_of(station, entity):
    """Whether a Thing or FeatureOfInterest was made for this station. A stored id alone proves
    nothing: ids start again when FROST's database is made anew."""
    return (entity.get("properties") or {}).get("station_link_id") == str(station.pk)


def _own_entity_exists(station, entity_set, entity_id):
    if not entity_id:
        return False
    entity = _get(_entity(entity_set, entity_id))
    return entity is not None and _is_of(station, entity)


def _list(path, **params):
    data = _get(_url(path), params=params)
    if data is None:
        raise FrostError(f"FROST has no {_url(path)}.")
    return data["value"]


def _create(path, body):
    """POST `body` and return the new entity's id, read from the `Location` header."""
    response = _request("POST", _url(path), json=body)
    location = response.headers.get("Location", "")
    match = re.search(r"\(([^()]+)\)$", location)
    if not match:
        raise FrostError(f"FROST created an entity at {path} but sent no id: {location!r}")
    return match.group(1)


def _find_or_create(entity_set, key, body):
    """The id of the shared entity whose `key` equals `body[key]`, made or brought up to date."""
    found = _list(entity_set, **{"$filter": f"{key} eq '{body[key]}'", "$orderby": "id"})
    if not found:
        return _create(entity_set, body)
    entity = found[0]
    if any(entity.get(name) != value for name, value in body.items()):
        _request("PATCH", _entity(entity_set, entity["@iot.id"]), json=body)
    return entity["@iot.id"]


def ensure_shared():
    """The ids of the shared Sensor and ObservedProperties, which are created only once."""
    properties = {
        key: _find_or_create(
            "ObservedProperties",
            "definition",
            {name: prop[name] for name in ("name", "definition", "description")},
        )
        for key, prop in OBSERVED_PROPERTIES.items()
    }
    return {"sensor": _find_or_create("Sensors", "name", SENSOR), "properties": properties}


def _link(entity_id):
    # Ids are numbers in FROST; the ones read from a `Location` header are text.
    return {"@iot.id": int(entity_id) if str(entity_id).isdigit() else entity_id}


def _geojson(geometry):
    return json.loads(geometry.geojson)


def _thing(station):
    habitat = station.habitat_type
    return {
        "name": f"{station.code} — {station.name} (simulated)",
        "description": "Simulated microclimate station",
        "properties": {
            "project_id": str(station.project_id),
            "habitat_type": habitat.name_en.lower() if habitat else None,
            "simulated": True,
            "station_link_id": str(station.pk),
        },
    }


def _location(station):
    return {
        "name": station.code,
        "description": "Station point",
        "encodingType": GEOJSON,
        "location": _geojson(station.geometry),
    }


def _feature_of_interest(station):
    """The linked habitat polygon while it is one, otherwise the station point."""
    habitat = station.habitat_polygon
    if habitat is not None:
        name, description = f"{station.code} habitat", "Habitat polygon of the station"
        geometry = habitat.geometry
    else:
        name, description = f"{station.code} station point", "Point of the station"
        geometry = station.geometry
    return {
        "name": name,
        "description": f"{description} (simulated station)",
        "encodingType": GEOJSON,
        "feature": _geojson(geometry),
        "properties": {"simulated": True, "station_link_id": str(station.pk)},
    }


def _datastream(station, key):
    """A Datastream without its Sensor and ObservedProperty links, as a PATCH sends it."""
    prop = OBSERVED_PROPERTIES[key]
    return {
        "name": f"{station.code} {prop['name'].lower()}, 10 min",
        "description": "Simulated, 10-minute",
        "unitOfMeasurement": prop["unit"],
        "observationType": OM_MEASUREMENT,
        "properties": {"simulated": True, "interval": "PT10M", "station_link_id": str(station.pk)},
    }


def _new_datastream(station, key, shared):
    return {
        **_datastream(station, key),
        "Sensor": _link(shared["sensor"]),
        "ObservedProperty": _link(shared["properties"][key]),
    }


def _save_feature_of_interest(station):
    body = _feature_of_interest(station)
    foi_id = station.metadata_json.get(FOI_KEY)
    if _own_entity_exists(station, "FeaturesOfInterest", foi_id):
        _request("PATCH", _entity("FeaturesOfInterest", foi_id), json=body)
    else:
        foi_id = _create("FeaturesOfInterest", body)
        station.metadata_json = {**station.metadata_json, FOI_KEY: foi_id}


def _datastreams_in_frost(thing_id):
    """`{observed property definition: [datastream ids]}` of a Thing."""
    found = {}
    rows = _list(
        f"Things({thing_id})/Datastreams",
        **{"$expand": "ObservedProperty($select=definition)", "$orderby": "id"},
    )
    for row in rows:
        definition = row["ObservedProperty"]["definition"]
        found.setdefault(definition, []).append(str(row["@iot.id"]))
    return found


def _create_thing(station, shared):
    """One deep insert: the Thing with its Location and four Datastreams, all or nothing."""
    station.sensorthings_thing_id = _create(
        "Things",
        {
            **_thing(station),
            "Locations": [_location(station)],
            "Datastreams": [_new_datastream(station, key, shared) for key in OBSERVED_PROPERTIES],
        },
    )
    station.sensorthings_datastream_ids = {}
    found = _datastreams_in_frost(station.sensorthings_thing_id)
    station.sensorthings_datastream_ids = {
        key: found[prop["definition"]][0] for key, prop in OBSERVED_PROPERTIES.items()
    }


def _update_thing(station, shared):
    """PATCH what is there. A Datastream that was deleted in FROST is created again.

    No HistoricalLocation is ever posted: FROST makes them itself (D-117).
    """
    thing_id = station.sensorthings_thing_id
    _request("PATCH", _entity("Things", thing_id), json=_thing(station))

    locations = _list(f"Things({thing_id})/Locations")
    if locations:
        location_url = _entity("Locations", locations[0]["@iot.id"])
        _request("PATCH", location_url, json=_location(station))
    else:
        _create(f"Things({thing_id})/Locations", _location(station))

    found = _datastreams_in_frost(thing_id)
    ids = dict(station.sensorthings_datastream_ids)
    for key, prop in OBSERVED_PROPERTIES.items():
        existing = found.get(prop["definition"], [])
        if existing:
            if ids.get(key) not in existing:
                ids[key] = existing[0]
            _request("PATCH", _entity("Datastreams", ids[key]), json=_datastream(station, key))
        else:
            path = f"Things({thing_id})/Datastreams"
            ids[key] = _create(path, _new_datastream(station, key, shared))
        station.sensorthings_datastream_ids = dict(ids)


def register(station):
    """Make FROST match the station. True when it had a stored Thing id that is missing from
    FROST, or is now something else's, and a new Thing was made.

    Sets the ids on `station` as soon as each is known and does not save it. Idempotent: with the
    ids stored, a second run only updates. Raises `FrostError`.
    """
    shared = ensure_shared()
    _save_feature_of_interest(station)
    thing_id = station.sensorthings_thing_id
    if _own_entity_exists(station, "Things", thing_id):
        _update_thing(station, shared)
        return False
    _create_thing(station, shared)
    return bool(thing_id)


def check(station):
    """The problems with the stored ids, as sentences. An empty list means that all of them
    exist and are this station's. Raises `FrostUnreachable`."""
    if not station.sensorthings_thing_id:
        return ["Not registered in FROST yet."]
    datastreams = station.sensorthings_datastream_ids
    stored = [("Thing", "Things", station.sensorthings_thing_id)]
    stored += [
        (f"{prop['name']} Datastream", "Datastreams", datastreams.get(key))
        for key, prop in OBSERVED_PROPERTIES.items()
    ]
    stored.append(("FeatureOfInterest", "FeaturesOfInterest", station.metadata_json.get(FOI_KEY)))
    problems = []
    for label, entity_set, entity_id in stored:
        if not entity_id:
            problems.append(f"{label}: no id stored.")
            continue
        try:
            entity = _get(_entity(entity_set, entity_id))
        except FrostUnreachable:
            raise
        except FrostError as error:
            return [*problems, str(error)]
        if entity is None:
            problems.append(f"{label} {entity_id} is not in FROST.")
        elif not _is_of(station, entity):
            problems.append(f"{label} {entity_id} in FROST is not this station's.")
    return problems
