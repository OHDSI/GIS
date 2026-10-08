#!/usr/bin/env bash
# Builds the tract-level benchmark dataset (a second, more detailed synthetic dataset; the tutorial dataset is not affected).
#
# Same pipeline as ../build_tutorial_dataset.sh with finer geography: persons are placed in census tracts of a few states
# (proportional to tract population), the generator's exposure is the real tract-level monthly PM2.5 (CDC EPHTN Downscaler),
# SES is simulated per tract, and the county-level PM2.5 is joined as a second, coarser variable through the same index so the
# two resolutions can be compared. Both the tract and the county source go through Gaia's catalog and spatial join.
#
# Needs docker, git, curl, unzip, python3. The CDC tract query is slow (about 5 minutes per request); downloads are cached in the
# database volume. Usage: tract/build_tract_benchmark.sh [--clean] [--keep-running] [--out DIR]
# Env:   TRACT_STATES (space separated state FIPS codes, default "01 04 06 41" = AL AZ CA OR), N_PERSONS (default 40000),
#        CATALOG_OVERLAY (a gaiaCatalog datastore/data directory whose entries are copied over the pinned catalog checkout while the
#        tract entries are not part of it), GAIA_DB_IMAGE, GAIA_CATALOG_REPO, GAIA_CATALOG_REF, BUILD_DIR, CONTAINER, VOLUME
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDG="$(cd "$HERE/.." && pwd)"                         # syntheticDataGIS/
BUILD_DIR="${BUILD_DIR:-$HERE/build}"
OUT_DIR="$BUILD_DIR/out"
GAIA_DB_IMAGE="${GAIA_DB_IMAGE:-ohdsi/gaia-db@sha256:bd044e2931b11d98a99e730582ab11788fc5beac1442b5c0ada1871c6398957a}"
GAIA_CATALOG_REPO="${GAIA_CATALOG_REPO:-https://github.com/OHDSI/gaiaCatalog.git}"
GAIA_CATALOG_REF="${GAIA_CATALOG_REF:-830b75aa6ae7febb926b05a5dd27e33a00c848d4}"
CATALOG_OVERLAY="${CATALOG_OVERLAY:-}"
CONTAINER="${CONTAINER:-gaia-db-tract-build}"
VOLUME="${VOLUME:-gaia-tract-build-pgdata}"
TRACT_STATES="${TRACT_STATES:-01 04 06 41}"
N_PERSONS="${N_PERSONS:-40000}"
STATES_FIPS="$(echo "$TRACT_STATES" | tr ' ' ',')"
DB=gaiacore
DBUSER=postgres

COUNTY_TABLE=us_2023_county_tl
COUNTY_PM25_TABLE=us_2014_2019_monthly_pm25_by_county_cdc
TRACT_TABLE=us_2019_tract_tl
TRACT_PM25_TABLE=us_2014_2019_monthly_pm25_by_tract_cdc
PM25_VARIABLE=pm25_mean_pred
TRACT_SES_TABLE=synthetic_tract_ses
SES_VARIABLE=ses_index
EXPOSURE_TYPE_CONCEPT=2052499878   # Exposure Type Concept: Air Quality Database
SES_TYPE_CONCEPT=2052497765        # Exposure Type Concept: Social Determinants Of Health (SDOH) Database
POP_URL="https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv"
SVI_URL="https://svi.cdc.gov/Documents/Data/2018/db/states"

CLEAN=0
KEEP=0
while [ $# -gt 0 ]; do
  case "$1" in
    --clean) CLEAN=1 ;;
    --keep-running) KEEP=1 ;;
    --out) OUT_DIR="$2"; shift ;;
    -h|--help) sed -n '2,14p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
dbpsql() { docker exec -i "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q "$@"; }
dbquery() { dbpsql -At -c "$1"; }
state_name() {  # state_name <fips> -> the state's name as used in the SVI file names
  case "$1" in 01) echo Alabama ;; 04) echo Arizona ;; 06) echo California ;; 41) echo Oregon ;;
    *) die "state $1 is not mapped to an SVI file name (add it to state_name)" ;; esac
}
now() { python3 -c 'import time; print(round(time.time(), 1))'; }

