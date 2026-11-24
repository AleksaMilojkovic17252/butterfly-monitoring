# Run: python3 -m venv venv && ./venv/bin/pip install geographiclib==2.1 && ./venv/bin/python distance_check.py
# Written for section 4.2 on 2026-11-11 (GeographicLib 2.1, Python 3). Not part of the app.
"""Compare the phone's three distance methods with geodesics on WGS 84.

Python ports of mobile/lib/core/geo/polygon_math.dart (_Projection, polygonAreaM2,
lineLengthM), features/transects/domain/geo_line.dart (distanceToLineM) and the
rounding of latlong2's Distance (roundResult true). The reference is GeographicLib
(Karney), the algorithm PostGIS uses for geography on the spheroid.
"""
import math
from geographiclib.geodesic import Geodesic

G = Geodesic.WGS84
LAT0, LON0 = 44.0, 20.5  # central Serbia


def offset(lat, lon, east_m, north_m):
    """Point east_m, north_m from (lat, lon) along geodesics (exact)."""
    p = G.Direct(lat, lon, 0, north_m)
    q = G.Direct(p["lat2"], p["lon2"], 90, east_m)
    return q["lat2"], q["lon2"]


# --- A. degree lengths: series against the exact WGS 84 formulas -----------------
def series(phi_deg):
    phi = math.radians(phi_deg)
    lat = 111132.92 - 559.82 * math.cos(2 * phi) + 1.175 * math.cos(4 * phi) - 0.0023 * math.cos(6 * phi)
    lon = 111412.84 * math.cos(phi) - 93.5 * math.cos(3 * phi) + 0.118 * math.cos(5 * phi)
    return lat, lon


def exact(phi_deg):
    a, f = G.a, G.f
    e2 = f * (2 - f)
    phi = math.radians(phi_deg)
    w = 1 - e2 * math.sin(phi) ** 2
    m = a * (1 - e2) / w ** 1.5
    n = a / math.sqrt(w)
    return math.pi / 180 * m, math.pi / 180 * n * math.cos(phi)


print("A. metres per degree, series minus exact (m)")
for phi in (42, 44, 46):
    s, e = series(phi), exact(phi)
    print(f"   {phi} N: lat {s[0]-e[0]:+.4f}, lon {s[1]-e[1]:+.4f}")


# --- phone projection --------------------------------------------------------------
def project(points):
    lat0 = sum(p[0] for p in points) / len(points)
    lon0 = sum(p[1] for p in points) / len(points)
    mlat, mlon = series(lat0)
    return [((p[1] - lon0) * mlon, (p[0] - lat0) * mlat) for p in points]


def phone_area(points):
    xy = project(points)
    s = 0.0
    for i in range(len(xy)):
        ax, ay = xy[i]
        bx, by = xy[(i + 1) % len(xy)]
        s += ax * by - bx * ay
    return abs(s) / 2


def phone_line_length(points):
    xy = project(points)
    return sum(math.dist(xy[i - 1], xy[i]) for i in range(1, len(xy)))


def geo_area(points):
    poly = G.Polygon()
    for lat, lon in points:
        poly.AddPoint(lat, lon)
    _, _, area = poly.Compute(False, True)
    return abs(area)


def geo_length(points):
    return sum(G.Inverse(*points[i - 1], *points[i])["s12"] for i in range(1, len(points)))


print("\nB. polygon area, phone against geodesic")
for side in (50, 200, 500, 1000):
    sq = [offset(LAT0, LON0, x, y) for x, y in ((0, 0), (side, 0), (side, side), (0, side))]
    pa, ga = phone_area(sq), geo_area(sq)
    print(f"   square {side} m: phone {pa:.2f}, geodesic {ga:.2f} m2, diff {100*(pa-ga)/ga:+.4f} %")
irregular = [offset(LAT0, LON0, x, y) for x, y in
             ((0, 0), (180, -20), (310, 60), (260, 210), (120, 260), (30, 170), (-40, 80))]
