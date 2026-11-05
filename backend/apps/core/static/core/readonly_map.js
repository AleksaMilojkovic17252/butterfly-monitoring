/* Read-only map of a stored geometry (T052): draws the GeoJSON in the data-geojson attribute of
   every .readonly-geometry-map element on top of OpenStreetMap, and zooms to it. An optional
   data-reference-geojson is drawn first as a dashed line, like the guide line of editable_map.js
   (T108: the transect a route proposal replaces), and the map fits both. No editing. Uses
   the OpenLayers build that Django's GIS widgets already load (the page lists it in its media). */
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll(".readonly-geometry-map").forEach(function (element) {
    var geometry = new ol.format.GeoJSON().readGeometry(element.dataset.geojson, {
      dataProjection: "EPSG:4326",
      featureProjection: "EPSG:3857",
    });
    var style = new ol.style.Style({
      image: new ol.style.Circle({
        radius: 8,
        fill: new ol.style.Fill({ color: "#d32f2f" }),
        stroke: new ol.style.Stroke({ color: "#ffffff", width: 2 }),
      }),
      fill: new ol.style.Fill({ color: "rgba(46, 125, 50, 0.3)" }),
      stroke: new ol.style.Stroke({ color: "#2e7d32", width: 3 }),
    });
    var layers = [new ol.layer.Tile({ source: new ol.source.OSM() })];
    var extent = geometry.getExtent().slice();
    if (element.dataset.referenceGeojson) {
      var reference = new ol.format.GeoJSON().readGeometry(element.dataset.referenceGeojson, {
        dataProjection: "EPSG:4326",
        featureProjection: "EPSG:3857",
      });
      layers.push(
        new ol.layer.Vector({
          source: new ol.source.Vector({ features: [new ol.Feature(reference)] }),
          style: new ol.style.Style({
            stroke: new ol.style.Stroke({ color: "#417690", width: 4, lineDash: [10, 8] }),
          }),
        })
      );
      extent = ol.extent.extend(extent, reference.getExtent());
    }
    var map = new ol.Map({
      target: element,
      layers: layers.concat([
        new ol.layer.Vector({
          source: new ol.source.Vector({ features: [new ol.Feature(geometry)] }),
          style: style,
        }),
      ]),
      view: new ol.View({ center: [0, 0], zoom: 2 }),
    });
    // A point has an empty extent; fit() centres on it and maxZoom keeps it from zooming to the sky.
    function fitToGeometry() {
      map.updateSize(); // measure the box again: the admin lays the page out after this script runs
      map.getView().fit(extent, { padding: [40, 40, 40, 40], maxZoom: 18 });
    }
    fitToGeometry();
    window.addEventListener("load", fitToGeometry);
  });
});