# ---------------------------------------------------------------------------
log "0. Preflight"
for tool in docker git curl unzip python3; do
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
log "1. gaiaCatalog @ $GAIA_CATALOG_REF"
CATALOG_DIR="$BUILD_DIR/gaiaCatalog"
[ -d "$CATALOG_DIR/.git" ] || git clone --quiet "$GAIA_CATALOG_REPO" "$CATALOG_DIR"
git -C "$CATALOG_DIR" config core.fileMode false
git -C "$CATALOG_DIR" fetch --quiet origin
git -C "$CATALOG_DIR" checkout --quiet "$GAIA_CATALOG_REF"
CATALOG_SHA="$(git -C "$CATALOG_DIR" rev-parse HEAD)"
echo "   gaiaCatalog commit: $CATALOG_SHA"
if [ -n "$CATALOG_OVERLAY" ]; then
  for entry in $TRACT_TABLE $TRACT_PM25_TABLE $TRACT_SES_TABLE; do
    [ -d "$CATALOG_OVERLAY/$entry" ] || die "CATALOG_OVERLAY has no $entry entry"
    rsync -a --exclude download --exclude datestamp "$CATALOG_OVERLAY/$entry/" "$CATALOG_DIR/datastore/data/$entry/"
    echo "   overlay: $entry"
  done
fi
for entry in $TRACT_TABLE $TRACT_PM25_TABLE $TRACT_SES_TABLE; do
  [ -d "$CATALOG_DIR/datastore/data/$entry/etl" ] || die "the catalog checkout has no $entry entry (set CATALOG_OVERLAY)"
done
chmod -R a+rwX "$CATALOG_DIR/datastore/data"

# ---------------------------------------------------------------------------
log "2. gaiaDB container ($GAIA_DB_IMAGE), tract states: $TRACT_STATES"
SECRETS_DIR="$BUILD_DIR/secrets"
mkdir -p "$SECRETS_DIR"
[ -f "$SECRETS_DIR/PG_PASSWORD" ] || printf 'gaia-build-local' > "$SECRETS_DIR/PG_PASSWORD"
[ -f "$SECRETS_DIR/AUTH_PASSWORD" ] || printf 'gaia-build-local' > "$SECRETS_DIR/AUTH_PASSWORD"
for f in CDC_APP_TOKEN AIRNOW_API_KEY USGS_USER USGS_PASSWORD CENSUS_API_KEY COPERNICUS_KEY; do
  [ -f "$SECRETS_DIR/$f" ] || : > "$SECRETS_DIR/$f"
done
chmod -R a+rX "$SECRETS_DIR"
# an app token in $CDC_APP_TOKEN raises the CDC rate limit
[ -z "${CDC_APP_TOKEN:-}" ] || printf '%s' "$CDC_APP_TOKEN" > "$SECRETS_DIR/CDC_APP_TOKEN"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  docker pull --platform linux/amd64 "$GAIA_DB_IMAGE" >/dev/null
  docker run -d --name "$CONTAINER" --hostname gaia-db --platform linux/amd64 --user postgres:postgres \
    -e POSTGRES_USER="$DBUSER" -e PGUSER="$DBUSER" -e POSTGRES_DB="$DB" -e PGDATABASE="$DB" \
    -e POSTGRES_PASSWORD_FILE=/run/secrets/PG_PASSWORD -e PG_PASSWORD_FILE=/run/secrets/PG_PASSWORD \
    -e AUTHENTICATOR_PASSWORD_FILE=/run/secrets/AUTH_PASSWORD \
    -e INIT_WITH_DATASOURCE_MOUNT=TRUE -e POSTGRES_PORT=5432 -e PGPORT=5432 \
    -e TRACT_STATES="$TRACT_STATES" \
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
  if docker exec "$CONTAINER" pg_isready -h 127.0.0.1 -U "$DBUSER" -d "$DB" >/dev/null 2>&1 \
     && [ "$(dbquery "SELECT count(*) FROM pg_proc WHERE proname='spatial_join_from_catalog'" 2>/dev/null || echo 0)" -ge 1 ]; then
    echo " - ready"; break
  fi
  echo -n "."; sleep 5
done
dbquery "SELECT 1 FROM pg_proc WHERE proname='spatial_join_from_catalog'" | grep -q 1 || die "gaiaDB did not become ready (docker logs $CONTAINER)"
dbquery "SELECT 1 FROM pg_proc WHERE proname='spatial_join_from_catalog' AND 'p_exposure_type_concept_id' = ANY(proargnames)" | grep -q 1 \
  || die "this gaiaDB image predates p_exposure_type_concept_id; set GAIA_DB_IMAGE to a build that includes it"
