#!/usr/bin/env bash
# Builds the synthetic OMOP + GIS tutorial dataset end to end (see README.md):
# gaiaDB ingests TIGER counties + CDC monthly PM2.5, stage 1 creates persons and residences,
# gaiaDB derives the exposure, stage 2 draws the clinical data from it, then verify and export.
# The exported dataset omits external_exposure (participants derive it in Session 2).
#
# Needs docker, git, curl, python3. First run downloads ~0.5 GB (slow on Apple Silicon: the image is amd64).
# Usage: ./build_tutorial_dataset.sh [--clean] [--keep-running] [--out DIR]
# Env:   GAIA_DB_IMAGE (defaults to the pinned release digest), GAIA_CATALOG_REPO, GAIA_CATALOG_REF, BUILD_DIR
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$HERE/build}"
OUT_DIR="$BUILD_DIR/out"
GAIA_DB_IMAGE="${GAIA_DB_IMAGE:-ohdsi/gaia-db@sha256:c6dab20c2064304e4293a7f66a897dbc1fd2c41c1f393234e93da4ce721474b8}"
GAIA_CATALOG_REPO="${GAIA_CATALOG_REPO:-https://github.com/OHDSI/gaiaCatalog.git}"
GAIA_CATALOG_REF="${GAIA_CATALOG_REF:-00cec2aead13c430fe2a02fb1876611565dae4e4}"
CONTAINER="${CONTAINER:-gaia-db-synth-build}"
VOLUME="${VOLUME:-gaia-synth-build-pgdata}"
DB=gaiacore
DBUSER=postgres

COUNTY_TABLE=us_2023_county_tl
PM25_TABLE=us_2014_2019_monthly_pm25_by_county_cdc
PM25_VARIABLE=pm25_mean_pred
POP_URL="https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv"

CLEAN=0
KEEP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --clean) CLEAN=1 ;;
    --keep-running) KEEP=1 ;;
    --out) OUT_DIR="$2"; shift ;;
    -h|--help) sed -n '2,9p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# psql inside the container; extra args are passed through (e.g. -c, -At)
