"""Transect rules and scopes. API and admin call these, not the models. Pull scopes: `pull_*`."""

import uuid
from decimal import ROUND_HALF_UP, Decimal

from django.contrib.gis.gdal import OGRGeometry
from django.contrib.gis.geos import GEOSGeometry
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError, connection, transaction
from django.db.models import Count, FloatField, Func, Max, OuterRef, Prefetch, Q, Subquery, Sum
from django.db.models.functions import Coalesce
from django.utils import timezone
from rest_framework import exceptions, serializers

from apps.accounts.services import is_admin
from apps.core.geo import utm_srid
from apps.core.geo_files import open_datasource
from apps.core.history import save_with_reason
from apps.projects.services import is_member, projects_for
from apps.surveys.services import counted_visits
from apps.sync.handlers import current_push_reason, soft_delete_pushed
from apps.transects import rules
from apps.transects.models import (
    ProposalStatus,
    Transect,
    TransectProposal,
    TransectSection,
)

# How far (metres) any point of a section may be from its transect line.
SECTION_TOLERANCE_M = 5.0
# The section lengths may differ from the transect length by this fraction before the admin warns.
LENGTH_MISMATCH_TOLERANCE = 0.02
MAX_GENERATED_SECTIONS = 200


class LineFileError(ValueError):
    """The uploaded line file could not be used. The message is shown to the admin."""


class SectionGenerationError(ValueError):
    """Sections cannot be generated. The message is shown to the admin."""


class GeodesicLength(Func):
    """Length in metres on the WGS 84 spheroid: `ST_Length(geometry::geography)`."""

    template = "ST_Length(%(expressions)s::geography)"
    output_field = FloatField()


def section_lies_along(section_geometry, transect_geometry):
    """True when the whole section lies within SECTION_TOLERANCE_M of the transect line.

    Not `ST_DWithin`: that only tests the closest point, so a section touching the line once
    would pass. The section must be covered by a buffer of the line, built on geography so
    the distance is in metres.
    """
    if section_geometry.empty or transect_geometry.empty:
        return False
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT ST_Covers("
            "ST_Buffer(ST_GeomFromEWKT(%s)::geography, %s)::geometry, ST_GeomFromEWKT(%s))",
            [transect_geometry.ewkt, SECTION_TOLERANCE_M, section_geometry.ewkt],
        )
        return cursor.fetchone()[0]


def transects_for(user):
    """Live transects in the user's projects (all for admins). Inactive ones are included."""
    return Transect.objects.alive().filter(project__in=projects_for(user))


def sections_for(user):
    """Live sections of `transects_for(user)`, for the REST API. The pull uses `pull_sections`."""
    return TransectSection.objects.alive().filter(transect__in=transects_for(user))


def geodesic_length_m(transect):
    """Geodesic length of one transect line in metres, for instances without `length_m`."""
    return (
        Transect.objects.filter(pk=transect.pk)
        .values_list(GeodesicLength("geometry"), flat=True)
        .get()
    )


def pull_transects(_user, project):
    """The project's transects, deleted rows included, so tombstones reach the phone."""
    return Transect.objects.filter(project=project).annotate(length_m=GeodesicLength("geometry"))


def pull_sections(_user, project):
    """Sections of the project's transects, deleted rows included, so tombstones reach the phone."""
    return TransectSection.objects.filter(transect__project=project)


def with_stats(transects, user):
    """Add `length_m`, `section_count`, `visit_count` and `last_visit_at` to a queryset.

    The visit fields are about the caller's own walked visits (admins: all visits); drafts and
    cancelled visits do not count (`surveys.services.COUNTED_STATUSES`).
    """
    # The visit figures are subqueries, not a second join: joining sections and visits together
    # would build sections x visits rows per transect.
    visits_of_transect = (
        counted_visits(user).filter(transect=OuterRef("pk")).order_by().values("transect")
    )
    return transects.annotate(
        length_m=GeodesicLength("geometry"),
        section_count=Count("sections", filter=Q(sections__deleted_at__isnull=True)),
        visit_count=Coalesce(
            Subquery(visits_of_transect.annotate(total=Count("pk")).values("total")), 0
        ),
        last_visit_at=Subquery(
            visits_of_transect.annotate(latest=Max("started_at")).values("latest")
        ),
    )


def with_sections(transects):
    """Prefetch the live sections in sequence order into `live_sections`."""
    return transects.prefetch_related(
        Prefetch(
            "sections",
            queryset=TransectSection.objects.alive().order_by("sequence_number"),
            to_attr="live_sections",
        )
    )


