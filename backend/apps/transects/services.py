"""Transect rules and scopes. API and admin call these, not the models. Pull scopes: `pull_*`."""

from django.contrib.gis.gdal import OGRGeometry
from django.contrib.gis.geos import GEOSGeometry
from django.db import connection, transaction
from django.db.models import Count, DateTimeField, FloatField, Func, Prefetch, Q, Sum, Value

from apps.core.geo_files import open_datasource
from apps.core.history import save_with_reason
from apps.projects.services import projects_for
from apps.transects.models import Transect, TransectSection

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

    The visit fields are about the caller's own visits (admins: all visits).
    """
    return transects.annotate(
        length_m=GeodesicLength("geometry"),
        section_count=Count("sections", filter=Q(sections__deleted_at__isnull=True)),
        # TODO(T034): count and latest start of the caller's visits once SurveyVisit exists.
        visit_count=Value(0),
        last_visit_at=Value(None, output_field=DateTimeField()),
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


def utm_srid(geometry):
    """EPSG code of the WGS 84 UTM zone that holds the centre of a 4326 geometry."""
    centre = geometry.centroid
    zone = int((centre.x + 180) // 6) % 60 + 1
    return (32600 if centre.y >= 0 else 32700) + zone


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
