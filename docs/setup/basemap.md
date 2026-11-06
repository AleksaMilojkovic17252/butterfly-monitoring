# Offline basemap (MBTiles)

T060, D-102. A project can have an **offline basemap**: one MBTiles file that an admin uploads and the phones download
with the project. The app draws it on every map, over the OpenStreetMap tiles. Without the file the maps work as before
(OSM tiles online, the ones already seen from the cache).

## What source is allowed

The tiles must come from data you may copy and use offline:

- **An OpenStreetMap extract** from [Geofabrik](https://download.geofabrik.de/) that you style yourself in QGIS. The data is
  ODbL: keep the credit "© OpenStreetMap contributors" where the map is shown or published.
- **An open orthophoto** whose licence allows offline copies (check it; many national portals do, some do not).
  Write the licence and the credit in the project description.

**Not allowed:** tiles saved from OpenStreetMap's tile servers, Google, Bing or any other tile server. That includes adding an
XYZ layer to QGIS and exporting it: the tile usage policies forbid bulk downloads, and the export would be exactly that.

## Make the file in QGIS

1. Load the data: the Geofabrik extract (open the `.gpkg` or `.shp` layers you need: roads, water, land use, buildings) and
   style it, or the orthophoto raster.
2. Zoom to the project area plus a small buffer (a few hundred metres). The smaller the area, the smaller the file.
3. *Processing → Toolbox → Raster tools → Generate XYZ tiles (MBTiles)*:
   - Extent: *Calculate from layer* or *Draw on canvas* (the area from step 2).
   - Minimum zoom **12**, maximum zoom **18**.
   - DPI 96, tile format **PNG** for a styled map, **JPG** for an orthophoto (smaller).
   - Tile width and height **256**.
   - Save to file: `something.mbtiles`.
4. Check the size. Typical: 20-80 MB for a few km². The admin refuses a file over 200 MB (nginx limit); lower the maximum
   zoom to 17 or shrink the extent if you are over.

The file must be a **raster** MBTiles (PNG, JPG or WebP tiles) with a `tiles` table and a `metadata` table that has the rows
`name` and `format`. The admin checks this when you upload.

## Upload and use

1. Admin → Projects → the project → **Basemap** → choose the file → Save. The page shows the size and the SHA-256 after saving.
   "Clear" removes the basemap from the project (the old file stays in MinIO, like replaced photos).
2. Saving the project makes phones show **Outdated** on the project card.
3. On the phone, tap **Update** (or **Download** for a project that is not loaded yet). The button shows the file size, for
   example **Update (48 MB)**, so you can choose Wi-Fi first. The download has a progress bar and can be cancelled.
   The automatic sync never downloads the file.
4. Open any map. In airplane mode the MBTiles tiles still show. Outside the file's area the cached OSM tiles show, or a plain
   background.

A new upload replaces the file on the phone at the next Update. "Remove all local data" in Settings deletes the file; logout keeps it.