IMAGE_DIGEST="$(docker inspect --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{else}}none{{end}}' "$GAIA_DB_IMAGE" 2>/dev/null || echo none)"
# the container must have been started with the same tract states as this run
[ "$(docker exec "$CONTAINER" printenv TRACT_STATES)" = "$TRACT_STATES" ] \
  || die "the running container was started with TRACT_STATES='$(docker exec "$CONTAINER" printenv TRACT_STATES)'; use --clean or another CONTAINER/VOLUME"

# ---------------------------------------------------------------------------
table_rows() {
  dbquery "SELECT CASE WHEN to_regclass('$1') IS NULL THEN 0
                       ELSE (xpath('/row/c/text()', query_to_xml('SELECT count(*) AS c FROM $1', false, true, '')))[1]::text::bigint END"
}
ingest() {  # ingest <table_id> <min rows>
  local table_id="$1" min_rows="$2" n
  n="$(table_rows "public.$table_id")"
  if [ "$n" -ge "$min_rows" ]; then echo "   $table_id already ingested ($n rows) - skipping"; return; fi
  echo "   ingesting $table_id (downloads + loads into PostGIS)..."
  dbpsql -c "SELECT * FROM backbone.ingest_datasource('$table_id')" >"$BUILD_DIR/ingest_$table_id.log" 2>&1 \
    || { tail -n 30 "$BUILD_DIR/ingest_$table_id.log"; die "ingestion of $table_id failed"; }
  n="$(table_rows "public.$table_id")"
  [ "$n" -ge "$min_rows" ] || { tail -n 30 "$BUILD_DIR/ingest_$table_id.log"; die "$table_id has only $n rows after ingestion"; }
  echo "   $table_id: $n rows"
}
load_variables() {  # load_variables <table_id> <geom label> <source text>
  dbpsql -c "SELECT * FROM backbone.gdsc_load_all_variables(p_table_id => '$1', p_geom_label => '$2', p_variable_nodata => -999, p_source => '$3')" \
    | tee "$BUILD_DIR/gdsc_load_$1.log" | cat
  if grep -q ' error ' "$BUILD_DIR/gdsc_load_$1.log"; then die "gdsc_load_all_variables reported an error for $1"; fi
}

log "3. Ingest datasets through the Gaia catalog"
N_STATES="$(echo "$TRACT_STATES" | wc -w | tr -d ' ')"
MIN_TRACTS=$((N_STATES * 250))
ingest "$COUNTY_TABLE" 3000
ingest "$COUNTY_PM25_TABLE" 3000
ingest "$TRACT_TABLE" "$MIN_TRACTS"
ingest "$TRACT_PM25_TABLE" "$MIN_TRACTS"
[ "$(dbquery "SELECT count(*) FROM public.$TRACT_PM25_TABLE WHERE $PM25_VARIABLE IS NOT NULL")" -ge "$MIN_TRACTS" ] \
  || die "the tract PM2.5 table has no joined monthly series (the tract table must be ingested first)"

# ---------------------------------------------------------------------------
log "4. Population: county estimates (Census 2019) and tract totals (CDC/ATSDR SVI 2018, ACS 2014-2018)"
dbpsql -c "DROP TABLE IF EXISTS public.ref_county_pop2019; CREATE TABLE public.ref_county_pop2019 (county_fips text PRIMARY KEY, pop_2019 integer NOT NULL);"
curl -fsSL --retry 3 "$POP_URL" | python3 -c '
import csv, io, sys
txt = sys.stdin.buffer.read().decode("latin-1")
w = csv.writer(sys.stdout)
w.writerow(["county_fips", "pop_2019"])
for r in csv.DictReader(io.StringIO(txt)):
    if r["SUMLEV"] == "050":
        w.writerow([r["STATE"].zfill(2) + r["COUNTY"].zfill(3), r["POPESTIMATE2019"]])
