"""Walking a transect (T071): positions in the UTM zone, noisy GPS fixes, a gap.

`LineWalker` holds the transect in UTM metres. Everything here is pure geometry; the random
numbers come from the caller's `random.Random`, so a seed always gives the same walk.
"""

import math
from dataclasses import dataclass

from django.contrib.gis.geos import Point

from apps.core.geo import utm_srid


class LineWalker:
    def __init__(self, line_4326):
        self.srid = utm_srid(line_4326)
        utm = line_4326.clone()
        utm.transform(self.srid)
        self.coords = [(x, y) for x, y, *_ in utm.coords]
        self.cumulative = [0.0]
        for (x1, y1), (x2, y2) in zip(self.coords, self.coords[1:], strict=False):
            self.cumulative.append(self.cumulative[-1] + math.hypot(x2 - x1, y2 - y1))
        self.length = self.cumulative[-1]

    def position(self, distance):
        """`(x, y, ux, uy)`: the point at `distance` metres along the line and the unit tangent."""
        distance = max(0.0, min(self.length, distance))
        index = 0
        while index < len(self.coords) - 2 and self.cumulative[index + 1] < distance:
            index += 1
        (x1, y1), (x2, y2) = self.coords[index], self.coords[index + 1]
        segment = self.cumulative[index + 1] - self.cumulative[index]
        part = (distance - self.cumulative[index]) / segment if segment else 0.0
        ux, uy = ((x2 - x1) / segment, (y2 - y1) / segment) if segment else (1.0, 0.0)
        return x1 + (x2 - x1) * part, y1 + (y2 - y1) * part, ux, uy

    def project(self, x, y):
        """Distance along the line of the point on it that is nearest to `(x, y)`."""
        best, best_distance = 0.0, math.inf
        for index in range(len(self.coords) - 1):
            (x1, y1), (x2, y2) = self.coords[index], self.coords[index + 1]
            dx, dy = x2 - x1, y2 - y1
            squared = dx * dx + dy * dy
            part = (
                0.0
                if squared == 0
                else max(0.0, min(1.0, ((x - x1) * dx + (y - y1) * dy) / squared))
            )
            gap = math.hypot(x - (x1 + dx * part), y - (y1 + dy * part))
            if gap < best_distance:
                best_distance = gap
                best = self.cumulative[index] + part * math.sqrt(squared)
        return best

    def to_lonlat(self, x, y):
        point = Point(x, y, srid=self.srid)
        point.transform(4326)
        return point.x, point.y

    def section_span(self, section_geometry_4326):
        """`(start_m, end_m)` of a section along the transect."""
        utm = section_geometry_4326.clone()
        utm.transform(self.srid)
        (x1, y1, *_), (x2, y2, *_) = utm.coords[0], utm.coords[-1]
        first, last = self.project(x1, y1), self.project(x2, y2)
        return min(first, last), max(first, last)

    def offset_lonlat(self, distance, offset_m):
        """Longitude and latitude of the point `offset_m` to the left of the line at `distance`."""
        x, y, ux, uy = self.position(distance)
        return self.to_lonlat(x - uy * offset_m, y + ux * offset_m)


@dataclass
class Fix:
    sequence: int
    seconds: int  # since the start of the walk
    lon: float
    lat: float
    accuracy_m: float
    altitude_m: float
    speed_m_s: float
    heading_deg: float


@dataclass
class Walk:
    speed_m_s: float
    accuracy_m: float
    walked_m: float
    duration_s: int
    fixes: list
    gap_s: int | None  # length of the injected gap, if any


def walk_visit(walker, rng, interval_s, fraction=1.0, with_gap=False):
    """Walk `fraction` of the line at 0.8-1.2 m/s with one fix every `interval_s` seconds.

    The accuracy of the visit is 3-8 m (with a little jitter per fix) and is also the sigma of
    the Gaussian noise. A gap removes fixes so that two neighbours are 61-125 s apart.
    """
    speed = rng.uniform(0.8, 1.2)
    accuracy = rng.uniform(3.0, 8.0)
    walked_m = walker.length * fraction
    duration = math.ceil(walked_m / speed)
    fixes = []
    for index in range(duration // interval_s + 1):
        seconds = index * interval_s
        x, y, ux, uy = walker.position(seconds * speed)
        fix_accuracy = max(1.0, accuracy + rng.uniform(-1.0, 1.0))
        lon, lat = walker.to_lonlat(x + rng.gauss(0, accuracy), y + rng.gauss(0, accuracy))
        fixes.append(
            Fix(
                sequence=0,
                seconds=seconds,
                lon=round(lon, 7),
                lat=round(lat, 7),
                accuracy_m=round(fix_accuracy, 1),
                altitude_m=round(250 + rng.gauss(0, 6), 1),
                speed_m_s=round(max(0.1, speed * rng.gauss(1.0, 0.05)), 2),
                heading_deg=round(math.degrees(math.atan2(ux, uy)) % 360, 1),
            )
        )
    gap_s = None
    if with_gap and len(fixes) > 40:
        gap_s = rng.randint(61, 120)
        removed = math.ceil(gap_s / interval_s) - 1
        first = rng.randint(len(fixes) // 10, len(fixes) * 6 // 10)
        if first + removed < len(fixes) - 3:
            del fixes[first : first + removed]
        else:
            gap_s = None
    for number, fix in enumerate(fixes, start=1):
        fix.sequence = number
    return Walk(speed, accuracy, walked_m, duration, fixes, gap_s)


def clean_track(walker, interval_s, speed=1.0):
    """Noise-free `(seconds, lon, lat)` fixes along the whole line, for the GPX file."""
    points = []
    for index in range(int(walker.length / speed) // interval_s + 1):
        seconds = index * interval_s
        x, y, _, _ = walker.position(seconds * speed)
        lon, lat = walker.to_lonlat(x, y)
        points.append((seconds, lon, lat))
    return points