dbpsql() { docker exec -i "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q "$@"; }
dbquery() { dbpsql -At -c "$1"; }

# ---------------------------------------------------------------------------
log "0. Preflight"
for tool in docker git curl python3; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is required but not installed"
done
docker info >/dev/null 2>&1 || die "docker daemon is not reachable"

if [ "$CLEAN" = 1 ]; then
  log "   --clean: removing container, volume and cached downloads"
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME" >/dev/null 2>&1 || true
  rm -rf "$BUILD_DIR/gaiaCatalog" "$BUILD_DIR/secrets" "$OUT_DIR"
fi
mkdir -p "$BUILD_DIR" "$OUT_DIR"

# ---------------------------------------------------------------------------
log "1. gaiaCatalog (dataset definitions + ETL scripts) @ $GAIA_CATALOG_REF"
CATALOG_DIR="$BUILD_DIR/gaiaCatalog"
if [ ! -d "$CATALOG_DIR/.git" ]; then
  git clone --quiet "$GAIA_CATALOG_REPO" "$CATALOG_DIR"
fi
git -C "$CATALOG_DIR" fetch --quiet origin
git -C "$CATALOG_DIR" checkout --quiet "$GAIA_CATALOG_REF"
git -C "$CATALOG_DIR" merge --quiet --ff-only "origin/$GAIA_CATALOG_REF" 2>/dev/null || true
CATALOG_SHA="$(git -C "$CATALOG_DIR" rev-parse HEAD)"
echo "   gaiaCatalog commit: $CATALOG_SHA"
# ETL scripts run as uid 70 and write under /data
chmod -R a+rwX "$CATALOG_DIR/datastore/data"

# ---------------------------------------------------------------------------
log "2. gaiaDB container ($GAIA_DB_IMAGE)"
SECRETS_DIR="$BUILD_DIR/secrets"
mkdir -p "$SECRETS_DIR"
# API-key secrets are empty placeholders (the two public datasets need none)
[ -f "$SECRETS_DIR/PG_PASSWORD" ] || printf 'gaia-build-local' > "$SECRETS_DIR/PG_PASSWORD"
[ -f "$SECRETS_DIR/AUTH_PASSWORD" ] || printf 'gaia-build-local' > "$SECRETS_DIR/AUTH_PASSWORD"
for f in CDC_APP_TOKEN AIRNOW_API_KEY USGS_USER USGS_PASSWORD CENSUS_API_KEY COPERNICUS_KEY; do
  [ -f "$SECRETS_DIR/$f" ] || : > "$SECRETS_DIR/$f"
done
chmod -R a+rX "$SECRETS_DIR"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  docker pull --platform linux/amd64 "$GAIA_DB_IMAGE" >/dev/null
  # the catalog ETL scripts connect to host 'gaia-db'
  docker run -d --name "$CONTAINER" --hostname gaia-db --platform linux/amd64 --user postgres:postgres \
    -e POSTGRES_USER="$DBUSER" -e PGUSER="$DBUSER" -e POSTGRES_DB="$DB" -e PGDATABASE="$DB" \
    -e POSTGRES_PASSWORD_FILE=/run/secrets/PG_PASSWORD -e PG_PASSWORD_FILE=/run/secrets/PG_PASSWORD \
    -e AUTHENTICATOR_PASSWORD_FILE=/run/secrets/AUTH_PASSWORD \
    -e INIT_WITH_DATASOURCE_MOUNT=TRUE -e POSTGRES_PORT=5432 -e PGPORT=5432 \
    -e GAIA_COPERNICUS_KEY_FILE=/run/secrets/COPERNICUS_KEY \
    -e USGS_USER_FILE=/run/secrets/USGS_USER -e USGS_PASSWORD_FILE=/run/secrets/USGS_PASSWORD \
    -e CDC_APP_TOKEN_FILE=/run/secrets/CDC_APP_TOKEN -e AIRNOW_API_KEY_FILE=/run/secrets/AIRNOW_API_KEY \
    -e CENSUS_API_KEY_FILE=/run/secrets/CENSUS_API_KEY \
    -v "$VOLUME":/var/lib/postgresql/data \
    -v "$CATALOG_DIR/datastore/data":/data \
    -v "$SECRETS_DIR":/run/secrets:ro \
    "$GAIA_DB_IMAGE" >/dev/null
fi

echo -n "   waiting for the database"
for _ in $(seq 1 120); do
  # TCP check: the init-time server is socket-only
  if docker exec "$CONTAINER" pg_isready -h 127.0.0.1 -U "$DBUSER" -d "$DB" >/dev/null 2>&1 \
     && [ "$(dbquery "SELECT count(*) FROM pg_proc WHERE proname='spatial_join_from_catalog'" 2>/dev/null || echo 0)" -ge 1 ]; then
    echo " - ready"; break
  fi
  echo -n "."; sleep 5
done
dbquery "SELECT 1 FROM pg_proc WHERE proname='spatial_join_from_catalog'" | grep -q 1 || die "gaiaDB did not become ready (docker logs $CONTAINER)"

IMAGE_ID="$(docker inspect --format '{{.Image}}' "$CONTAINER")"
IMAGE_DIGEST="$(docker inspect --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{else}}none{{end}}' "$GAIA_DB_IMAGE" 2>/dev/null || echo none)"
echo "   image: $GAIA_DB_IMAGE  digest: $IMAGE_DIGEST"

# ---------------------------------------------------------------------------
table_rows() {  # table_rows <schema.table> -> row count, or 0 when the table does not exist
  dbquery "SELECT CASE WHEN to_regclass('$1') IS NULL THEN 0
                       ELSE (xpath('/row/c/text()', query_to_xml('SELECT count(*) AS c FROM $1', false, true, '')))[1]::text::bigint END"
}

ingest() {  # ingest <table_id> <min rows>
  local table_id="$1" min_rows="$2" n
  n="$(table_rows "public.$table_id")"
  if [ "$n" -ge "$min_rows" ]; then
    echo "   $table_id already ingested ($n rows) - skipping"
    return
  fi
  echo "   ingesting $table_id (downloads + loads into PostGIS)..."
  dbpsql -c "SELECT * FROM backbone.ingest_datasource('$table_id')" >"$BUILD_DIR/ingest_$table_id.log" 2>&1 \
    || { tail -n 30 "$BUILD_DIR/ingest_$table_id.log"; die "ingestion of $table_id failed"; }
  n="$(table_rows "public.$table_id")"
  [ "$n" -ge "$min_rows" ] || { tail -n 30 "$BUILD_DIR/ingest_$table_id.log"; die "$table_id has only $n rows after ingestion"; }
  echo "   $table_id: $n rows"
}

log "3. Ingest datasets through the Gaia catalog"
ingest "$COUNTY_TABLE" 3000
ingest "$PM25_TABLE" 3000
[ "$(dbquery "SELECT count(*) FROM public.$PM25_TABLE WHERE $PM25_VARIABLE IS NOT NULL")" -ge 3000 ] \
  || die "the PM2.5 table has no joined monthly series (the TIGER table must be ingested first)"

# ---------------------------------------------------------------------------
log "4. County population estimates (Census 2019), downloaded on the fly"
dbpsql -c "DROP TABLE IF EXISTS public.ref_county_pop2019; CREATE TABLE public.ref_county_pop2019 (county_fips text PRIMARY KEY, pop_2019 integer NOT NULL);"
curl -fsSL --retry 3 "$POP_URL" | python3 -c '
import csv, io, sys
txt = sys.stdin.buffer.read().decode("latin-1")
w = csv.writer(sys.stdout)
w.writerow(["county_fips", "pop_2019"])
for r in csv.DictReader(io.StringIO(txt)):
    if r["SUMLEV"] == "050":               # county level
        w.writerow([r["STATE"].zfill(2) + r["COUNTY"].zfill(3), r["POPESTIMATE2019"]])
' | dbpsql -c "\\copy public.ref_county_pop2019 FROM STDIN WITH (FORMAT csv, HEADER true)"
echo "   $(dbquery 'SELECT count(*) FROM public.ref_county_pop2019') counties with population"

# ---------------------------------------------------------------------------
log "5. Stage 1 - persons, residences, location history"
dbpsql < "$HERE/sql/stage1_ddl.sql" >/dev/null
dbpsql <<SQL
CREATE TABLE demo.build_info (key varchar(40) PRIMARY KEY, value text NOT NULL);
INSERT INTO demo.build_info VALUES
  ('built_on',            to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD')),
  ('generator_git_commit','$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo unknown)'),
  ('gaia_db_image',       '$GAIA_DB_IMAGE'),
  ('gaia_db_image_digest','$IMAGE_DIGEST'),
  ('gaia_catalog_commit', '$CATALOG_SHA'),
  ('pm25_dataset',        '$PM25_TABLE ($PM25_VARIABLE, CDC EPHTN EPA Downscaler, monthly county means)'),
  ('county_dataset',      '$COUNTY_TABLE (Census TIGER/Line 2023 counties)'),
  ('population_source',   '$POP_URL');
SQL
dbpsql < "$HERE/sql/stage1_population.sql" >/dev/null

log "6. gaiaDB: load locations, derive exposure with the catalog spatial join"
dbpsql -c "TRUNCATE working.external_exposure; TRUNCATE working.location_history, working.location CASCADE;"
dbpsql -c "SELECT * FROM working.load_location_data('/tmp/LOCATION.csv', '/tmp/LOCATION_HISTORY.csv')"
dbpsql -c "SELECT * FROM backbone.gdsc_load_all_variables(p_table_id => '$PM25_TABLE', p_geom_label => 'name', p_variable_nodata => -999, p_source => 'CDC EPHTN daily county PM2.5 (EPA Downscaler), monthly means')" \
  | tee "$BUILD_DIR/gdsc_load_variables.log" | cat
if grep -q ' error ' "$BUILD_DIR/gdsc_load_variables.log"; then die "gdsc_load_all_variables reported an error"; fi
dbpsql -c "SELECT working.spatial_join_from_catalog('$PM25_VARIABLE', '$PM25_TABLE')"
echo "   $(dbquery "SELECT count(*) FROM working.external_exposure") exposure rows derived by gaiaDB"

# ---------------------------------------------------------------------------
log "7. Stage 2 - clinical data, SDOH and fixtures drawn from the derived exposure"
dbpsql < "$HERE/sql/stage2_clinical.sql" >/dev/null

log "8. Verify"
dbpsql < "$HERE/sql/verify.sql"

# ---------------------------------------------------------------------------
log "9. Write outputs to $OUT_DIR"
rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR/csv"
# strip \restrict lines (newer pg_dump) so the dump restores with any psql
docker exec "$CONTAINER" pg_dump -U "$DBUSER" -d "$DB" -n omopgis -n demo --no-owner --no-privileges \
  | grep -v -E '^\\(un)?restrict ' | gzip -9 > "$OUT_DIR/synthetic_omop_gis.sql.gz"

# one CSV per non-empty table
for t in $(dbquery "SELECT table_schema || '.' || table_name FROM information_schema.tables
                    WHERE table_schema IN ('omopgis','demo') AND table_type = 'BASE TABLE' ORDER BY 1"); do
  if [ "$(dbquery "SELECT EXISTS (SELECT 1 FROM $t)")" = "t" ]; then
    dbpsql -c "\\copy (SELECT * FROM $t x ORDER BY 1, x::text) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$OUT_DIR/csv/${t#*.}.csv"
  fi
done

# fallback exposure file
dbpsql -c "\\copy (SELECT row_number() OVER (ORDER BY person_id, exposure_start_date, location_id) AS external_exposure_id,
                          location_id, person_id, exposure_concept_id, exposure_start_date,
                          exposure_start_datetime, exposure_end_date, exposure_end_datetime, exposure_type_concept_id,
                          exposure_relationship_concept_id, exposure_source_concept_id, exposure_source_value,
                          exposure_relationship_source_value, dose_unit_source_value, quantity, modifier_source_value,
                          operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id
                   FROM working.external_exposure ORDER BY person_id, exposure_start_date, location_id)
           TO STDOUT WITH (FORMAT csv, HEADER true)" | gzip -9 > "$OUT_DIR/external_exposure_fallback.csv.gz"

dbpsql -At -c "SELECT key || ': ' || value FROM demo.build_info ORDER BY key" > "$OUT_DIR/BUILD_INFO.txt"

( cd "$OUT_DIR" && ls -l synthetic_omop_gis.sql.gz external_exposure_fallback.csv.gz && du -sh csv )

if [ "$KEEP" = 0 ]; then
  log "Stopping the build container (database volume $VOLUME is kept for fast re-runs)"
  docker rm -f "$CONTAINER" >/dev/null
fi
log "Done. Dataset: $OUT_DIR/synthetic_omop_gis.sql.gz  (restore with: gunzip -c ... | psql)"
