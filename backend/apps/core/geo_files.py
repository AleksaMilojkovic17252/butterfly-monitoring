"""Reading uploaded GIS files (GeoJSON, KML, GPX) with GDAL, for the admin import actions."""

import os
import tempfile
from contextlib import contextmanager

from django.contrib.gis.gdal import DataSource, GDALException


@contextmanager
def open_datasource(uploaded, suffixes, error):
    """Open an uploaded file as a GDAL `DataSource`; the file is deleted when the block ends.

    The suffix tells GDAL which driver to use, so only `suffixes` (lowercase, with the dot) are
    accepted. A wrong suffix or a file GDAL cannot read raises `error` (a ValueError subclass
    whose message is shown to the admin). Read the features inside the block.
    """
    suffix = os.path.splitext(uploaded.name)[1].lower()
    if suffix not in suffixes:
        names = ", ".join(suffixes[:-1]) + " or " + suffixes[-1]
        raise error(f"Upload a {names} file.")
    with tempfile.NamedTemporaryFile(suffix=suffix) as tmp:
        for chunk in uploaded.chunks():
            tmp.write(chunk)
        tmp.flush()
        try:
            yield DataSource(tmp.name)
        except GDALException as exc:
            raise error(f"Could not read the file: {exc}") from exc
