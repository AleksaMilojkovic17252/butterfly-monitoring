// Read-only route map on the visit page (T036): the track as a solid line over the transect
// line, dashed in the same style as the reference line of editable_map.js. Pan and zoom only.
/* global ol */
"use strict";
{
    const routeStyle = new ol.style.Style({
        stroke: new ol.style.Stroke({color: "#c2255c", width: 3}),
    });
    const transectStyle = new ol.style.Style({
        stroke: new ol.style.Stroke({color: "#417690", width: 4, lineDash: [10, 8]}),
    });

    function layerOf(scriptId, style, format) {
        const geojson = JSON.parse(document.getElementById(scriptId).textContent);
        const source = new ol.source.Vector();
        if (geojson) {
            const geometry = format.readGeometry(geojson, {
                dataProjection: "EPSG:4326",
                featureProjection: "EPSG:3857",
            });
            source.addFeature(new ol.Feature(geometry));
        }
        return new ol.layer.Vector({source, style});
    }

    function drawRouteMap(element) {
        const format = new ol.format.GeoJSON();
        const transect = layerOf(element.dataset.transectId, transectStyle, format);
        const route = layerOf(element.dataset.routeId, routeStyle, format);
        const map = new ol.Map({
            target: element,
            layers: [new ol.layer.Tile({source: new ol.source.OSM()}), transect, route],
            view: new ol.View(),
        });
        const extent = route.getSource().getExtent();
        ol.extent.extend(extent, transect.getSource().getExtent());
        map.getView().fit(extent, {padding: [30, 30, 30, 30], maxZoom: 18});
    }

    document.addEventListener("DOMContentLoaded", () => {
        document.querySelectorAll(".route_map").forEach(drawRouteMap);
    });
}
