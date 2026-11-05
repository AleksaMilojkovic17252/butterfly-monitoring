"""Input rules for a route proposal (T108): V02, V07 and V08 reject.

The rules are in docs/requirements/validation-rules.md. Pure functions, no database access:
`transects.services.save_proposal` calls them, so push and the admin are covered.
"""

from apps.resources.rules import is_valid_geometry
from apps.transects.models import ProposalReason

PROPOSAL_GEOMETRY_TYPES = ("LineString",)


def validate_proposal(data):
    """The hard errors of a route proposal as `{field: [rule ID]}`; an empty dict means valid.

    `data` holds the proposal's final values by field name; the geometry is a GEOS geometry.
    A recording that ends before it starts has no rule ID, so it is a plain sentence.
    """
    errors = {}
    # V02
    if not (data.get("name") or "").strip():
        errors.setdefault("name", []).append("V02")
    # `is None`, not `in (None, "")`: comparing a GEOS geometry with a string tries to parse it.
    if data.get("reason") in (None, ""):
        errors.setdefault("reason", []).append("V02")
    for field in ("geometry", "recorded_from", "recorded_to"):
        if data.get(field) is None:
            errors.setdefault(field, []).append("V02")
    # V07. A missing reason is V02's.
    reason = data.get("reason")
    if reason not in (None, "") and reason not in ProposalReason.values:
        errors.setdefault("reason", []).append("V07")
    # V08: at least two distinct points, in range. A line that crosses itself is valid.
    geometry = data.get("geometry")
    if geometry is not None and not is_valid_geometry(geometry, PROPOSAL_GEOMETRY_TYPES):
        errors.setdefault("geometry", []).append("V08")
    start, end = data.get("recorded_from"), data.get("recorded_to")
    if start is not None and end is not None and end < start:
        errors.setdefault("recorded_to", []).append(
            "Must not be before the start of the recording."
        )
    return errors
