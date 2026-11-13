# Synthetic monitors: from points to people with Voronoi cells

Networks of simulated PM2.5 monitors that sample a **known** exposure field, with persons to assign them to and an answer key. It is the test bed for the point-source operations of gaiaDB: the Voronoi (Thiessen) tessellation of the monitors, and the nearest-point join (see Point Sources in the [gaiaDB README](https://github.com/OHDSI/gaiaDB#point-sources-voronoi-cells-and-nearest-point-joins)). Everything is simulated; the values are not measurements of any real exposure.

```sh
python3 monitors/build_monitors.py                  # data/ (needs numpy; deterministic)
python3 monitors/build_monitor_entries.py --catalog ../gaiaCatalog/datastore/data
monitors/verify_monitors_gaia.sh                    # the Gaia joins against the answer key (needs docker; about 10 minutes on Apple Silicon)
python3 monitors/monitors_figure.py                 # the figure of the website's Examples page (needs matplotlib)
```

## The data

The field is the 1 km Gaussian random field of the [raster example](../raster/README.md) (correlation length 1 km, mean 9, SD 1.9 ug/m3) plus its trend of 0.30 ug/m3 per year in the west rising to 0.50 in the east, over the same 10 km window around downtown Los Angeles. 200 monitors are placed at random, at least 150 m apart, and the networks of **20, 60 and 200 monitors are nested** (the first *n*). A monitor reads the true field at its site plus noise (SD 0.3 ug/m3), one annual mean per year 2014 to 2019. The persons are the 500 test points of the raster example, living at the point 2014 to 2019.

| Catalog entry | What it is |
|---|---|
| `synthetic_monitors_20`, `_60`, `_200` | The monitors as a point source with an annual jsonb series (published CSV, like the tower sensors) |
| `synthetic_monitors_20_voronoi`, `_60_voronoi`, `_200_voronoi` | The Voronoi cells of each network as a polygon source, built from the point source in the postgis step with `backbone.create_voronoi_source`; the point source has to be ingested first. The ETL metadata has a proposed `derive` entry that says how it is built |

## The answer key

`data/expected_monitor_assignment.csv` has one row per network, person and year: the nearest monitor and its distance (planar, EPSG:5070), the margin to the second nearest, the monitor's reading, the true exposure at the person, the number of monitors within 1 km and 2.5 km, and the inverse-distance weighted value of the 3 nearest. `data/monitor_error_summary.csv` has the error of each way of assigning exposure against the true field:

| Monitors | One network mean | Nearest (Voronoi) | Mean within 1 km | Inverse distance, 3 nearest |
|---|---|---|---|---|
| 20 | 1.53 | 2.46 | 1.93 (211 of 500 persons have an estimate) | 2.04 |
| 60 | 1.52 | 1.79 | 1.57 (425) | 1.48 |
| 200 | 1.55 | 1.47 | 1.36 | 1.25 |

*RMSE against the true annual exposure, ug/m3, 500 persons and six years. The true exposure has an SD of 1.66.*

With the field's correlation length of 1 km, a network with monitors 2 km apart (20) says nothing about the exposure between them: the nearest monitor is worse than giving everybody the network mean (a monitor that tells nothing about the person's site has an error of about the square root of two times the field's own SD). Only when the spacing falls below the correlation length (200 monitors, median distance to the nearest monitor 359 m) does assigning the nearest monitor beat the mean, and averaging several monitors beats taking one. A 1 km buffer gives 58% of the persons of the sparse network no monitor and 99% of the dense one several.

## Checked

`verify_monitors_gaia.sh` ingests the six entries in a throwaway gaia-db container and compares with the key (500 persons, 3,000 person-years per network):

- The cells of every network cover the 100 km2 window exactly (area 100.0000 km2), are valid and do not overlap; every person is in the cell of the key's nearest monitor, with exactly the key's monitor value: 3,000 rows, none missing, none duplicated, none from another monitor, for all three networks. The cells joined with the existing `spatial_join_from_catalog` need no new join.
- The buffer join of the point sources (the only point join before): at 1 km, 289, 75 and 0 of 500 persons get no monitor and 81, 227 and 493 get several (up to 13 rows); the number of monitors differs from the key for 1, 5 and 20 persons at 1 km, because gaiaDB buffers a geography in metres and the key measures planar distances.
- `spatial_join_nearest_from_catalog` (geodesic distances) returns 3,000 rows for each network and a different monitor than the key and the cells in 6, 18 and 24 of them: persons whose two nearest monitors are almost equally far, since distances in EPSG:5070 are off by up to 0.7% depending on direction. The inverse-distance weighted value (k = 3) differs from the key by 0.009 ug/m3 on average; the largest differences (0.8 to 1.1) are, I expect, persons whose third and fourth monitor are almost equally far, which I have not checked.

The unit tests of the functions, on a small hand-checkable fixture (ties aside, since exact ties do not survive the projection), are in `tests/test_point_sources.sql` in gaiaDB.
