"""Who can see which project. The API and the pull's project check (T025) scope through here."""

import hashlib
import sqlite3
import tempfile
from datetime import date

from django.contrib.gis.gdal import OGRGeometry
from django.contrib.gis.geos import MultiPolygon
from django.core.exceptions import ValidationError

from apps.accounts.services import is_admin
from apps.core.geo_files import open_datasource
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


def pull_projects(_user, project):
    """The project itself, deleted rows included, so tombstones reach the phone."""
    return Project.objects.filter(pk=project.pk)


def pull_protocols(_user, project):
    """The project's protocol, deleted rows included, so tombstones reach the phone."""
    return ProjectProtocol.objects.filter(project=project)


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
    polygons = []
    with open_datasource(uploaded, (".geojson", ".json", ".kml"), AreaFileError) as source:
        for layer in source:
            for feature in layer:
                polygons.extend(_polygons_of(feature.geom))
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


SQLITE_HEADER = b"SQLite format 3\x00"
MAX_BASEMAP_BYTES = 200 * 1024 * 1024  # the same limit as nginx's for the project admin
RASTER_FORMATS = {"png", "jpg", "jpeg", "webp"}


def inspect_basemap(uploaded):
    """Check an uploaded MBTiles file and return `(size in bytes, sha256 hex)` (T060, D-102).

    It must be named `*.mbtiles`, be a SQLite file of at most 200 MB, and have a `tiles` table and
    raster metadata. The upload is read once, in 1 MiB chunks, into a temporary file so SQLite can
    open it. Raises ValidationError.
    """
    if not uploaded.name.lower().endswith(".mbtiles"):
        raise ValidationError("The basemap must be a .mbtiles file.")
    digest = hashlib.sha256()
    size = 0
    with tempfile.NamedTemporaryFile(suffix=".mbtiles") as copy:
        uploaded.seek(0)
        for chunk in uploaded.chunks(1024 * 1024):
            if size == 0 and not chunk.startswith(SQLITE_HEADER):
                raise ValidationError("This is not an MBTiles (SQLite) file.")
            digest.update(chunk)
            copy.write(chunk)
            size += len(chunk)
            if size > MAX_BASEMAP_BYTES:
                raise ValidationError("The basemap is larger than 200 MB.")
        copy.flush()
        if size == 0:
            raise ValidationError("The file is empty.")
        _check_mbtiles(copy.name)
    uploaded.seek(0)  # the storage reads it again
    return size, digest.hexdigest()


def _check_mbtiles(path):
    """Raise ValidationError unless the SQLite file at `path` has what the phone needs.

    That is a `tiles` table and a `metadata` table with the rows `name` and `format` (the app's
    MBTiles package refuses a file without them), and a raster `format`: PNG, JPG or WebP. A
    vector file (`pbf`) would open but draw nothing.
    """
    try:
        connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
        try:
            tables = {
                row[0]
                for row in connection.execute(
                    "SELECT name FROM sqlite_master WHERE type IN ('table', 'view')"
                )
            }
            if "tiles" not in tables:
                raise ValidationError(
                    "The file has no 'tiles' table, so it is not an MBTiles file."
                )
            if "metadata" not in tables:
                raise ValidationError("The file has no 'metadata' table.")
            metadata = dict(connection.execute("SELECT name, value FROM metadata"))
        finally:
            connection.close()
    except sqlite3.DatabaseError as error:
        raise ValidationError("This is not a readable MBTiles file.") from error
    missing = {"name", "format"} - metadata.keys()
    if missing:
        raise ValidationError(
            f"The metadata table has no {' or '.join(sorted(missing))} row, which the app needs."
        )
    tile_format = str(metadata["format"]).lower()
    if tile_format not in RASTER_FORMATS:
        raise ValidationError(
            f"The tile format is '{tile_format}'. Only raster basemaps (png, jpg, webp) work."
        )


def set_basemap(project, uploaded, user=None):
    """Attach an MBTiles file to a project: the same steps as the admin form (T060).

    For shell use; the admin calls `inspect_basemap` in its form and sets the fields itself.
    """
    project.basemap_size, project.basemap_sha256 = inspect_basemap(uploaded)
    project.basemap = uploaded
    if user is not None:
        project.updated_by = user
    project.save()
