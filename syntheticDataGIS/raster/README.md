# Synthetic rasters

Test layers for the raster join path of gaiaDB (design question in [#537](https://github.com/OHDSI/GIS/issues/537), concept in [discussion #558](https://github.com/OHDSI/GIS/discussions/558)), with an answer key. Everything is simulated; the values are not measurements of any real exposure.

```sh
python3 raster/build_synthetic_rasters.py      # needs numpy; writes raster/data (about 0.7 MB, deterministic)
```

All layers are in EPSG:5070 over the same 10 km window around downtown Los Angeles as the vector `synthetic_surface_*` entries, with cells aligned to the origin as `ST_SquareGrid` does. GeoTIFFs are written without GDAL (uncompressed, one band).

| Layer | Cells | What it tests |
|---|---|---|
| `synthetic_raster_surface_100m` / `_1km` / `_10km` | 25 m / 250 m / 2.5 km | The **same fields** as the vector `synthetic_surface_*` grids (same random Fourier features, value at the cell centre), so raster and vector joins can be compared one to one. The cell is a quarter of the correlation length at every scale |
| `synthetic_raster_annual_2014` ... `_2019` | 250 m | One file per year: the 1 km field plus a trend of 0.30 ug/m3 per year in the west rising to 0.50 in the east (matching annual layers to residence intervals), and a 3 x 3 cell **nodata hole** (-9999) 1 km east and 1 km south of the centre |
| `synthetic_raster_landcover` | 100 m | Byte classes with NLCD codes: 11 Open Water, 21 Developed Open Space, 41 Deciduous Forest, 81 Pasture/Hay (nodata 255). Categorical values and class fractions in a buffer |

`raster_figure.py` draws the figure of the [raster example](https://ohdsi.github.io/GIS/examples.html) (`rmd/images/raster_surfaces_landcover.png`; needs numpy and matplotlib).

## Answer key

`raster_test_points.csv` has 500 seeded points inside the window, at least 1.5 km from the edge so 1 km buffers fit (`x_5070`/`y_5070` are the same points in the raster CRS). `expected_raster_values.csv` has one row per point, layer and method:

| method | meaning |
|---|---|
| `point` | The value of the cell that contains the point (what `ST_Value` should return); empty on nodata. `analytic_value` is the true field at the point itself, so the gap shows the discretisation error (mean absolute gap about 0.65 ug/m3 at every scale, because the cell is a fixed fraction of the correlation length) |
| `buffer_mean` | Mean of the cells whose **centre** lies within `radius_m` (250 and 1000 m, only where the buffer is at least one cell wide), nodata excluded |
| `class_fraction` | Land cover only: share of the valid cells in the buffer for each `class_code` |

Conventions, confirmed against PostGIS 3.5 in the gaia-db image (see below): `ST_Clip` keeps cells by their **centre**, so the key matches it exactly when the buffer circle is well approximated (`ST_Buffer(..., 'quad_segs=256')`; the default 8 segments per quarter circle leaves differences of about 0.5% in a buffer mean, up to 0.7 ug/m3 where a 250 m buffer covers only a few 250 m cells). The key uses a planar buffer in EPSG:5070, while `spatial_join_from_catalog` buffers a geography in metres, so expect a small tolerance there, not equality. Six of the points fall in the nodata hole of the annual layers (36 point rows over six years), which give no value.

## Catalog entries

`build_raster_entries.py --catalog ../gaiaCatalog/datastore/data` writes five [gaiaCatalog](https://github.com/OHDSI/gaiaCatalog) entries (JSON-LD, ETL metadata, osgeo and postgis scripts): `synthetic_raster_surface_100m`, `_1km`, `_10km`, `synthetic_raster_annual` (the six years in one table, told apart by `filename`) and `synthetic_raster_landcover`. The osgeo step downloads the GeoTIFFs from this folder on GitHub (so they must be on `main` first; `--url-base` overrides); the postgis step loads them with `raster2pgsql -s 5070 -F -t 64x64` into `public.<table_id>` (columns `rast`, `filename`). The annual entry adds a proposed `raster_layers` field to its ETL metadata (period of each file), and the land cover entry a `classes` field.

## Checked

`verify_raster_load.sh` starts a throwaway gaia-db container, serves the files from this checkout, ingests every entry with `backbone.ingest_datasource()` and compares the database with the key. Last run (PostGIS 3.5.7):

- All five entries ingest; metadata registers `geom_index` and `attr_index` rows, and the raster tables load (49 tiles for the 100 m surface, one tile for the small ones, six for the annual table).
- The origin and cell count of each surface equal the `ST_SquareGrid` cells of the vector entries, so raster and vector are cell for cell the same grid.
- `ST_Value` at the 500 points matches the key (max difference 5e-7; the 36 annual nodata points give NULL), for all layers.
- Buffer means (`ST_Clip` + `ST_SummaryStats` over tiles) and land cover class fractions match the key exactly for the first 100 points.
- With gaiaDB's raster routing and join ([`sql/07_raster_functions.sql`](https://github.com/OHDSI/gaiaDB), loaded into the container from a sibling `gaiaDB` checkout or `GAIADB_SQL`): the variables are registered by `ingest_datasource` itself (a `raster_register` step; six layers for the annual series, taken from `raster_layers` in its ETL metadata, one layer for each of the others), then one person per test point is joined with `spatial_join_raster_from_catalog`. The `point` join returns exactly the rows of the key (500 per static layer, 2,964 for the annual series, none for the nodata points) with values within 5e-7. The `buffer_mean` join differs from the key by 0.003 to 0.012 ug/m3 on average (largest single difference 0.14, with 250 m cells), because gaiaDB buffers a geography in metres and the key a planar circle in EPSG:5070.
- The `class_fraction` join on the land cover raster derives 1,458 of the 1,460 non-zero class shares of the key at 250 m and 1,996 of 1,997 at 1 km, with shares that differ by 0.004 and 0.002 on average (largest 0.059 and 0.012) and sum to 1 for every location. The few classes it does not return are in the key but not in gaiaDB's geography buffer; same buffer difference as for the means, not inspected one by one.
- GDAL reads every file with CRS EPSG:5070, the right nodata and extent; the Albers conversion matches `gdaltransform` to about 5 mm.

## Notes for the gaiaDB raster work

- `backbone.ingest_datasource` routes on the `dataRepresentation` term of the JSON-LD: for `raster` it loads the table, then registers the variables and layers (`gdsc_load_all_raster_variables`); `spatial_join_raster_from_catalog` joins them (gaiaDB `sql/05` and `sql/07`). A variable without dates now gets them by inference (year-only dates, one-sided dates, `temporalCoverage`, and for rasters the year in the name and table_id, or the static period 1900-01-01 to 2100-12-31; see the gaiaDB README, Variable dates). Checked on the metadata of the catalog's NLCD (2021), DEM (static) and VIIRS (their own year) entries; the NLCD tree cover entries had their dates and value range corrected in gaiaCatalog first (they said `startDate` 2024, `minValue` 100, `maxValue` 2021, one field off). Only the metadata load was run for these entries, not their ETL.
- `geom_index.geom_type_source_value` is `Raster Dataset` (the top-level `type`), because the geometry type is read from the `vectorGeometry` term that raster entries do not have. Routing therefore uses `dataRepresentation`, which is the cleaner signal.
- `raster2pgsql` pads a raster smaller than the tile to the tile size with nodata; the origin is unchanged.

## Next

Writing the design up on #537.
