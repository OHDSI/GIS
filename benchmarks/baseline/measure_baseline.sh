#!/usr/bin/env bash
# Issue #525: what does adding a dataset cost today? Runs the two worked cases through the current gaiaDB image in a throwaway
# container and records the wall-clock time and outcome of every step, plus a count of the files, code and credentials involved.
#   mdc_hospitals            a dataset (point source from an ArcGIS REST service)
#   synthetic_road_proximity a derived dataset (distance bands around the primary and secondary roads of California)
#
#   benchmarks/baseline/measure_baseline.sh [--keep]      # needs docker and python3; the gaiaCatalog checkout is expected next to this one
#
# Environment: GAIA_DB_IMAGE (default ohdsi/gaia-db:main), CATALOG (default ../../../gaiaCatalog/datastore/data), STATES (default 06, California).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAIA_DB_IMAGE="${GAIA_DB_IMAGE:-ohdsi/gaia-db:main}"
CATALOG="${CATALOG:-$HERE/../../../gaiaCatalog/datastore/data}"
GAIADB_REPO="${GAIADB_REPO:-$HERE/../../../gaiaDB}"
STATES="${STATES:-06}"
CONTAINER=gaia-baseline-test
DB=gaiacore; DBUSER=postgres
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1

WORK="$(mktemp -d)"
cleanup() { [ "$KEEP" = 1 ] || docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; rm -rf "$WORK"; }
trap cleanup EXIT
now() { python3 -c 'import time; print(f"{time.time():.3f}")'; }
dbpsql() { docker exec -i -e PGOPTIONS="-c client_min_messages=warning" "$CONTAINER" psql -U "$DBUSER" -d "$DB" -q "$@"; }
# timed <label> <command...>: prints "label | seconds | exit"
timed() { local label="$1"; shift; local t0 t1; t0=$(now); "$@" >"$WORK/last.out" 2>&1; local rc=$?; t1=$(now)
          printf '%s | %.1f s | exit %s\n' "$label" "$(python3 -c "print($t1 - $t0)")" "$rc"; return 0; }

echo "## Environment"
echo "image: $GAIA_DB_IMAGE ($(docker inspect --format '{{index .RepoDigests 0}}' "$GAIA_DB_IMAGE" 2>/dev/null || echo 'no digest'))"
echo "host: $(uname -sm), docker platform linux/amd64 (emulated on Apple Silicon); date $(date +%F)"
echo "gaiaCatalog: $(git -C "$CATALOG/../.." rev-parse --short HEAD 2>/dev/null || echo unknown); gaiaDB: $(git -C "$GAIADB_REPO" rev-parse --short HEAD 2>/dev/null || echo unknown)"