pa, ga = phone_area(irregular), geo_area(irregular)
print(f"   irregular ~300 m: phone {pa:.1f}, geodesic {ga:.1f} m2, diff {100*(pa-ga)/ga:+.4f} %")

print("\nC. line length, phone projection against geodesic")
for total in (1000, 3000):
    line = [offset(LAT0, LON0, x, 30 * math.sin(x / 80)) for x in range(0, total + 1, 50)]
    pl, gl = phone_line_length(line), geo_length(line)
    print(f"   {total} m zigzag: phone {pl:.3f}, geodesic {gl:.3f} m, diff {pl-gl:+.3f} m")

print("\nC2. rounding each segment to a whole metre (latlong2 roundResult)")
for step in (5.0, 5.4, 5.6, 4.8):
    n = int(1000 // step)
    pts = [offset(LAT0, LON0, 0, i * step) for i in range(n + 1)]
    exact_sum = geo_length(pts)
    rounded = sum(round(G.Inverse(*pts[i - 1], *pts[i])["s12"]) for i in range(1, len(pts)))
    print(f"   straight walk, {step} m between fixes: exact {exact_sum:.1f} m, rounded sum {rounded} m, "
          f"diff {100*(rounded-exact_sum)/exact_sum:+.1f} %")


# --- D. distance from a point to a segment ------------------------------------------
def phone_dist_to_line(p, line):
    R = 6371008.8
    lat0, lon0 = map(math.radians, p)
    c = math.cos(lat0)

    def pr(q):
        return ((math.radians(q[1]) - lon0) * c * R, (math.radians(q[0]) - lat0) * R)

    best = None
    for i in range(len(line) - 1):
        ax, ay = pr(line[i])
        bx, by = pr(line[i + 1])
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        t = 0.0 if L2 == 0 else max(0.0, min(1.0, -(ax * dx + ay * dy) / L2))
        d = math.hypot(ax + t * dx, ay + t * dy)
        best = d if best is None or d < best else best
    return best


def geo_dist_to_segment(p, a, b, steps=20000):
    line = G.InverseLine(*a, *b)
    best = None
    for k in range(steps + 1):
        q = line.Position(line.s13 * k / steps)
        d = G.Inverse(*p, q["lat2"], q["lon2"])["s12"]
        best = d if best is None or d < best else best
    return best


print("\nD. point to segment, phone (sphere, equirectangular) against geodesic")
a = offset(LAT0, LON0, 0, 0)
b = offset(LAT0, LON0, 300, 120)
for off in (5, 20, 50):
    # a point off the middle of the segment, perpendicular in the local plane
    mid = offset(LAT0, LON0, 150, 60)
    ux, uy = 120 / math.hypot(300, 120), -300 / math.hypot(300, 120)
    p = offset(mid[0], mid[1], ux * off, uy * off)
    ph, ge = phone_dist_to_line(p, [a, b]), geo_dist_to_segment(p, a, b)
    print(f"   {off} m off a 323 m segment: phone {ph:.4f}, geodesic {ge:.4f} m, diff {ph-ge:+.4f} m")


# --- E. rounding with GPS noise (illustration only) ---------------------------------
import random, statistics
from geographiclib.geodesic import Geodesic
G = Geodesic.WGS84
def offset(lat, lon, e, n):
    p = G.Direct(lat, lon, 0, n); q = G.Direct(p["lat2"], p["lon2"], 90, e); return q["lat2"], q["lon2"]
for sigma in (1.0, 3.0):
    diffs = []
    for seed in range(50):
        rnd = random.Random(seed)
        pts = [offset(44.0, 20.5, rnd.gauss(0, sigma), i * 5.4 + rnd.gauss(0, sigma)) for i in range(186)]
        segs = [G.Inverse(*pts[i-1], *pts[i])["s12"] for i in range(1, len(pts))]
        diffs.append(100 * (sum(round(s) for s in segs) - sum(segs)) / sum(segs))
    print(f"sigma {sigma} m, 5.4 m steps, 50 runs: rounded minus exact, mean {statistics.mean(diffs):+.2f} %, "
          f"min {min(diffs):+.2f} %, max {max(diffs):+.2f} %")