' | dbpsql -c "\\copy public.ref_county_pop2019 FROM STDIN WITH (FORMAT csv, HEADER true)"
SVI_DIR="$CATALOG_DIR/datastore/data/_svi2018"
mkdir -p "$SVI_DIR"; chmod a+rwx "$SVI_DIR"
dbpsql -c "DROP TABLE IF EXISTS public.ref_tract_pop; CREATE TABLE public.ref_tract_pop (geoid text PRIMARY KEY, pop integer NOT NULL);"
for st in $TRACT_STATES; do
  name="$(state_name "$st")"
  [ -f "$SVI_DIR/$name.zip" ] || curl -fsSL --retry 3 -o "$SVI_DIR/$name.zip" "$SVI_URL/$name.zip"
  rm -rf "$SVI_DIR/$name"; mkdir -p "$SVI_DIR/$name"; chmod a+rwx "$SVI_DIR/$name"
  unzip -qo "$SVI_DIR/$name.zip" -d "$SVI_DIR/$name"; chmod -R a+rwX "$SVI_DIR/$name"
  docker exec "$CONTAINER" sh -c "rm -f /data/_svi2018/$name.csv; ogr2ogr -f CSV /data/_svi2018/$name.csv /data/_svi2018/$name/*.gdb -select FIPS,E_TOTPOP"
  python3 -c '
import csv, sys
w = csv.writer(sys.stdout)
for r in csv.DictReader(open(sys.argv[1])):
    if int(r["E_TOTPOP"]) > 0:
        w.writerow([r["FIPS"], r["E_TOTPOP"]])
' "$SVI_DIR/$name.csv" | dbpsql -c "\\copy public.ref_tract_pop FROM STDIN WITH (FORMAT csv)"
done
echo "   $(dbquery 'SELECT count(*) FROM public.ref_county_pop2019') counties and $(dbquery 'SELECT count(*) FROM public.ref_tract_pop') populated tracts"

