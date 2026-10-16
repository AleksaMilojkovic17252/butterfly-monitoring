"""Who can see which project. Pull (T025) and the API both scope through here."""

import os
import tempfile
from datetime import date

from django.contrib.gis.gdal import DataSource, GDALException, OGRGeometry
from django.contrib.gis.geos import MultiPolygon

from apps.accounts.services import is_admin
from apps.projects.models import Project, ProjectMembership, ProjectProtocol


def projects_for(user):
    """Live projects the user may see: all for admins, otherwise their memberships.

    Removing a membership drops the project from the user's next pull; rows already on the
    phone are not deleted.
    """
    projects = Project.objects.alive()
    if is_admin(user):
        return projects
    return projects.filter(memberships__user=user)


def is_member(user, project_id):
    return ProjectMembership.objects.filter(
        user=user, project_id=project_id, project__deleted_at__isnull=True
    ).exists()


def create_default_protocol(project):
    """Give a project its protocol with the defaults from docs/requirements/protocol.md.

    The season has no model default: it is 1 April - 30 September of the project's start year.
    """
    year = project.start_date.year
    protocol, _ = ProjectProtocol.objects.get_or_create(
        project=project,
        defaults={
            "season_start": date(year, 4, 1),
            "season_end": date(year, 9, 30),
            "created_by": project.created_by,
            "updated_by": project.updated_by,
        },
    )
    return protocol


class AreaFileError(ValueError):
    """The uploaded study-area file could not be used. The message is shown to the admin."""


def multipolygon_from_file(uploaded):
    """Read a GeoJSON or KML upload into one 2D MultiPolygon in EPSG:4326.

    All polygons in the file are merged. Points and lines are ignored. GDAL (via GeoDjango)
    reads both formats; the suffix tells it which driver to use.
    """
    suffix = os.path.splitext(uploaded.name)[1].lower()
    if suffix not in (".geojson", ".json", ".kml"):
        raise AreaFileError("Upload a .geojson, .json or .kml file.")
    with tempfile.NamedTemporaryFile(suffix=suffix) as tmp:
        for chunk in uploaded.chunks():
            tmp.write(chunk)
        tmp.flush()
        try:
            source = DataSource(tmp.name)
            polygons = []
            for layer in source:
                for feature in layer:
                    polygons.extend(_polygons_of(feature.geom))
        except GDALException as exc:
            raise AreaFileError(f"Could not read the file: {exc}") from exc
    if not polygons:
        raise AreaFileError("The file has no polygons.")
    return MultiPolygon(*polygons, srid=4326)


def _polygons_of(geom: OGRGeometry):
    if geom.srs is None:  # GeoJSON without a CRS is WGS 84 by definition
        geom.srid = 4326
    elif geom.srid != 4326:
        geom.transform(4326)
    geom.coord_dim = 2  # KML carries a Z of 0
    if geom.geom_type.name in ("Polygon", "MultiPolygon"):
        geos = geom.geos
        return list(geos) if geos.geom_type == "MultiPolygon" else [geos]
    return []
