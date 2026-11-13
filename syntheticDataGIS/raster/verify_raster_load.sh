#!/usr/bin/env bash
# Loads the synthetic raster catalog entries into a throwaway gaiaDB container and checks them against the answer key:
# ingest through backbone.ingest_datasource, grid alignment against ST_SquareGrid, ST_Value at the test points,
# buffer means (ST_Clip + ST_SummaryStats) and land cover class fractions. Needs docker and python3 (+ numpy).
#
#   raster/verify_raster_load.sh [--keep]      # --keep leaves the container running (gaia-raster-test)
#
# The files are served from this checkout over http, so nothing has to be pushed first.
# The raster functions (sql/07_raster_functions.sql) and the raster routing of ingest_datasource (sql/05) of gaiaDB are loaded
# from GAIADB_SQL (default ../../../gaiaDB/sql next to this checkout) before the ingest, when the image does not have them yet;
# set GAIADB_SQL=none to use the image as it is and skip the join checks.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAIA_DB_IMAGE="${GAIA_DB_IMAGE:-ohdsi/gaia-db:main}"
CONTAINER=gaia-raster-test
DB=gaiacore; DBUSER=postgres
PORT="${PORT:-8099}"
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1
GAIADB_SQL="${GAIADB_SQL:-$HERE/../../../gaiaDB/sql}"

