"""Writes the transects as a GPX 1.1 file for the GPS replay (T071 feeds T072)."""

import xml.etree.ElementTree as ET
from datetime import UTC, datetime, timedelta

from .walk import LineWalker, clean_track

NAMESPACE = "http://www.topografix.com/GPX/1/1"
REPLAY_START = datetime(2026, 5, 1, 8, 0, tzinfo=UTC)  # fixed, so the file is reproducible


def write_gpx(path, transects, interval_s):
    """One `<trk>` per transect (named by its code), walked at 1 m/s without noise."""
    ET.register_namespace("", NAMESPACE)
    root = ET.Element(
        f"{{{NAMESPACE}}}gpx", {"version": "1.1", "creator": "simulate_season (T071)"}
    )
    for transect in transects:
        track = ET.SubElement(root, f"{{{NAMESPACE}}}trk")
        ET.SubElement(track, f"{{{NAMESPACE}}}name").text = transect.code
        segment = ET.SubElement(track, f"{{{NAMESPACE}}}trkseg")
        for seconds, lon, lat in clean_track(LineWalker(transect.geometry), interval_s):
            point = ET.SubElement(
                segment, f"{{{NAMESPACE}}}trkpt", {"lat": f"{lat:.7f}", "lon": f"{lon:.7f}"}
            )
            moment = REPLAY_START + timedelta(seconds=seconds)
            ET.SubElement(point, f"{{{NAMESPACE}}}time").text = moment.strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            )
    ET.indent(root)
    path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(path, encoding="utf-8", xml_declaration=True)
