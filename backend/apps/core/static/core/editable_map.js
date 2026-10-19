// EditableMapWidget (T098): Django's OpenLayers MapWidget, edited one part at a time.
// A Multi* value (e.g. the project's MultiPolygon study area) is split into one feature per
// part, so a single polygon can be selected and deleted; on save the parts are joined again.
/* global ol, MapWidget */
"use strict";
{
    const cond = ol.events.condition;

    // Multi type -> the type of one part, and the OpenLayers class that joins the parts.
    const MULTI_TYPES = {
        MultiPolygon: {part: "Polygon", join: ol.geom.MultiPolygon},
        MultiLineString: {part: "LineString", join: ol.geom.MultiLineString},
        MultiPoint: {part: "Point", join: ol.geom.MultiPoint},
    };

    // A reference line or shape under the editable features (see setReference).
    const referenceStyle = new ol.style.Style({
        fill: new ol.style.Fill({color: "rgba(65, 118, 144, 0.15)"}),
        stroke: new ol.style.Stroke({color: "#417690", width: 4, lineDash: [10, 8]}),
    });

    const selectedStyle = new ol.style.Style({
        fill: new ol.style.Fill({color: "rgba(242, 177, 52, 0.35)"}),
        stroke: new ol.style.Stroke({color: "#f2b134", width: 4}),
        image: new ol.style.Circle({
            radius: 7,
            fill: new ol.style.Fill({color: "#f2b134"}),
            stroke: new ol.style.Stroke({color: "#fff", width: 2}),
        }),
    });

    class EditableMapWidget extends MapWidget {
        constructor(options) {
            super(options);
            this.multi = MULTI_TYPES[this.options.geom_name];

            // Django loaded the saved value as one Multi* feature: replace it with its parts.
            if (this.multi) {
                this.ready = false; // don't save while splitting
                for (const feature of this.featureCollection.getArray().slice()) {
                    this.featureCollection.remove(feature);
                    for (const part of partsOf(feature.getGeometry())) {
                        this.featureCollection.push(new ol.Feature(part));
                    }
                }
                this.ready = true;
            }

            // Django only saves on add and change; save on remove too (delete selected).
            this.featureCollection.on("remove", () => this.serializeFeatures());

            const wrapper = document.getElementById(this.options.map_id).parentElement;
            wrapper.editableMap = this; // lets page scripts call setReference()
            this.deleteButton = wrapper.querySelector(".delete_selected");
            if (this.deleteButton) {
                this.deleteButton.addEventListener("click", () => this.deleteSelected());
                const selected = this.interactions.select.getFeatures();
                const update = () => (this.deleteButton.disabled = selected.getLength() === 0);
                selected.on(["add", "remove"], update);
            }

            // Delete key removes the selected part, unless the admin is typing in a field.
            document.addEventListener("keydown", (event) => {
                if (event.key !== "Delete" || event.target.closest("input, textarea, select")) {
                    return;
                }
                if (this.interactions.select.getFeatures().getLength() > 0) {
                    event.preventDefault();
                    this.deleteSelected();
                }
            });
        }

        // Replaces Django's version: draw single parts, and add a Select interaction.
        // Called from MapWidget's constructor, so only `this.options` and the map exist yet.
        createInteractions() {
            const multi = MULTI_TYPES[this.options.geom_name];
            const overlay = this.featureOverlay;
            const onFeature = (event) =>
                this.map.hasFeatureAtPixel(event.pixel, {layerFilter: (layer) => layer === overlay});
            let drawing = false;

            // Click inside a part to select it (highlighted). Clicking elsewhere unselects.
            this.interactions.select = new ol.interaction.Select({
                layers: [overlay],
                style: selectedStyle,
                condition: (event) =>
                    !drawing && cond.singleClick(event) && cond.noModifierKeys(event),
                toggleCondition: cond.never,
            });

            // A click on empty map starts a new part; a click on an existing part selects it
            // instead. Once drawing, every click adds a corner. Shift + drag draws freehand
            // (OpenLayers' default freehandCondition).
            this.interactions.draw = new ol.interaction.Draw({
                features: this.featureCollection,
                type: multi ? multi.part : this.options.geom_name,
                condition: (event) => cond.noModifierKeys(event) && (drawing || !onFeature(event)),
            });
            this.interactions.draw.on("drawstart", () => {
                drawing = true;
                this.interactions.select.getFeatures().clear();
            });
            this.interactions.draw.on(["drawend", "drawabort"], () => (drawing = false));

            // Drag corners and edges to reshape; Shift + click removes a corner. Django uses the
            // same delete gesture, but by default pressing on an edge also inserts a corner (and
            // then ignores the click), so Shift + click near a corner added one. No insert
            // while Shift is held fixes that.
            this.interactions.modify = new ol.interaction.Modify({
                features: this.featureCollection,
                deleteCondition: (event) => cond.shiftKeyOnly(event) && cond.singleClick(event),
                insertVertexCondition: (event) => !cond.shiftKeyOnly(event),
            });

            // The last interaction added sees each event first.
            this.map.addInteraction(this.interactions.select);
            this.map.addInteraction(this.interactions.draw);
            this.map.addInteraction(this.interactions.modify);
        }

        // Show a read-only geometry (GeoJSON in EPSG:4326, or null to remove it) under the
        // editable features, e.g. the transect a section is drawn along. It is not saved and
        // cannot be selected; new and dragged points snap to it. The view zooms to fit it.
        setReference(geojson) {
            if (!this.reference) {
                this.reference = new ol.source.Vector();
                // A managed layer, so it renders under Django's feature overlay.
                this.map.addLayer(new ol.layer.Vector({source: this.reference, style: referenceStyle}));
                // Added after Draw and Modify, as OpenLayers requires for snapping.
                this.map.addInteraction(new ol.interaction.Snap({source: this.reference}));
            }
            this.reference.clear();
            if (!geojson) {
                return;
            }
            const geometry = new ol.format.GeoJSON().readGeometry(geojson, {
                dataProjection: "EPSG:4326",
                featureProjection: this.map.getView().getProjection(),
            });
            this.reference.addFeature(new ol.Feature(geometry));
            const extent = geometry.getExtent().slice();
            for (const feature of this.featureCollection.getArray()) {
                ol.extent.extend(extent, feature.getGeometry().getExtent());
            }
            this.map.getView().fit(extent, {padding: [40, 40, 40, 40], maxZoom: 18});
        }

        deleteSelected() {
            const selected = this.interactions.select.getFeatures();
            for (const feature of selected.getArray().slice()) {
                this.featureCollection.remove(feature);
            }
            selected.clear();
            if (this.featureCollection.getLength() === 0) {
                this.enableDrawing(); // single geometry: allow drawing a new one
            }
        }

        clearFeatures() {
            this.interactions.select.getFeatures().clear();
            super.clearFeatures();
        }

        // Writes the hidden textarea: all parts joined into one Multi* geometry, or empty
        // (the field saves NULL) when the map has no features.
        serializeFeatures() {
            const textarea = document.getElementById(this.options.id);
            const features = this.featureCollection.getArray();
            if (features.length === 0) {
                textarea.value = "";
            } else if (this.multi) {
                const geometry = new this.multi.join(
                    features.map((feature) => feature.getGeometry().getCoordinates())
                );
                textarea.value = new ol.format.GeoJSON().writeGeometry(geometry);
            } else {
                super.serializeFeatures();
            }
        }
    }

    // The single parts of a geometry (a non-multi geometry is its own only part).
    function partsOf(geometry) {
        switch (geometry.getType()) {
        case "MultiPolygon":
            return geometry.getPolygons();
        case "MultiLineString":
            return geometry.getLineStrings();
        case "MultiPoint":
            return geometry.getPoints();
        default:
            return [geometry];
        }
    }

    window.EditableMapWidget = EditableMapWidget;
}
