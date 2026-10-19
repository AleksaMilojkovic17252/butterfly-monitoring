// Transect form (T022): every section map in the sections inline shows the whole transect as
// a dashed line, so it is clear which stretch the section covers. The line is read from the
// transect's own map, so it follows edits made on this page before saving.
/* global ol */
"use strict";
document.addEventListener("DOMContentLoaded", () => {
    const main = document.getElementById("id_geometry_div_map");
    const transect = main && main.editableMap;
    const group = document.getElementById("sections-group");
    if (!transect || !group) {
        return;
    }
    const sectionMaps = () =>
        Array.from(group.querySelectorAll(".editable_map"))
            .map((wrapper) => wrapper.editableMap)
            .filter(Boolean);

    // The transect's line as GeoJSON in EPSG:4326, or null while the map is empty.
    function transectLine() {
        const features = transect.featureCollection.getArray();
        if (features.length === 0) {
            return null;
        }
        return new ol.format.GeoJSON().writeGeometryObject(features[0].getGeometry(), {
            dataProjection: "EPSG:4326",
            featureProjection: transect.map.getView().getProjection(),
        });
    }

    const showLine = (fit) => {
        const line = transectLine();
        for (const widget of sectionMaps()) {
            widget.setReference(line, fit);
        }
    };

    // Redraw the dashed line when the transect's line is drawn, reshaped or removed.
    // The views are left alone then: the admin may be looking at a section.
    const update = () => showLine(false);
    transect.featureCollection.on(["add", "remove"], update);
    transect.interactions.modify.on("modifyend", update);

    // The maps are inside a closed <details>, laid out at zero size, so zoom them when it opens.
    const fitAll = () => {
        for (const widget of sectionMaps()) {
            widget.map.updateSize();
            widget.fitReference();
        }
    };
    const details = group.querySelector("details");
    if (details) {
        details.addEventListener("toggle", () => details.open && fitAll());
    }
    showLine(true);
});
