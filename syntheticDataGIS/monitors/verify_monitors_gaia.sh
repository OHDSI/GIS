#!/usr/bin/env bash
# Runs the monitor networks through gaiaDB in a throwaway container and compares the joins with the answer key:
# the point sources and their Voronoi cells are ingested from the catalog entries, one person per test point (500, living
# at the point 2014-2019) is joined to the cells with spatial_join_from_catalog, and to the monitors through a buffer.
# Needs docker and python3 (+ numpy).
#
#   monitors/verify_monitors_gaia.sh [--keep]      # --keep leaves the container running (gaia-monitors-test)
#
# The files are served from this checkout over http, so nothing has to be pushed first. gaiaDB's sql files (02 to 09)
# are loaded from GAIADB_SQL (default ../../../gaiaDB/sql next to this checkout) before the ingest; GAIADB_SQL=none uses the image as it is.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAIA_DB_IMAGE="${GAIA_DB_IMAGE:-ohdsi/gaia-db:main}"
GAIADB_SQL="${GAIADB_SQL:-$HERE/../../../gaiaDB/sql}"
CONTAINER=gaia-monitors-test
DB=gaiacore; DBUSER=postgres
PORT="${PORT:-8098}"
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1

WORK="$(mktemp -d)"
cleanup() {
  [ -n "${HTTP_PID:-}" ] && kill "$HTTP_PID" 2>/dev/null || true
  [ "$KEEP" = 1 ] || docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
dbpsql() { docker exec -i -e PGOPTIONS="-c client_min_messages=warning" "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q "$@"; }

echo "==> monitors, answer key and catalog entries"
python3 "$HERE/build_monitors.py" --out "$HERE/data" >/dev/null
mkdir -p "$WORK/data" "$WORK/secrets"
python3 "$HERE/build_monitor_entries.py" --catalog "$WORK/data" --url-base "http://host.docker.internal:$PORT" >/dev/null
chmod -R a+rwX "$WORK/data"
printf 'gaia-monitors-test' > "$WORK/secrets/PG_PASSWORD"; printf 'gaia-monitors-test' > "$WORK/secrets/AUTH_PASSWORD"
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
if [ "$GAIADB_SQL" != none ] && [ -d "$GAIADB_SQL" ]; then
  echo "==> gaiaDB sql from $GAIADB_SQL"
  for f in "$GAIADB_SQL"/0[2-9]_*.sql; do
    docker cp "$f" "$CONTAINER":/tmp/"$(basename "$f")"
    docker exec "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q -f /tmp/"$(basename "$f")" >/dev/null
  done
fi

NETS="20 60 200"
echo "==> ingest (the cells are built from the point source, which goes first)"
for n in $NETS; do
  for t in synthetic_monitors_$n synthetic_monitors_${n}_voronoi; do
    echo "-- $t"
    dbpsql -At -F ' | ' -c "SELECT step, status, left(message, 160) FROM backbone.ingest_datasource('$t') WHERE status <> 'in_progress' AND step IN ('metadata_load', 'postgis', 'complete', 'ingestion')" | grep -E 'error|complete|postgis' || true
  done
done

echo "==> geometry of the cells"
for n in $NETS; do
  dbpsql -At -F ' | ' -c "SELECT 'synthetic_monitors_${n}_voronoi', count(*) AS cells, bool_and(ST_IsValid(geom)) AS valid,
       round((sum(ST_Area(ST_Transform(geom, 5070))) / 1e6)::numeric, 4) AS area_km2, round(max(ST_Area(ST_Transform(geom, 5070)) / 1e6)::numeric, 3) AS largest_km2,
       (SELECT count(*) FROM synthetic_monitors_${n}_voronoi a JOIN synthetic_monitors_${n}_voronoi b ON a.ogc_fid < b.ogc_fid AND ST_Overlaps(a.geom, b.geom)) AS overlapping_pairs
       FROM synthetic_monitors_${n}_voronoi"
done

echo "==> persons and answer key"
dbpsql <<'SQL'
CREATE TABLE tp (point_id int PRIMARY KEY, lon double precision, lat double precision, x double precision, y double precision);
CREATE TABLE ek (point_id int, network int, year int, nearest_monitor_id int, distance_m double precision, tie_margin_m double precision,
                 monitor_value double precision, true_value double precision, within_1000 int, within_2500 int, idw_k3_value double precision);
SQL
tail -n +2 "$HERE/../raster/data/raster_test_points.csv" | dbpsql -c "\\copy tp FROM STDIN WITH (FORMAT csv)"
tail -n +2 "$HERE/data/expected_monitor_assignment.csv" | dbpsql -c "\\copy ek FROM STDIN WITH (FORMAT csv)"
dbpsql <<'SQL'
INSERT INTO working.location (location_id, geom, longitude, latitude)
SELECT point_id, g, ST_X(g), ST_Y(g) FROM (SELECT point_id, ST_Transform(ST_SetSRID(ST_MakePoint(x, y), 5070), 4326) AS g FROM tp) t;
INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date)
SELECT point_id, 2052496995, 1147314, point_id, DATE '2014-01-01', DATE '2019-12-31' FROM tp;
SQL

echo "==> Voronoi cells: spatial_join_from_catalog (ST_Within) vs the nearest monitor of the key"
for n in $NETS; do
  t=synthetic_monitors_${n}_voronoi
  dbpsql -q -c "SELECT * FROM backbone.gdsc_load_all_variables(p_table_id => '$t', p_geom_label => 'monitor_id', p_variable_nodata => -999, p_source => 'simulated monitors')" >/dev/null
  dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_from_catalog('pm25_monitor', '$t', 'ST_Within', 0, 2052499878)" >/dev/null
  dbpsql -At -F ' | ' -c "
  WITH ee AS (SELECT person_id, extract(year FROM exposure_start_date)::int AS yr, value_as_number::float8 AS v, count(*) OVER (PARTITION BY person_id, extract(year FROM exposure_start_date)) AS n FROM working.external_exposure),
       k AS (SELECT point_id, year, monitor_value FROM ek WHERE network = $n)
  SELECT $n AS network, (SELECT count(*) FROM k) AS expected, (SELECT count(*) FROM ee) AS derived,
         (SELECT count(*) FROM k WHERE NOT EXISTS (SELECT 1 FROM ee WHERE ee.person_id = k.point_id AND ee.yr = k.year)) AS missing,
         (SELECT count(*) FROM ee WHERE n > 1) AS duplicated,
         (SELECT count(*) FROM ee JOIN k ON ee.person_id = k.point_id AND ee.yr = k.year WHERE abs(ee.v - k.monitor_value) > 1e-3) AS other_monitor,
         (SELECT max(abs(ee.v - k.monitor_value)) FROM ee JOIN k ON ee.person_id = k.point_id AND ee.yr = k.year) AS max_diff"
done

echo "==> point sources through a buffer (the join that exists for points): persons with no, one or several monitors, vs the key"
for n in $NETS; do
  t=synthetic_monitors_${n}
  dbpsql -q -c "SELECT * FROM backbone.gdsc_load_all_variables(p_table_id => '$t', p_geom_label => 'monitor_id', p_variable_nodata => -999, p_source => 'simulated monitors')" >/dev/null
  for r in 1000 2500; do
    dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_from_catalog('pm25_monitor', '$t', 'ST_Within', $r, 2052499878)" >/dev/null
    col=$([ "$r" = 1000 ] && echo within_1000 || echo within_2500)
    dbpsql -At -F ' | ' -c "
    WITH per AS (SELECT person_id, count(*) AS rows_2014 FROM working.external_exposure WHERE exposure_start_date = '2014-01-01' GROUP BY 1),
         k AS (SELECT point_id, $col AS expected FROM ek WHERE network = $n AND year = 2014)
    SELECT $n AS network, $r AS radius_m,
           count(*) FILTER (WHERE coalesce(per.rows_2014, 0) = 0) AS persons_with_none,
           count(*) FILTER (WHERE per.rows_2014 = 1) AS with_one, count(*) FILTER (WHERE per.rows_2014 > 1) AS with_several,
           max(coalesce(per.rows_2014, 0)) AS most_rows, count(*) FILTER (WHERE coalesce(per.rows_2014, 0) <> k.expected) AS differs_from_key
    FROM k LEFT JOIN per ON per.person_id = k.point_id"
  done
done
echo "==> nearest-point join (geodesic distances) and inverse-distance weighting (k=3) vs the key, and vs the Voronoi cells (planar, EPSG:5070)"
for n in $NETS; do
  t=synthetic_monitors_${n}; v=${t}_voronoi
  dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_from_catalog('pm25_monitor', '$v', 'ST_Within', 0, 2052499878)" >/dev/null
  dbpsql -q -c "DROP TABLE IF EXISTS cells_$n; CREATE TABLE cells_$n AS SELECT person_id, exposure_start_date AS d, value_as_number::float8 AS v FROM working.external_exposure" >/dev/null
  dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_nearest_from_catalog('pm25_monitor', '$t', 1, NULL, 2, TRUE, 2052499878)" >/dev/null
  dbpsql -At -F ' | ' -c "
  WITH ee AS (SELECT person_id, exposure_start_date AS d, extract(year FROM exposure_start_date)::int AS yr, value_as_number::float8 AS v,
                     substring(modifier_source_value from 'distance_m=([0-9.]+)')::float8 AS dist FROM working.external_exposure),
       k AS (SELECT point_id, year, monitor_value, distance_m FROM ek WHERE network = $n)
  SELECT 'nearest', $n AS network, (SELECT count(*) FROM k) AS expected, (SELECT count(*) FROM ee) AS derived,
         (SELECT count(*) FROM ee JOIN k ON ee.person_id = k.point_id AND ee.yr = k.year WHERE abs(ee.v - k.monitor_value) > 1e-3) AS other_monitor_than_key,
         (SELECT count(*) FROM ee JOIN cells_$n c ON c.person_id = ee.person_id AND c.d = ee.d WHERE abs(ee.v - c.v) > 1e-3) AS differs_from_cells,
         (SELECT round(avg(ee.dist / k.distance_m)::numeric, 4) FROM ee JOIN k ON ee.person_id = k.point_id AND ee.yr = k.year) AS geodesic_over_planar_distance"
  dbpsql -q -c "TRUNCATE working.external_exposure" -c "SELECT working.spatial_join_nearest_from_catalog('pm25_monitor', '$t', 3, NULL, 2, FALSE, 2052499878)" >/dev/null
  dbpsql -At -F ' | ' -c "
  WITH ee AS (SELECT person_id, extract(year FROM exposure_start_date)::int AS yr, value_as_number::float8 AS v FROM working.external_exposure),
       k AS (SELECT point_id, year, idw_k3_value FROM ek WHERE network = $n)
  SELECT 'idw k=3', $n AS network, count(*) AS compared, (SELECT count(*) FROM ee) AS derived,
         round(avg(abs(ee.v - k.idw_k3_value))::numeric, 5) AS avg_diff, round(max(abs(ee.v - k.idw_k3_value))::numeric, 4) AS max_diff
  FROM ee JOIN k ON ee.person_id = k.point_id AND ee.yr = k.year"
done
echo "==> done"
