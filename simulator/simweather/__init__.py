"""Simulated weather: a daily story of temperature, cloud, wind and rain (T071).

Standard library only and pure: the same inputs always give the same output, and nothing
touches a database. `simulate_season` (T071) uses it for the manual weather of each simulated
visit, and the sensor simulator (T079) imports it too, so the sensor readings and the weather
written on the visits agree.

The weather is **plausible, not realistic**: a seasonal temperature curve, a day-to-day anomaly
that persists for a few days, a two-state rain chain and a diurnal curve. It is not fitted to any
station. The project evaluates the system, not the climate.
"""

import math
import random
from dataclasses import dataclass
from datetime import date, timedelta

PRECIPITATION = ("none", "drizzle", "light_rain", "rain")

# cos curve through about 16 C on 1 May, 24 C in mid-July and 20.5 C at the end of August.
_MEAN_C = 12.93
_AMPLITUDE_C = 11.07
_PEAK_DAY_OF_YEAR = 196  # 15 July
_ANOMALY_PERSISTENCE = 0.7
_ANOMALY_SD_C = 2.0
_RAIN_AFTER_DRY = 0.15
_RAIN_AFTER_RAIN = 0.5


@dataclass(frozen=True)
class DailyWeather:
    date: date
    t_mean_c: float
    t_max_c: float
    cloud_pct: int
    wind_beaufort: int
    precipitation: str  # one of PRECIPITATION
    rain_mm: float


def _clamp(value, low, high):
    return max(low, min(high, value))


def season(seed, start, end, lat, lon):
    """One `DailyWeather` per day from `start` to `end` (both included).

    `lat` and `lon` only shift the base temperature a little (a degree per ten degrees of
    latitude away from 45 N, and a small east-west term).
    """
    rng = random.Random(f"{seed}:simweather")
    shift = -0.1 * (lat - 45.0) + 0.02 * (lon - 20.0)
    anomaly = 0.0
    raining = False
    days = []
    day = start
    while day <= end:
        anomaly = _ANOMALY_PERSISTENCE * anomaly + rng.gauss(0, _ANOMALY_SD_C)
        seasonal = _MEAN_C + _AMPLITUDE_C * math.cos(
            2 * math.pi * (day.timetuple().tm_yday - _PEAK_DAY_OF_YEAR) / 365
        )
        raining = rng.random() < (_RAIN_AFTER_RAIN if raining else _RAIN_AFTER_DRY)
        if raining:
            kind = rng.choices(PRECIPITATION[1:], weights=[4, 4, 2])[0]
            rain_mm = round(rng.uniform(0.2, 2.0) * (1 + PRECIPITATION.index(kind)), 1)
        else:
            kind, rain_mm = "none", 0.0
        t_mean = seasonal + shift + anomaly - (2.0 if raining else 0.0)
        t_max = t_mean + rng.uniform(3.0, 5.5)
        cloud = 40 - 6 * anomaly + rng.gauss(0, 25)
        if raining:
            cloud = max(cloud, 80 + rng.uniform(0, 20))
        wind = rng.gauss(2.2 + (1.0 if raining else 0.0), 1.1)
        days.append(
            DailyWeather(
                date=day,
                t_mean_c=round(t_mean, 1),
                t_max_c=round(t_max, 1),
                cloud_pct=int(_clamp(round(cloud), 0, 100)),
                wind_beaufort=int(_clamp(round(wind), 0, 6)),
                precipitation=kind,
                rain_mm=rain_mm,
            )
        )
        day += timedelta(days=1)
    return days


def at_hour(day, local_hour, rng):
    """The weather at a local hour of `day`: `(temp_c, cloud_pct, wind_beaufort, precipitation)`.

    A diurnal temperature curve (mean at 09:00, peak at 15:00) plus small noise from `rng`.
    """
    amplitude = day.t_max_c - day.t_mean_c
    temp = day.t_mean_c + amplitude * math.sin(2 * math.pi * (local_hour - 9.0) / 24)
    temp += rng.gauss(0, 0.7)
    cloud = int(_clamp(round(day.cloud_pct + rng.gauss(0, 8)), 0, 100))
    wind = int(_clamp(day.wind_beaufort + rng.choice([-1, 0, 0, 1]), 0, 6))
    return round(temp, 1), cloud, wind, day.precipitation
