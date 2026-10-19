"""Transect rules and scopes. API, admin and pull (T025) call these, not the models."""

from django.db import connection
from django.db.models import Count, DateTimeField, FloatField, Func, Prefetch, Q, Value

from apps.projects.services import projects_for
from apps.transects.models import Transect, TransectSection

# How far (metres) any point of a section may be from its transect line.
SECTION_TOLERANCE_M = 5.0


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
    """Live sections of `transects_for(user)`. The pull (T025) sends these to the phone."""
    return TransectSection.objects.alive().filter(transect__in=transects_for(user))


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