def linestring_from_file(uploaded):
    """Read the first line of a GPX, KML or GeoJSON upload as a 2D LineString in EPSG:4326.

    GDAL (via GeoDjango) reads all three formats; the suffix tells it which driver to use.
    Points are ignored (GPX waypoints and track points), and a MultiLineString (a GPX track)
    gives its first line.
    """
    with open_datasource(uploaded, (".gpx", ".kml", ".geojson", ".json"), LineFileError) as source:
        for layer in source:
            for feature in layer:
                line = _first_line(feature.geom)
                if line is not None:
                    return line
    raise LineFileError("The file has no line or track.")


def _first_line(geom: OGRGeometry):
    # KML and GPX lines with elevation are named "LineString25D".
    if geom.geom_type.name.removesuffix("25D") not in ("LineString", "MultiLineString"):
        return None
    if geom.srs is None:  # GeoJSON without a CRS is WGS 84 by definition
        geom.srid = 4326
    elif geom.srid != 4326:
        geom.transform(4326)
    geom.coord_dim = 2  # GPX and KML carry elevation or a Z of 0
    geos = geom.geos
    line = geos[0] if geos.geom_type == "MultiLineString" else geos
    return None if line.empty else line


def split_line(line, parts):
    """Cut a 4326 line into `parts` pieces of equal length, in order.

    The cut happens in the line's UTM zone, so the pieces are equal in metres. Fractions of a
    line in degrees are not: at 44 °N a degree of longitude is about 72 % of a degree of
    latitude (D-046). Neighbouring pieces share their end point exactly.
    """
    srid = utm_srid(line)
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT ST_AsEWKT(ST_Transform(ST_LineSubstring(ST_Transform(ST_GeomFromEWKT(%s), %s),"
            " (n - 1)::float8 / %s::float8, n::float8 / %s::float8), 4326))"
            " FROM generate_series(1, %s) n ORDER BY n",
            [line.ewkt, srid, parts, parts, parts],
        )
        pieces = [GEOSGeometry(row[0]) for row in cursor.fetchall()]
    if any(piece.geom_type != "LineString" or piece.empty for piece in pieces):
        raise SectionGenerationError("The transect line is too short to split.")
    return pieces


@transaction.atomic
def generate_sections(transect, parts, prefix, replace, user):
    """Create `parts` equal sections numbered 1..parts, with codes `<prefix><number>`.

    Refuses when the transect already has live sections, unless `replace`: those are then
    soft-deleted first (the unique constraints only cover live rows). Returns the new sections.
    """
    if not 1 <= parts <= MAX_GENERATED_SECTIONS:
        raise SectionGenerationError(f"Choose between 1 and {MAX_GENERATED_SECTIONS} sections.")
    existing = list(transect.sections.alive())
    if existing and not replace:
        raise SectionGenerationError(
            f"{transect.code} already has {len(existing)} section(s). "
            "Tick “replace” to soft-delete them first."
        )
    pieces = split_line(transect.geometry, parts)
    for section in existing:
        section._change_reason = "Replaced by generated sections"
        section.soft_delete(user)
    return [
        _new_section(transect, number, prefix, piece, user)
        for number, piece in enumerate(pieces, start=1)
    ]


def _new_section(transect, number, prefix, piece, user):
    section = TransectSection(
        transect=transect,
        section_code=f"{prefix}{number}",
        sequence_number=number,
        geometry=piece,
        created_by=user,
    )
    save_with_reason(section, user, f"Generated: section {number} of {transect.code}")
    return section


def section_length_mismatch(transect):
    """(sections_m, transect_m) when the live sections' total length is off by over 2 %, else None.

    A transect without sections has nothing to compare.
    """
    sections = transect.sections.alive()
    if not sections.exists():
        return None
    sections_m = sections.aggregate(total=Sum(GeodesicLength("geometry")))["total"]
    transect_m = (
        Transect.objects.filter(pk=transect.pk).values_list(GeodesicLength("geometry"), flat=True)
    ).get()
    if abs(sections_m - transect_m) > LENGTH_MISMATCH_TOLERANCE * transect_m:
        return sections_m, transect_m
    return None


def nearest_section_id(transect_id, point, max_distance_m):
    """Id of the live section of the transect nearest to `point` within `max_distance_m` metres,
    or None. On a tie (a shared end point) the lower sequence number wins."""
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT id FROM transect_section"
            " WHERE transect_id = %s AND deleted_at IS NULL"
            " AND ST_DWithin(geometry::geography, ST_GeomFromEWKT(%s)::geography, %s)"
            " ORDER BY geometry::geography <-> ST_GeomFromEWKT(%s)::geography, sequence_number"
            " LIMIT 1",
            [transect_id, point.ewkt, float(max_distance_m), point.ewkt],
        )
        row = cursor.fetchone()
    return row[0] if row else None


# Route proposals (T108). The phone creates them; an admin accepts or rejects them.

_TENTH = Decimal("0.1")
MIN_REJECT_NOTE_LENGTH = 10


class ProposalReviewed(exceptions.APIException):
    """A change to a proposal an admin has already accepted or rejected."""

    status_code = 409
    default_code = "proposal_reviewed"
    default_detail = "An admin has already reviewed this proposal."


class ProposalReviewError(ValueError):
    """A proposal cannot be accepted or rejected. The message is shown to the admin."""


def pull_transect_proposals(user, project):
    """The caller's own proposals in the project, deleted rows included (D-049)."""
    return TransectProposal.objects.filter(project=project, created_by=user)


def project_of_proposal(proposal):
    """`PushHandlers.project_of`."""
    return proposal.project


def guard_proposal(_user, proposal):
    """Push guard: only a pending proposal may change, even when the phone's base version is
    stale. Without it an admin's accept would turn a late phone update into a conflict."""
    if proposal.status != ProposalStatus.PENDING:
        raise ProposalReviewed


def build_new_proposal(user, proposal_id, data):
    """An unsaved proposal from a create payload."""
    # Imported here: transects.serializers imports this module (geodesic_length_m).
    from apps.transects.serializers import TransectProposalSyncSerializer

    serializer = TransectProposalSyncSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    proposal = TransectProposal(id=proposal_id, created_by=user, **serializer.validated_data)
    project = proposal.project
    if project.deleted_at is not None:
        raise exceptions.ValidationError({"project": ["This project was deleted."]})
    if not is_admin(user) and not is_member(user, project.pk):
        raise exceptions.PermissionDenied("You are not a member of this project.")
    replaced = proposal.replaces_transect
    if replaced is not None and (
        replaced.deleted_at is not None or replaced.project_id != proposal.project_id
    ):
        raise exceptions.ValidationError(
            {"replaces_transect": ["This transect was not found in the project."]}
        )
    return proposal


def apply_proposal_changes(user, proposal, data):
    """Apply an update payload to `proposal` (unsaved). Only the keys in `data` change;
    `project` and `replaces_transect` cannot."""
    from apps.transects.serializers import TransectProposalSyncSerializer

    if not is_admin(user) and not is_member(user, proposal.project_id):
        raise exceptions.PermissionDenied("You are not a member of this proposal's project.")
    serializer = TransectProposalSyncSerializer(proposal, data=data, partial=True)
    serializer.is_valid(raise_exception=True)
    changes = dict(serializer.validated_data)
    for field_name in ("project", "replaces_transect"):
        if field_name in changes:
            new_value = changes.pop(field_name)
            if getattr(new_value, "pk", None) != getattr(proposal, f"{field_name}_id"):
                raise exceptions.ValidationError({field_name: ["Cannot be changed."]})
    for field_name, value in changes.items():
        setattr(proposal, field_name, value)
    return proposal


def save_proposal(proposal, user, history_reason):
    """Check the input rules, work out `length_m`, check the table's constraints, then save with
    a history reason. The rules come first, so a bad line never reaches PostGIS."""
    errors = rules.validate_proposal(
        {
            name: getattr(proposal, name)
            for name in ("name", "reason", "geometry", "recorded_from", "recorded_to")
        }
    )
    if errors:
        raise exceptions.ValidationError(errors)
    proposal.length_m = _line_length_m(proposal.geometry)
    try:
        proposal.validate_constraints()
    except DjangoValidationError as error:
        raise exceptions.ValidationError(serializers.as_serializer_error(error)) from error
    save_with_reason(proposal, user, history_reason)
    # The trigger wrote a new server_version; the instance still holds the old one (D-029).
    proposal.refresh_from_db(fields=["server_version"])
    return proposal


def push_create_proposal(user, proposal_id, data):
    proposal = build_new_proposal(user, proposal_id, data)
    return save_proposal(proposal, user, current_push_reason())


def push_update_proposal(user, proposal, data):
    guard_proposal(user, proposal)  # a merged resend skips the framework's guard
    apply_proposal_changes(user, proposal, data)
    return save_proposal(proposal, user, current_push_reason())


def push_delete_proposal(user, proposal):
    soft_delete_pushed(proposal, user)


def _line_length_m(geometry):
    """The length of a line in metres on the WGS 84 ellipsoid, to one decimal."""
    with connection.cursor() as cursor:
        cursor.execute("SELECT ST_Length(ST_GeomFromEWKT(%s)::geography)", [geometry.ewkt])
        length = Decimal(repr(cursor.fetchone()[0]))
    return length.quantize(_TENTH, rounding=ROUND_HALF_UP)


def transect_code_taken(project_id, code):
    """True when the project has a transect with this code, deleted ones included:
    `transect_code_unique` has no `deleted_at` condition."""
    return Transect._base_manager.filter(project_id=project_id, code=code).exists()


def transect_codes_in_use(project_id):
    """`(code, deleted)` of every transect of the project, deleted ones included, by code. They
    all block `transect_code_unique`."""
    rows = Transect._base_manager.filter(project_id=project_id).order_by("code")
    return [
        (code, deleted_at is not None)
        for code, deleted_at in rows.values_list("code", "deleted_at")
    ]


def accept_proposal(proposal_id, admin, *, code, name, deactivate_replaced):
    """Make an inactive transect from a pending proposal and mark the proposal accepted.

    No visit changes. A replaced transect is only set to inactive: its line stays as it is, so
    its past visits keep their route. Returns the new transect.
    """
    with transaction.atomic():
        proposal = _pending_proposal(proposal_id)
        if transect_code_taken(proposal.project_id, code):
            raise ProposalReviewError(
                f"The project already has a transect with the code {code} "
                "(a deleted transect keeps its code)."
            )
        user_name = proposal.created_by.get_full_name() or proposal.created_by.email
        transect = Transect(
            id=uuid.uuid4(),
            project=proposal.project,
            code=code,
            name=name,
            geometry=proposal.geometry,
            active=False,
            description=(
                f"From route proposal '{proposal.name}' by {user_name}, "
                f"recorded {proposal.recorded_from:%Y-%m-%d}."
            ),
            created_by=admin,
        )
        try:
            with transaction.atomic():
                save_with_reason(transect, admin, "Created from route proposal")
        except IntegrityError as error:  # a concurrent insert of the same code
            raise ProposalReviewError(
                f"The project already has a transect with the code {code}."
            ) from error
        replaced = None
        if deactivate_replaced and proposal.replaces_transect_id is not None:
            # Locked and read again, so an edit by another admin is not overwritten. A deleted
            # transect is left alone: it is not shown to anyone, and a save would bump its
            # version and push it to the phones again.
            replaced = Transect._base_manager.select_for_update().get(
                pk=proposal.replaces_transect_id
            )
        if replaced is not None and replaced.active and replaced.deleted_at is None:
            replaced.active = False
            save_with_reason(replaced, admin, f"Replaced by transect {code} (route proposal)")
        proposal.status = ProposalStatus.ACCEPTED
        proposal.created_transect = transect
        proposal.reviewed_by = admin
        proposal.reviewed_at = timezone.now()
        save_with_reason(proposal, admin, f"Accepted: transect {code}")
    return transect


def reject_proposal(proposal_id, admin, note):
    """Reject a pending proposal with a note of at least MIN_REJECT_NOTE_LENGTH characters."""
    note = (note or "").strip()
    if len(note) < MIN_REJECT_NOTE_LENGTH:
        raise ProposalReviewError(f"Give a reason of at least {MIN_REJECT_NOTE_LENGTH} characters.")
    with transaction.atomic():
        proposal = _pending_proposal(proposal_id)
        proposal.status = ProposalStatus.REJECTED
        proposal.review_note = note
        proposal.reviewed_by = admin
        proposal.reviewed_at = timezone.now()
        save_with_reason(proposal, admin, note)
    return proposal


def _pending_proposal(proposal_id):
    """The proposal, locked for the rest of the transaction, which must still be pending."""
    proposal = (
        TransectProposal.objects.alive()
        .select_for_update(of=("self",))
        .select_related("project", "created_by", "replaces_transect")
        .filter(pk=proposal_id)
        .first()
    )
    if proposal is None:
        raise ProposalReviewError("The proposal was not found.")
    if proposal.status != ProposalStatus.PENDING:
        raise ProposalReviewError("The proposal has already been reviewed.")
    return proposal
