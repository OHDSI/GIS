# Nearest-point join: timing (#536)

`working.spatial_join_nearest_from_catalog` (gaiaDB `sql/08`) assigns every location the value of its nearest point. `bench_nearest.sql` times it on random points and persons: `npts` monitors with three annual values, `nloc` persons living at one location for the three years (so 3 x `nloc` rows come out), uniform in a 100 km x 100 km window near Los Angeles.

```sh
docker exec <gaia-db container> psql -U postgres -d gaiacore -At -F' ' -v npts=10000 -v nloc=10000 -f bench_nearest.sql   # npts nloc k seconds rows
```

## Results (k = 1)

Seconds for the join call (the first call on a point table also builds its spatial index, included), gaiaDB working tree of 2026-11-17 on the `ohdsi/gaia-db:main` image, emulated linux/amd64 on Apple Silicon (see the baseline README for what that does to absolute times). One run each.

| Points | 1,000 persons | 10,000 persons | 100,000 persons |
|---|---|---|---|
| 200 | 0.2 | 1.3 | 12.5 |
| 10,000 | 0.4 | 2.4 | 21.2 |
| 100,000 | 1.5 | 9.6 | 639 |

The version of 2026-11-13 compared every person with every point (no spatial index on the geometry tables, which `CREATE TABLE ... AS TABLE` does not copy from the template):

| Points | 1,000 persons | 10,000 persons |
|---|---|---|
| 200 | 1.7 | 20.3 |
| 10,000 | 91.9 | over 240 (stopped) |
| 100,000 | over 240 (stopped) | over 240 (stopped) |

## What changed, and what is not explained

- `gdsc_load_variable` now creates a GiST index on the geometry of every `working.geom_*` table and a btree on the attribute table; this also helps `spatial_join_from_catalog`, which had no spatial index either.
- The nearest join ranks with the k-nearest-neighbour operator on a geography index (created on first use). Two things kept the planner from using it, found with `EXPLAIN ANALYZE`: a second sort key (the tie-break on `geom_record_id`) and `COALESCE` on the window dates in the join condition. Both are gone; exact ties between two points at the same distance now go either way.
- The time grows with persons, not with points, up to 10,000 points. **100,000 points with 100,000 persons (639 s) is far worse than the trend of the other cells** (about 2 ms per person and year, against 0.3 ms for 10,000 persons). I have not looked into why: the join is the same query, so the suspects are the sort and aggregation of the 300,000 result rows and the memory of the emulated container. It was not run on native hardware, or more than once, and other work was running in the same container for part of it.
- Not measured: k > 1, `max_distance_m`, real layers (the California roads of the baseline), the other joins (`spatial_join_from_catalog`, raster) at this scale, native hardware.
