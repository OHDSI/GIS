# Nearest-point join: timing (#536)

`working.spatial_join_nearest_from_catalog` (gaiaDB `sql/08`) assigns every location the value of its nearest point. `bench_nearest.sql` times it on random points and persons: `npts` monitors with three annual values, `nloc` persons living at one location for the three years (so 3 x `nloc` rows come out), uniform in a 100 km x 100 km window near Los Angeles. `bench_roads.sh` times it on a real layer.

```sh
docker exec <gaia-db container> psql -U postgres -d gaiacore -At -F' ' -v npts=10000 -v nloc=10000 -f bench_nearest.sql   # npts nloc k seconds rows
```

Every run rolls back, but a rolled-back run leaves dead rows in `working.location*`: run `VACUUM ANALYZE working.location, working.location_history, working.external_exposure` between runs, or use a fresh container (see the correction below).

## Results, random points (k = 1)

Seconds for the join call (the first call on a point table also builds its spatial index, included), gaiaDB working tree of 2026-11-17 on the `ohdsi/gaia-db:main` image, emulated linux/amd64 on Apple Silicon (see the baseline README for what that does to absolute times). One run each, fresh container, `VACUUM ANALYZE` between runs.

| Points | 1,000 persons | 10,000 persons | 100,000 persons |
|---|---|---|---|
| 200 | 0.14 | 1.3 | 15 |
| 10,000 | 0.56 | 2.9 | 26 |
| 100,000 | 1.8 | 4.4 | 36 |

At 10,000 points and 10,000 persons: k = 3 (inverse-distance weighted) 3.3 s, k = 1 with `max_distance_m` = 1,000 1.2 s (28,542 of the 30,000 rows have a monitor within 1 km).

The version of 2026-11-13 compared every person with every point (no spatial index on the geometry tables, which `CREATE TABLE ... AS TABLE` does not copy from the template). Same harness, same conditions:

| Points | 1,000 persons | 10,000 persons |
|---|---|---|
| 200 | 1.6 | 14.3 |
| 10,000 | 88 | not run (an earlier run was stopped at 240 s) |
| 100,000 | not run (an earlier run was stopped at 240 s) | not run (stopped at 240 s) |

## Results, a real layer: the primary and secondary roads of California

7,403 line features of `us_2019_prisecroads_tl` (TIGER 2019), loaded with `ingest_datasource`, one numeric attribute (the length of the road in metres, one window 2014-2019). Persons are uniform random points in the extent of the roads, so many are far from any road (the worst case for a nearest search). `bench_roads.sh`. Same conditions as above.

| Persons | k = 1 | seconds per person |
|---|---|---|
| 1,000 | 4.4 | 4.4 ms |
| 10,000 | 41 | 4.1 ms |
| 100,000 | 396 | 4.0 ms |

At 10,000 persons: k = 3 takes 59 s; k = 1 with `max_distance_m` = 5,000 takes 15 s (2,068 persons have a road within 5 km).

The time grows linearly with persons, but a person costs about ten times more against these roads than against monitors (4 ms against 0.3 ms per person and year at 10,000 points), because the distance to a long line with many vertices is expensive. A distance limit prunes it well.

## Correction: an earlier 639 s result is withdrawn

A first run of the grid reported 639 s for 100,000 persons against 100,000 points. It was not reproduced: the same query ran in 31 s (select only) and 34 s (the whole harness) in a fresh container, and 36 s in the grid above. The first container had already run many rolled-back 100,000-person runs, which leave dead rows in `working.location*` and `external_exposure`; I have not proved that this was the cause, but the result went away with a clean container and `VACUUM ANALYZE` between runs, and I have not seen it since. The timings of the 2026-11-13 version above were measured under better conditions than the first grid, so some earlier numbers (the 92 s for 10,000 points and 1,000 persons) differ slightly.

## What changed in the join, and what is not measured

- `gdsc_load_variable` now creates a GiST index on the geometry of every `working.geom_*` table and a btree on the attribute table; this also helps `spatial_join_from_catalog`, which had no spatial index either.
- The nearest join ranks with the k-nearest-neighbour operator on a geography index (created on first use). Two things kept the planner from using it, found with `EXPLAIN ANALYZE`: a second sort key (the tie-break on `geom_record_id`) and `COALESCE` on the window dates in the join condition. Both are gone; exact ties between two points at the same distance now go either way.
- Without the attribute index (a database loaded by an older `gdsc_load_variable`), the planner joins the attribute table by scanning it for every probe at 100,000 points. Databases loaded before this change need `CREATE INDEX ... ON working.attr_<table> (attr_index_id, geom_record_id, attr_start_date)`, or a reload.
- Not measured: native hardware, repeated runs (one each), the other joins (`spatial_join_from_catalog`, raster) at this scale, a real point layer (the roads are lines).
