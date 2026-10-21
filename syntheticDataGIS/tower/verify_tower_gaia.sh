#!/usr/bin/env bash
# Usage: tower/verify_tower_gaia.sh [--keep]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$HERE/build}"
GAIA_DB_IMAGE="${GAIA_DB_IMAGE:-ohdsi/gaia-db@sha256:bd044e2931b11d98a99e730582ab11788fc5beac1442b5c0ada1871c6398957a}"
CONTAINER="${CONTAINER:-gaia-db-tower-verify}"
VOLUME="${VOLUME:-gaia-tower-verify-pgdata}"
HTTP_PORT="${HTTP_PORT:-8765}"
DB=gaiacore; DBUSER=postgres
EXPOSURE_TYPE_CONCEPT=2052499878
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
dbpsql() { docker exec -i "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q "$@"; }
dbquery() { dbpsql -At -c "$1"; }

cleanup() {
  [ -n "${HTTP_PID:-}" ] && kill "$HTTP_PID" 2>/dev/null || true
  if [ "$KEEP" = 0 ]; then docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; docker volume rm "$VOLUME" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT

for tool in docker python3; do command -v "$tool" >/dev/null 2>&1 || die "$tool is required"; done
docker info >/dev/null 2>&1 || die "docker daemon is not reachable"
[ -f "$HERE/data/tower_floors.csv" ] || python3 -I "$HERE/build_tower_dataset.py"

log "1. Catalog entries pointing at a local web server for the CSV sources"
rm -rf "$BUILD_DIR/catalog"; mkdir -p "$BUILD_DIR"
python3 -I "$HERE/build_tower_entries.py" --catalog "$BUILD_DIR/catalog" --url-base "http://host.docker.internal:$HTTP_PORT"
chmod -R a+rwX "$BUILD_DIR/catalog"
python3 -I -m http.server "$HTTP_PORT" --directory "$HERE/data" --bind 0.0.0.0 >/dev/null 2>&1 &
HTTP_PID=$!

log "2. gaiaDB container ($GAIA_DB_IMAGE)"
SECRETS_DIR="$BUILD_DIR/secrets"; mkdir -p "$SECRETS_DIR"
[ -f "$SECRETS_DIR/PG_PASSWORD" ] || printf 'gaia-verify-local' > "$SECRETS_DIR/PG_PASSWORD"
[ -f "$SECRETS_DIR/AUTH_PASSWORD" ] || printf 'gaia-verify-local' > "$SECRETS_DIR/AUTH_PASSWORD"
for f in CDC_APP_TOKEN AIRNOW_API_KEY USGS_USER USGS_PASSWORD CENSUS_API_KEY COPERNICUS_KEY; do [ -f "$SECRETS_DIR/$f" ] || : > "$SECRETS_DIR/$f"; done
chmod -R a+rX "$SECRETS_DIR"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker volume rm "$VOLUME" >/dev/null 2>&1 || true
docker pull --platform linux/amd64 "$GAIA_DB_IMAGE" >/dev/null
docker run -d --name "$CONTAINER" --hostname gaia-db --platform linux/amd64 --user postgres:postgres \
  -e POSTGRES_USER="$DBUSER" -e PGUSER="$DBUSER" -e POSTGRES_DB="$DB" -e PGDATABASE="$DB" \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/PG_PASSWORD -e PG_PASSWORD_FILE=/run/secrets/PG_PASSWORD \
  -e AUTHENTICATOR_PASSWORD_FILE=/run/secrets/AUTH_PASSWORD \
  -e INIT_WITH_DATASOURCE_MOUNT=TRUE -e POSTGRES_PORT=5432 -e PGPORT=5432 \
  -e GAIA_COPERNICUS_KEY_FILE=/run/secrets/COPERNICUS_KEY -e USGS_USER_FILE=/run/secrets/USGS_USER -e USGS_PASSWORD_FILE=/run/secrets/USGS_PASSWORD \
  -e CDC_APP_TOKEN_FILE=/run/secrets/CDC_APP_TOKEN -e AIRNOW_API_KEY_FILE=/run/secrets/AIRNOW_API_KEY -e CENSUS_API_KEY_FILE=/run/secrets/CENSUS_API_KEY \
  -v "$VOLUME":/var/lib/postgresql/data -v "$BUILD_DIR/catalog":/data -v "$SECRETS_DIR":/run/secrets:ro \
  "$GAIA_DB_IMAGE" >/dev/null
echo -n "   waiting for the database"
for _ in $(seq 1 180); do
  if docker exec "$CONTAINER" pg_isready -h 127.0.0.1 -U "$DBUSER" -d "$DB" >/dev/null 2>&1 \
     && [ "$(dbquery "SELECT count(*) FROM pg_proc WHERE proname='spatial_join_from_catalog'" 2>/dev/null || echo 0)" -ge 1 ]; then echo " - ready"; break; fi
  echo -n "."; sleep 2
done

log "3. Ingest the two catalog entries"
for t in synthetic_tower_floors synthetic_tower_sensors; do
  out=$(dbquery "SELECT step || ': ' || status || ' ' || coalesce(message, '') FROM backbone.ingest_datasource('$t')") || die "ingest of $t failed"
  echo "$out" | sed 's/^/   /'
  ! echo "$out" | grep -qi -E "error|fail" || die "ingest of $t reported an error"
done
[ "$(dbquery "SELECT count(*) FROM synthetic_tower_floors")" = 100 ] || die "expected 100 floor polygons"
[ "$(dbquery "SELECT count(*) FROM synthetic_tower_sensors")" = 400 ] || die "expected 400 sensors"

log "4. Load the persons' locations (copied from the CSV files, ids preserved)"
python3 -I - "$HERE/data" <<'PY' | dbpsql
import csv, sys
d = sys.argv[1]
print("CREATE TEMP TABLE l (location_id int, address_1 text, location_source_value text, latitude float8, longitude float8);")
print("COPY l FROM STDIN WITH (FORMAT csv);")
for r in csv.DictReader(open(f"{d}/location.csv")):
    print(",".join([r["location_id"], '"' + r["address_1"] + '"', r["location_source_value"], r["latitude"], r["longitude"]]))
print("\\.")
print("INSERT INTO working.location (location_id, address_1, location_source_value, latitude, longitude, geom) SELECT location_id, address_1, location_source_value, latitude, longitude, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) FROM l;")
print("SELECT setval(pg_get_serial_sequence('working.location','location_id'), (SELECT max(location_id) FROM working.location));")
print("CREATE TEMP TABLE h (location_id int, relationship_type_concept_id int, domain_id int, entity_id int, start_date date, end_date date);")
print("COPY h FROM STDIN WITH (FORMAT csv);")
for r in csv.DictReader(open(f"{d}/location_history.csv")):
    print(",".join([r["location_id"], r["relationship_type_concept_id"], r["domain_id"], r["entity_id"], r["start_date"], r["end_date"]]))
print("\\.")
print("INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date) SELECT * FROM h;")
PY
echo "   locations: $(dbquery "SELECT count(*) FROM working.location") histories: $(dbquery "SELECT count(*) FROM working.location_history")"

log "5. Geometry invariants"
bad=$(dbquery "SELECT count(*) FROM working.location l LEFT JOIN synthetic_tower_floors f ON ST_Within(l.geom, ST_Transform(f.geom, 4326)) WHERE f.floor_number IS DISTINCT FROM substring(l.location_source_value from 7)::int")
[ "$bad" = 0 ] || die "$bad locations are not inside the polygon of their own floor"
bad=$(dbquery "SELECT count(*) FROM synthetic_tower_sensors s JOIN synthetic_tower_floors f ON ST_Within(ST_Transform(s.geom, 4326), ST_Transform(f.geom, 4326)) WHERE f.floor_number <> s.floor_number")
[ "$bad" = 0 ] || die "$bad sensors lie in the wrong floor polygon"
[ "$(dbquery "SELECT count(*) FROM (SELECT floor_number FROM synthetic_tower_sensors GROUP BY 1 HAVING count(*) = 4) x")" = 100 ] || die "every floor needs 4 sensors"
bad=$(dbquery "SELECT count(*) FROM synthetic_tower_floors a JOIN synthetic_tower_floors b ON a.floor_number + 1 = b.floor_number AND NOT ST_Touches(a.geom, b.geom)")
[ "$bad" = 0 ] || die "$bad neighbouring floors do not touch"
echo "   every location is in its floor, every sensor in its floor, neighbouring floors touch"

log "6. Build the variable tables and derive the exposure with the Gaia join"
out=$(dbquery "SELECT variable_name || ': ' || status || ' ' || coalesce(message, '') FROM backbone.gdsc_load_all_variables(p_table_id => 'synthetic_tower_floors', p_geom_label => 'floor_number', p_variable_nodata => -999, p_source => 'OHDSI GIS tower generator (simulated)')")
echo "$out" | sed 's/^/   /'
! echo "$out" | grep -qi -E "error|fail" || die "loading the variables reported an error"
dbquery "SELECT working.spatial_join_from_catalog('pm25_floor_mean', 'synthetic_tower_floors', p_exposure_type_concept_id => $EXPOSURE_TYPE_CONCEPT)"
n=$(dbquery "SELECT count(*) FROM working.external_exposure")
echo "   exposure rows: $n"

log "7. Compare with the independent answer key"
dbpsql -At -c "COPY (SELECT person_id, count(*), round(sum(value_as_number)::numeric, 4), min(exposure_start_date), max(exposure_end_date), count(DISTINCT exposure_source_value) FROM working.external_exposure GROUP BY person_id ORDER BY person_id) TO STDOUT WITH (FORMAT csv)" > "$BUILD_DIR/gaia_person_exposure.csv"
python3 -I - "$HERE/data/person_exposure_truth.csv" "$BUILD_DIR/gaia_person_exposure.csv" <<'PY'
import csv, sys
truth = {int(r["person_id"]): r for r in csv.DictReader(open(sys.argv[1]))}
got = {int(r[0]): r for r in csv.reader(open(sys.argv[2]))}
assert set(truth) == set(got), f"persons differ: {len(truth)} in the key, {len(got)} in Gaia"
rows_bad = vals_bad = 0; worst = 0.0
for pid, t in truth.items():
    g = got[pid]
    days = int(t["days"]); exp = float(t["pm25_day_weighted"]) * days
    if int(g[1]) != days or g[3] != "2019-01-01" or g[4] != "2019-12-31": rows_bad += 1
    d = abs(float(g[2]) - exp); worst = max(worst, d)
    if d > 1e-3: vals_bad += 1
print(f"persons {len(truth)}; persons with a wrong row count or period {rows_bad}; with a wrong value sum {vals_bad}; worst absolute difference of the 365-day sum {worst:.5f}")
sys.exit(1 if rows_bad or vals_bad else 0)
PY
log "Gaia check passed"