WORK="$(mktemp -d)"
cleanup() {
  [ -n "${HTTP_PID:-}" ] && kill "$HTTP_PID" 2>/dev/null || true
  [ "$KEEP" = 1 ] || docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
dbpsql() { docker exec -i -e PGOPTIONS="-c client_min_messages=warning" "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q "$@"; }

echo "==> rasters and catalog entries"
python3 "$HERE/build_synthetic_rasters.py" --out "$HERE/data" >/dev/null
mkdir -p "$WORK/data" "$WORK/secrets"
python3 "$HERE/build_raster_entries.py" --catalog "$WORK/data" --url-base "http://host.docker.internal:$PORT" >/dev/null
chmod -R a+rwX "$WORK/data"
printf 'gaia-raster-test' > "$WORK/secrets/PG_PASSWORD"; printf 'gaia-raster-test' > "$WORK/secrets/AUTH_PASSWORD"
for f in CDC_APP_TOKEN AIRNOW_API_KEY USGS_USER USGS_PASSWORD CENSUS_API_KEY COPERNICUS_KEY; do : > "$WORK/secrets/$f"; done
chmod -R a+rX "$WORK/secrets"
(cd "$HERE/data" && exec python3 -m http.server "$PORT" --bind 0.0.0.0 >/dev/null 2>&1) & HTTP_PID=$!

echo "==> gaiaDB container ($GAIA_DB_IMAGE)"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER" --hostname gaia-db --platform linux/amd64 --user postgres:postgres \
  --add-host host.docker.internal:host-gateway \
  -e POSTGRES_USER="$DBUSER" -e PGUSER="$DBUSER" -e POSTGRES_DB="$DB" -e PGDATABASE="$DB" \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/PG_PASSWORD -e PG_PASSWORD_FILE=/run/secrets/PG_PASSWORD \
  -e AUTHENTICATOR_PASSWORD_FILE=/run/secrets/AUTH_PASSWORD -e INIT_WITH_DATASOURCE_MOUNT=TRUE -e POSTGRES_PORT=5432 -e PGPORT=5432 \
  -e GAIA_COPERNICUS_KEY_FILE=/run/secrets/COPERNICUS_KEY -e USGS_USER_FILE=/run/secrets/USGS_USER -e USGS_PASSWORD_FILE=/run/secrets/USGS_PASSWORD \
  -e CDC_APP_TOKEN_FILE=/run/secrets/CDC_APP_TOKEN -e AIRNOW_API_KEY_FILE=/run/secrets/AIRNOW_API_KEY -e CENSUS_API_KEY_FILE=/run/secrets/CENSUS_API_KEY \
  -v "$WORK/data":/data -v "$WORK/secrets":/run/secrets:ro "$GAIA_DB_IMAGE" >/dev/null
echo -n "   waiting for the database"
for _ in $(seq 1 120); do
  if docker exec "$CONTAINER" pg_isready -h 127.0.0.1 -U "$DBUSER" -d "$DB" >/dev/null 2>&1 \
     && [ "$(dbpsql -At -c "SELECT count(*) FROM pg_proc WHERE proname='ingest_datasource'" 2>/dev/null || echo 0)" -ge 1 ]; then echo " - ready"; break; fi
  echo -n "."; sleep 5
done
dbpsql -At -c "SELECT PostGIS_Full_Version()" | head -c 200; echo

if [ "$GAIADB_SQL" != none ] && [ -f "$GAIADB_SQL/07_raster_functions.sql" ]; then
  echo "==> gaiaDB raster functions from $GAIADB_SQL"
  for f in 07_raster_functions 05_data_source_retrieval_functions; do
    docker cp "$GAIADB_SQL/$f.sql" "$CONTAINER":/tmp/$f.sql
    docker exec "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q -f /tmp/$f.sql
  done
fi

TABLES="synthetic_raster_surface_100m synthetic_raster_surface_1km synthetic_raster_surface_10km synthetic_raster_annual synthetic_raster_landcover"
echo "==> ingest"
for t in $TABLES; do
  echo "-- $t"
  dbpsql -At -F ' | ' -c "SELECT * FROM backbone.ingest_datasource('$t')" || die "ingest of $t failed"
done

echo "==> answer key and points"
dbpsql <<'SQL'
CREATE TABLE tp (point_id int PRIMARY KEY, lon double precision, lat double precision, x double precision, y double precision);
CREATE TABLE ek (point_id int, layer text, year text, method text, radius_m int, class_code text, value double precision, analytic_value double precision);
SQL
tail -n +2 "$HERE/data/raster_test_points.csv" | dbpsql -c "\\copy tp FROM STDIN WITH (FORMAT csv)"
tail -n +2 "$HERE/data/expected_raster_values.csv" | dbpsql -c "\\copy ek FROM STDIN WITH (FORMAT csv)"

echo "==> tables"
for t in $TABLES; do
  dbpsql -At -F ' | ' -c "SELECT '$t', count(*) AS tiles, min(ST_SRID(rast)), min(ST_UpperLeftX(rast)), max(ST_UpperLeftY(rast)), min(ST_ScaleX(rast)), count(DISTINCT filename) AS files FROM public.$t"
done

echo "==> grid alignment against ST_SquareGrid (the raster's origin must equal the corner of the first grid cell; cell counts must agree)"
for spec in "100m 25" "1km 250" "10km 2500"; do
  set -- $spec
  dbpsql -At -F ' | ' -c "
  WITH g AS (SELECT min(ST_XMin(geom)) x0, max(ST_YMax(geom)) ytop, count(*) n
             FROM ST_SquareGrid($2, ST_Expand(ST_Transform(ST_SetSRID(ST_MakePoint(-118.25, 34.05), 4326), 5070), 5000)) geom),
       r AS (SELECT min(ST_UpperLeftX(rast)) x0, max(ST_UpperLeftY(rast)) ytop, sum((ST_SummaryStats(rast)).count) n FROM public.synthetic_raster_surface_$1)
  SELECT '$1', g.x0, r.x0, g.ytop, r.ytop, g.n AS grid_cells, r.n AS raster_cells_with_data,
         CASE WHEN abs(g.x0 - r.x0) < 1e-6 AND abs(g.ytop - r.ytop) < 1e-6 AND g.n = r.n THEN 'aligned' ELSE 'NOT ALIGNED' END FROM g, r"
done

echo "==> ST_Value at the test points vs the key (tolerance 1e-4; nodata must give NULL)"
for t in $TABLES; do
  dbpsql -At -F ' | ' -c "
  SELECT '$t', count(*) AS n, count(*) FILTER (WHERE v IS NULL) AS null_values, count(*) FILTER (WHERE k.value IS NULL) AS key_null,
         count(*) FILTER (WHERE v IS DISTINCT FROM k.value AND NOT (k.value IS NOT NULL AND v IS NOT NULL AND abs(v - k.value) < 1e-4)) AS mismatches,
         max(abs(v - k.value)) AS max_diff
  FROM tp p
  JOIN ek k ON k.point_id = p.point_id AND k.method = 'point' AND k.layer LIKE '$t%'
  JOIN public.$t r ON r.filename = k.layer || '.tif' AND ST_Intersects(r.rast, ST_SetSRID(ST_MakePoint(p.x, p.y), 5070))
  CROSS JOIN LATERAL (SELECT ST_Value(r.rast, 1, ST_SetSRID(ST_MakePoint(p.x, p.y), 5070)) AS v) q(v)"
done

echo "==> buffer means (ST_Clip + ST_SummaryStats over tiles) vs the key, first 100 points"
for t in synthetic_raster_surface_100m synthetic_raster_surface_1km synthetic_raster_annual; do
  dbpsql -At -F ' | ' -c "
  SELECT k.layer, k.radius_m, count(*) AS n, round(max(abs(m - k.value))::numeric, 6) AS max_diff, round(avg(abs(m - k.value))::numeric, 6) AS avg_diff,
         count(*) FILTER (WHERE abs(m - k.value) > 1e-3) AS differ
  FROM ek k JOIN tp p USING (point_id)
  CROSS JOIN LATERAL (SELECT ST_Buffer(ST_SetSRID(ST_MakePoint(p.x, p.y), 5070), k.radius_m, 'quad_segs=256') AS b) bb
  CROSS JOIN LATERAL (SELECT sum((st).sum) / nullif(sum((st).count), 0) AS m FROM (
        SELECT ST_SummaryStats(ST_Clip(r.rast, 1, bb.b, true)) AS st FROM public.$t r
        WHERE r.filename = k.layer || '.tif' AND ST_Intersects(r.rast, bb.b)) s) agg
  WHERE k.method = 'buffer_mean' AND k.layer LIKE '$t%' AND k.point_id <= 100 AND (k.layer NOT LIKE '%annual%' OR k.layer LIKE '%2016')
  GROUP BY k.layer, k.radius_m ORDER BY 1, 2"
done

echo "==> land cover class fractions in a 1 km buffer vs the key, first 100 points"
dbpsql -At -F ' | ' -c "
SELECT k.class_code, count(*) AS n, round(max(abs(coalesce(f.frac, 0) - k.value))::numeric, 6) AS max_diff
FROM ek k JOIN tp p USING (point_id)
CROSS JOIN LATERAL (SELECT ST_Buffer(ST_SetSRID(ST_MakePoint(p.x, p.y), 5070), k.radius_m, 'quad_segs=256') AS b) bb
CROSS JOIN LATERAL (
  SELECT sum(vc.count) FILTER (WHERE vc.value = k.class_code::int)::double precision / sum(vc.count) AS frac
  FROM (SELECT (ST_ValueCount(ST_Clip(r.rast, 1, bb.b, true), 1, true)).* FROM public.synthetic_raster_landcover r WHERE ST_Intersects(r.rast, bb.b)) vc) f
WHERE k.method = 'class_fraction' AND k.radius_m = 1000 AND k.layer = 'synthetic_raster_landcover' AND k.point_id <= 100
GROUP BY k.class_code ORDER BY 1"
if [ "$GAIADB_SQL" != none ]; then
echo "==> raster join (gaiaDB sql/07_raster_functions.sql)"
echo "-- registered by ingest_datasource (layers: one per file for the annual series, one for the others)"
dbpsql -At -F ' | ' -c "SELECT ai.table_name, ai.variable_name, count(rl.*) AS layers, min(rl.start_date), max(rl.end_date)
                        FROM backbone.attr_index ai LEFT JOIN backbone.raster_layer rl USING (attr_index_id)
                        WHERE ai.table_name LIKE 'synthetic_raster%' GROUP BY 1, 2 ORDER BY 1"
# one person per test point, living at the point from 2014 to 2019
dbpsql <<'SQL'
INSERT INTO working.location (location_id, geom, longitude, latitude)
SELECT point_id, g, ST_X(g), ST_Y(g) FROM (SELECT point_id, ST_Transform(ST_SetSRID(ST_MakePoint(x, y), 5070), 4326) AS g FROM tp) t;
INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date)
SELECT point_id, 2052496995, 1147314, point_id, DATE '2014-01-01', DATE '2019-12-31' FROM tp;
SQL
echo "-- point join: rows and values vs the key (missing = in the key but not derived, extra = derived but not in the key)"
for t in $TABLES; do
  var="$(dbpsql -At -c "SELECT variable_name FROM backbone.attr_index WHERE table_name = '$t'")"
  dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_raster_from_catalog('$var', '$t', 'point', 0, 2052499878)" >/dev/null
  dbpsql -At -F ' | ' -c "
  WITH ee AS (SELECT person_id, CASE WHEN '$t' = 'synthetic_raster_annual' THEN extract(year FROM exposure_start_date)::int::text END AS yr, value_as_number::float8 AS v FROM working.external_exposure),
       k AS (SELECT point_id, year AS yr, value FROM ek WHERE method = 'point' AND layer LIKE '$t%' AND value IS NOT NULL)
  SELECT '$t', (SELECT count(*) FROM k) AS expected, (SELECT count(*) FROM ee) AS derived,
         (SELECT count(*) FROM k WHERE NOT EXISTS (SELECT 1 FROM ee WHERE ee.person_id = k.point_id AND ee.yr IS NOT DISTINCT FROM k.yr)) AS missing,
         (SELECT count(*) FROM ee WHERE NOT EXISTS (SELECT 1 FROM k WHERE ee.person_id = k.point_id AND ee.yr IS NOT DISTINCT FROM k.yr)) AS extra,
         (SELECT max(abs(ee.v - k.value)) FROM ee JOIN k ON ee.person_id = k.point_id AND ee.yr IS NOT DISTINCT FROM k.yr) AS max_diff"
done
echo "-- buffer_mean join (geography buffer in metres) vs the key (planar buffer in EPSG:5070): small differences are expected"
for spec in "synthetic_raster_surface_100m 250" "synthetic_raster_surface_100m 1000" "synthetic_raster_surface_1km 1000" "synthetic_raster_annual 1000"; do
  set -- $spec; t=$1; r=$2
  var="$(dbpsql -At -c "SELECT variable_name FROM backbone.attr_index WHERE table_name = '$t'")"
  dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_raster_from_catalog('$var', '$t', 'buffer_mean', $r, 2052499878)" >/dev/null
  dbpsql -At -F ' | ' -c "
  WITH ee AS (SELECT person_id, CASE WHEN '$t' = 'synthetic_raster_annual' THEN extract(year FROM exposure_start_date)::int::text END AS yr, value_as_number::float8 AS v FROM working.external_exposure),
       k AS (SELECT point_id, year AS yr, value FROM ek WHERE method = 'buffer_mean' AND radius_m = $r AND layer LIKE '$t%' AND value IS NOT NULL)
  SELECT '$t', $r, count(*) AS compared, (SELECT count(*) FROM k) AS expected, (SELECT count(*) FROM ee) AS derived,
         round(avg(abs(ee.v - k.value))::numeric, 5) AS avg_diff, round(max(abs(ee.v - k.value))::numeric, 4) AS max_diff
  FROM ee JOIN k ON ee.person_id = k.point_id AND ee.yr IS NOT DISTINCT FROM k.yr"
done
echo "-- class_fraction join vs the key (classes with share 0 are not derived; missing = in the key but not derived, extra = the reverse)"
for r in 250 1000; do
  dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_raster_from_catalog('land_cover', 'synthetic_raster_landcover', 'class_fraction', $r, 2052499878)" >/dev/null
  dbpsql -At -F ' | ' -c "
  WITH ee AS (SELECT person_id, modifier_source_value AS cls, value_as_number::float8 AS v FROM working.external_exposure),
       k AS (SELECT point_id, class_code AS cls, value FROM ek WHERE method = 'class_fraction' AND radius_m = $r AND layer = 'synthetic_raster_landcover' AND value > 0)
  SELECT 'synthetic_raster_landcover', $r, (SELECT count(*) FROM k) AS expected, (SELECT count(*) FROM ee) AS derived,
         (SELECT count(*) FROM k WHERE NOT EXISTS (SELECT 1 FROM ee WHERE ee.person_id = k.point_id AND ee.cls = k.cls)) AS missing,
         (SELECT count(*) FROM ee WHERE NOT EXISTS (SELECT 1 FROM k WHERE ee.person_id = k.point_id AND ee.cls = k.cls)) AS extra,
         round(avg(abs(ee.v - k.value))::numeric, 5) AS avg_diff, round(max(abs(ee.v - k.value))::numeric, 4) AS max_diff,
         (SELECT round(max(abs(t - 1))::numeric, 9) FROM (SELECT sum(v) AS t FROM ee GROUP BY person_id) x) AS max_sum_error
  FROM ee JOIN k ON ee.person_id = k.point_id AND ee.cls = k.cls"
done
fi
echo "==> done"