echo; echo "## What has to be written (files and lines in the catalog entry)"
for t in mdc_hospitals us_2019_prisecroads_tl synthetic_road_proximity; do
  d="$CATALOG/$t"
  nfiles=$(find "$d" -type f | wc -l | tr -d ' '); nlines=$(find "$d" -type f \( -name '*.sh' -o -name 'processStep' \) -exec cat {} + | wc -l | tr -d ' ')
  kb=$(find "$d" -type f -name 'meta_*.json' -exec cat {} + | wc -c | awk '{printf "%.0f", $1/1024}')
  gen=$(grep -l 'Created by etl()' "$d"/etl/*.sh 2>/dev/null | wc -l | tr -d ' ')
  secrets=$(cat "$d"/etl/*.sh | grep -c -E '^export [A-Z_]+=\$\(cat \$[A-Z_]+_FILE\)')
  echo "$t | files: $nfiles | script lines: $nlines | metadata: ${kb} KB | scripts stamped 'Created by etl()': $gen | secret-file exports in scripts: $secrets"
done
echo "generator of synthetic_road_proximity in this repo: $(wc -l < "$HERE/../../syntheticDataGIS/tract/build_road_entries.py" | tr -d ' ') lines (build_road_entries.py)"

echo; echo "## gaiaDB code on the path from source to EXTERNAL_EXPOSURE (lines of SQL/PLpgSQL per file)"
for f in 02_jsonld_ingestion_functions 03_location_ingestion_functions 04_spatial_join_functions 05_data_source_retrieval_functions 06_gdsc_catalog_functions; do
  printf '%s | %s lines | %s functions\n' "$f" "$(git -C "$GAIADB_REPO" show 570a40b:sql/$f.sql 2>/dev/null | wc -l | tr -d ' ')" "$(git -C "$GAIADB_REPO" show 570a40b:sql/$f.sql 2>/dev/null | grep -c -i '^CREATE OR REPLACE FUNCTION')"
done
echo "(counted at gaiaDB commit 570a40b, the state before the raster and point-source additions)"

echo; echo "## Running the two cases"
mkdir -p "$WORK/data" "$WORK/secrets"
for t in mdc_hospitals us_2019_prisecroads_tl synthetic_road_proximity; do cp -R "$CATALOG/$t" "$WORK/data/$t"; done
chmod -R a+rwX "$WORK/data"
printf 'gaia-baseline' > "$WORK/secrets/PG_PASSWORD"; printf 'gaia-baseline' > "$WORK/secrets/AUTH_PASSWORD"
for f in CDC_APP_TOKEN AIRNOW_API_KEY USGS_USER USGS_PASSWORD CENSUS_API_KEY COPERNICUS_KEY; do : > "$WORK/secrets/$f"; done
chmod -R a+rX "$WORK/secrets"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
t0=$(now)
docker run -d --name "$CONTAINER" --hostname gaia-db --platform linux/amd64 --user postgres:postgres \
  -e POSTGRES_USER="$DBUSER" -e PGUSER="$DBUSER" -e POSTGRES_DB="$DB" -e PGDATABASE="$DB" \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/PG_PASSWORD -e PG_PASSWORD_FILE=/run/secrets/PG_PASSWORD \
  -e AUTHENTICATOR_PASSWORD_FILE=/run/secrets/AUTH_PASSWORD -e INIT_WITH_DATASOURCE_MOUNT=TRUE -e POSTGRES_PORT=5432 -e PGPORT=5432 -e TRACT_STATES="$STATES" \
  -e GAIA_COPERNICUS_KEY_FILE=/run/secrets/COPERNICUS_KEY -e USGS_USER_FILE=/run/secrets/USGS_USER -e USGS_PASSWORD_FILE=/run/secrets/USGS_PASSWORD \
  -e CDC_APP_TOKEN_FILE=/run/secrets/CDC_APP_TOKEN -e AIRNOW_API_KEY_FILE=/run/secrets/AIRNOW_API_KEY -e CENSUS_API_KEY_FILE=/run/secrets/CENSUS_API_KEY \
  -v "$WORK/data":/data -v "$WORK/secrets":/run/secrets:ro "$GAIA_DB_IMAGE" >/dev/null
for _ in $(seq 1 120); do
  docker exec "$CONTAINER" pg_isready -h 127.0.0.1 -U "$DBUSER" -d "$DB" >/dev/null 2>&1 \
    && [ "$(dbpsql -At -c "SELECT count(*) FROM pg_proc WHERE proname='ingest_datasource'" 2>/dev/null || echo 0)" -ge 1 ] && break
  sleep 3
done
printf 'container start and gaiaDB initialisation | %.1f s\n' "$(python3 -c "print($(now) - $t0)")"

ingest() {  # ingest <table_id>: runs the protocol and prints its step rows
  timed "ingest_datasource('$1')" dbpsql -At -F ' | ' -c "SELECT step, status, left(message, 120) FROM backbone.ingest_datasource('$1') WHERE status <> 'in_progress'"
  grep -E 'error' "$WORK/last.out" | head -3 | sed 's/^/    /'
  echo "    rows: $(dbpsql -At -c "SELECT count(*) FROM public.$1" 2>&1 | tail -1)"
}

echo; echo "### Case 1: mdc_hospitals"
ingest mdc_hospitals
echo "    registered variables (attr_index): $(dbpsql -At -c "SELECT count(*) FROM backbone.attr_index WHERE table_name = 'mdc_hospitals'")  of $(dbpsql -At -c "SELECT count(*) FROM backbone.variable_source vs JOIN backbone.data_source ds USING (data_source_uuid) WHERE ds.dataset_id LIKE '%/mdc_hospitals'") variables in the metadata"
timed "gdsc_load_all_variables('mdc_hospitals')" dbpsql -At -c "SELECT * FROM backbone.gdsc_load_all_variables(p_table_id => 'mdc_hospitals', p_geom_label => 'name', p_variable_nodata => -999, p_source => 'baseline')"
head -c 300 "$WORK/last.out" | sed 's/^/    /'

echo; echo "### Case 2: synthetic_road_proximity (needs the roads it is derived from)"
ingest us_2019_prisecroads_tl
ingest synthetic_road_proximity
timed "gdsc_load_all_variables('synthetic_road_proximity')" dbpsql -At -c "SELECT * FROM backbone.gdsc_load_all_variables(p_table_id => 'synthetic_road_proximity', p_geom_label => 'band', p_variable_nodata => -999, p_source => 'baseline')"
head -c 300 "$WORK/last.out" | sed 's/^/    /'
# 10,000 persons at random points of the bands, living there 2019
dbpsql -c "TRUNCATE working.external_exposure; TRUNCATE working.location_history, working.location CASCADE;
  INSERT INTO working.location (location_id, geom, longitude, latitude)
  SELECT row_number() OVER (), g, ST_X(g), ST_Y(g) FROM (SELECT ST_Transform(ST_PointOnSurface(geom), 4326) AS g FROM synthetic_road_proximity ORDER BY random() LIMIT 10000) t;
  INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date)
  SELECT location_id, 2052496995, 1147314, location_id, DATE '2019-01-01', DATE '2019-12-31' FROM working.location;"
timed "spatial_join_from_catalog('road_increment') for 10,000 persons" dbpsql -At -c "SELECT working.spatial_join_from_catalog('road_increment', 'synthetic_road_proximity', 'ST_Within', 0, 0)"
echo "    exposure rows: $(dbpsql -At -c 'SELECT count(*) FROM working.external_exposure')"
echo; echo "## done"
