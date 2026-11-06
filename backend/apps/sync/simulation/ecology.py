"""Plausible butterfly abundance (T071): per-taxon parameters from the taxon id, and counts.

Not realistic ecology: the thesis evaluates the system. Every parameter comes from a SHA-256 of
the taxon id, never from `hash()` (salted per process), so the same list always gives the same
season.
"""

import hashlib
import math

MAX_ORDINARY_COUNT = 50  # high_count (> 50) is injected on purpose, never drawn


def _digest(text):
    return hashlib.sha256(text.encode()).digest()


def taxon_params(taxon_id):
    """`(peak_day_of_year, sigma_days, base_abundance)` of a taxon."""
    digest = _digest(str(taxon_id))
    peak = 120 + digest[0] / 255 * 130  # day of year 120-250
    sigma = 7 + digest[1] / 255 * 23  # 7-30 days
    u = (digest[2] * 256 + digest[3]) / 65535
    base = 0.002 + 1.0 * u**6  # most species rare, a few common
    return peak, sigma, base


def habitat_weight(taxon_id, habitat_code):
    """How much a taxon likes a habitat, 0-1, squared so that strong liking is rare."""
    digest = _digest(f"{taxon_id}:{habitat_code}")
    return (digest[0] / 255) ** 2


def expected_count(params, day_of_year, habitat_weight_value, temp_c, cloud_pct):
    peak, sigma, base = params
    flight = math.exp(-0.5 * ((day_of_year - peak) / sigma) ** 2)
    weather = max(0.1, min(1.2, (temp_c - 12.0) / 12.0)) * (1 - 0.5 * cloud_pct / 100)
    return base * habitat_weight_value * flight * weather


def poisson(rng, lam):
    """Knuth's sampler; a normal approximation above 30."""
    if lam <= 0:
        return 0
    if lam > 30:
        return max(0, round(rng.gauss(lam, math.sqrt(lam))))
    limit = math.exp(-lam)
    k, p = 0, 1.0
    while True:
        p *= rng.random()
        if p <= limit:
            return k
        k += 1