# ---------------------------------------------------------------------------
log "5. Stage 1 - persons placed in tracts, residences, location history ($N_PERSONS persons)"
dbpsql < "$SDG/sql/stage1_ddl.sql" >/dev/null
{
  cat "$SDG/sql/stage1_vocabulary_head.sql"
  for tbl in concept vocabulary domain concept_class relationship concept_relationship concept_ancestor concept_synonym; do
    for f in "$SDG/vocabulary/$tbl.csv" "$SDG/vocab_temp/${tbl}_delta.csv"; do
      [ -f "$f" ] || continue
      echo "COPY stg_$tbl FROM STDIN WITH (FORMAT csv, HEADER true);"
      cat "$f"; [ -z "$(tail -c1 "$f")" ] || echo
      echo '\.'
    done
  done
  cat "$SDG/sql/stage1_vocabulary_tail.sql"
} | dbpsql >/dev/null
echo "   $(dbquery 'SELECT count(*) FROM omopgis.concept') concepts loaded"
dbpsql <<SQL
CREATE TABLE demo.build_info (key varchar(40) PRIMARY KEY, value text NOT NULL);
INSERT INTO demo.build_info VALUES
  ('profile',             'tract benchmark'),
  ('built_on',            to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD')),
  ('generator_git_commit','$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo unknown)'),
  ('gaia_db_image',       '$GAIA_DB_IMAGE'),
  ('gaia_db_image_digest','$IMAGE_DIGEST'),
  ('gaia_catalog_commit', '$CATALOG_SHA'),
  ('tract_states',        '$TRACT_STATES'),
  ('n_persons',           '$N_PERSONS'),
  ('tract_pm25_dataset',  '$TRACT_PM25_TABLE ($PM25_VARIABLE, CDC EPHTN Downscaler tract-level, monthly means of the daily predictions)'),
  ('county_pm25_dataset', '$COUNTY_PM25_TABLE ($PM25_VARIABLE, CDC EPHTN Downscaler county-level, monthly means)'),
  ('tract_dataset',       '$TRACT_TABLE (Census TIGER/Line 2019 tracts, 2010 vintage)'),
  ('county_dataset',      '$COUNTY_TABLE (Census TIGER/Line 2023 counties)'),
  ('tract_ses_dataset',   '$TRACT_SES_TABLE ($SES_VARIABLE, simulated tract SES index ingested through the Gaia catalog)'),
  ('tract_population',    'CDC/ATSDR SVI 2018 total population (ACS 2014-2018)'),
  ('county_population',   '$POP_URL');
SQL
dbpsql -v n_persons="$N_PERSONS" -v states_fips="$STATES_FIPS" < "$HERE/sql/stage1_tract_population.sql" >/dev/null
echo "   $(dbquery 'SELECT count(*) FROM omopgis.tract_reference') eligible tracts, $(dbquery 'SELECT count(DISTINCT tract_geoid) FROM omopgis.location') used"

# ---------------------------------------------------------------------------
log "6. gaiaDB: load locations, derive the tract-level exposure with the catalog spatial join"
TIMINGS="$OUT_DIR/timings.csv"; echo "step,seconds,rows" > "$TIMINGS"
dbpsql -c "TRUNCATE working.external_exposure; TRUNCATE working.location_history, working.location CASCADE;"
dbpsql -c "SELECT * FROM working.load_location_data('/tmp/LOCATION.csv', '/tmp/LOCATION_HISTORY.csv')"
load_variables "$TRACT_PM25_TABLE" geoid "CDC EPHTN daily tract PM2.5 (EPA Downscaler), monthly means"

# the tract SES source file is generated from tract_reference; its catalog entry downloads it from the published URL.
# The file is pre-staged with a datestamp so the first build does not need the published file to exist yet.
SES_DIR="$CATALOG_DIR/datastore/data/$TRACT_SES_TABLE"
mkdir -p "$SES_DIR/download"
dbpsql -c "\\copy (SELECT tract_geoid AS geoid, ses_index FROM omopgis.tract_reference ORDER BY tract_geoid) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$SES_DIR/download/$TRACT_SES_TABLE.csv"
date '+%F %T' > "$SES_DIR/datestamp"
chmod -R a+rwX "$SES_DIR"
dbpsql -c "DROP TABLE IF EXISTS working.attr_$TRACT_SES_TABLE, working.geom_$TRACT_SES_TABLE CASCADE;
           DELETE FROM backbone.attr_index WHERE table_name = '$TRACT_SES_TABLE';
           DELETE FROM backbone.geom_index WHERE table_name = '$TRACT_SES_TABLE';
           DELETE FROM backbone.variable_source WHERE data_source_uuid IN (SELECT data_source_uuid FROM backbone.data_source WHERE dataset_id LIKE '%/$TRACT_SES_TABLE');
           DELETE FROM backbone.data_source WHERE dataset_id LIKE '%/$TRACT_SES_TABLE';
           DROP TABLE IF EXISTS public.$TRACT_SES_TABLE;"
ingest "$TRACT_SES_TABLE" "$MIN_TRACTS"
load_variables "$TRACT_SES_TABLE" geoid "Simulated tract SES index (benchmark)"

t0=$(now)
dbpsql -c "SELECT working.spatial_join_from_catalog('$PM25_VARIABLE', '$TRACT_PM25_TABLE', p_exposure_type_concept_id => $EXPOSURE_TYPE_CONCEPT)"
t1=$(now)
echo "gaia spatial join, tract PM2.5,$(python3 -c "print(round($t1-$t0, 1))"),$(dbquery "SELECT count(*) FROM working.external_exposure")" >> "$TIMINGS"
dbpsql -c "SELECT working.spatial_join_from_catalog('$SES_VARIABLE', '$TRACT_SES_TABLE', p_exposure_type_concept_id => $SES_TYPE_CONCEPT)"
echo "   $(dbquery "SELECT count(*) FROM working.external_exposure") exposure rows derived by gaiaDB (tract PM2.5 and tract SES)"

# ---------------------------------------------------------------------------
log "7. Stage 2 - clinical data, SDOH and fixtures drawn from the tract-level exposure"
# stage 2 runs before the county-level PM2.5 is joined, so it only sees the tract-level (finest) exposure
dbpsql < "$SDG/sql/stage2_clinical.sql" >/dev/null

log "8. County-level PM2.5 through the same index (the coarser resolution)"
load_variables "$COUNTY_PM25_TABLE" name "CDC EPHTN daily county PM2.5 (EPA Downscaler), monthly means"
before=$(dbquery "SELECT count(*) FROM working.external_exposure")
t0=$(now)
dbpsql -c "SELECT working.spatial_join_from_catalog('$PM25_VARIABLE', '$COUNTY_PM25_TABLE', p_exposure_type_concept_id => $EXPOSURE_TYPE_CONCEPT)"
t1=$(now)
echo "gaia spatial join, county PM2.5,$(python3 -c "print(round($t1-$t0, 1))"),$(( $(dbquery "SELECT count(*) FROM working.external_exposure") - before ))" >> "$TIMINGS"

log "9. Verify"
TRACT_SRC="$(dbquery "SELECT variable_source_id FROM backbone.attr_index WHERE table_name = '$TRACT_PM25_TABLE' AND variable_name = '$PM25_VARIABLE'")"
COUNTY_SRC="$(dbquery "SELECT variable_source_id FROM backbone.attr_index WHERE table_name = '$COUNTY_PM25_TABLE' AND variable_name = '$PM25_VARIABLE'")"
SES_SRC="$(dbquery "SELECT variable_source_id FROM backbone.attr_index WHERE table_name = '$TRACT_SES_TABLE' AND variable_name = '$SES_VARIABLE'")"
dbpsql -v tract_pm25_src="$TRACT_SRC" -v county_pm25_src="$COUNTY_SRC" -v tract_ses_src="$SES_SRC" < "$HERE/sql/verify_tract.sql"

# ---------------------------------------------------------------------------
log "10. Write outputs to $OUT_DIR"
mkdir -p "$OUT_DIR/csv"
docker exec "$CONTAINER" pg_dump -U "$DBUSER" -d "$DB" -n omopgis -n demo --no-owner --no-privileges \
  | grep -v -E '^\\(un)?restrict ' | gzip -9 > "$OUT_DIR/synthetic_omop_gis_tract.sql.gz"
for t in $(dbquery "SELECT table_schema || '.' || table_name FROM information_schema.tables
                    WHERE table_schema IN ('omopgis','demo') AND table_type = 'BASE TABLE' ORDER BY 1"); do
  if [ "$(dbquery "SELECT EXISTS (SELECT 1 FROM $t)")" = "t" ]; then
    dbpsql -c "\\copy (SELECT * FROM $t x ORDER BY 1, x::text) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$OUT_DIR/csv/${t#*.}.csv"
  fi
done
# all exposure rows: tract PM2.5, county PM2.5 and tract SES (distinguish them with exposure_source_value)
dbpsql -c "\\copy (SELECT row_number() OVER (ORDER BY person_id, exposure_start_date, location_id, exposure_source_value) AS external_exposure_id,
                          location_id, person_id, exposure_concept_id, exposure_start_date,
                          exposure_start_datetime, exposure_end_date, exposure_end_datetime, exposure_type_concept_id,
                          exposure_relationship_concept_id, exposure_source_concept_id, exposure_source_value,
                          exposure_relationship_source_value, dose_unit_source_value, quantity, modifier_source_value,
                          operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id
                   FROM working.external_exposure ORDER BY person_id, exposure_start_date, location_id, exposure_source_value)
           TO STDOUT WITH (FORMAT csv, HEADER true)" | gzip -9 > "$OUT_DIR/external_exposure_fallback_tract.csv.gz"
# raw monthly series of the tracts and counties in use: the input of an independent answer key
dbpsql -c "\\copy (SELECT c.geoid AS tract_geoid, split_part(k.key, '/', 1) AS start_date, split_part(k.key, '/', 2) AS end_date, k.value::numeric AS pm25_mean_pred FROM public.$TRACT_PM25_TABLE c, jsonb_each_text(c.$PM25_VARIABLE) k WHERE c.geoid IN (SELECT tract_geoid FROM omopgis.tract_reference) ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER true)" | gzip -9 > "$OUT_DIR/tract_pm25_monthly.csv.gz"
dbpsql -c "\\copy (SELECT c.geoid AS county_fips, split_part(k.key, '/', 1) AS start_date, split_part(k.key, '/', 2) AS end_date, k.value::numeric AS pm25_mean_pred FROM public.$COUNTY_PM25_TABLE c, jsonb_each_text(c.$PM25_VARIABLE) k WHERE c.geoid IN (SELECT county_fips FROM omopgis.county_reference) ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER true)" | gzip -9 > "$OUT_DIR/county_pm25_monthly.csv.gz"
# source file of the tract SES catalog entry (publish it as syntheticDataGIS/tract/data/tract_ses.csv)
cp "$SES_DIR/download/$TRACT_SES_TABLE.csv" "$OUT_DIR/tract_ses.csv"
dbpsql -At -c "SELECT key || ': ' || value FROM demo.build_info ORDER BY key" > "$OUT_DIR/BUILD_INFO.txt"
( cd "$OUT_DIR" && ls -l *.gz && du -sh csv && cat timings.csv )

if [ "$KEEP" = 0 ]; then
  log "Stopping the build container (database volume $VOLUME is kept for fast re-runs)"
  docker rm -f "$CONTAINER" >/dev/null
fi
log "Done. Dataset: $OUT_DIR/synthetic_omop_gis_tract.sql.gz"
