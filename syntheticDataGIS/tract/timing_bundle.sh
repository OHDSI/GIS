#!/usr/bin/env bash
# Timing of the Gaia join against plain PostGIS SQL on another machine, without rebuilding the tract benchmark.
#   tract/timing_bundle.sh export [container] [bundle dir]   on the machine holding the build: writes the bundle
#   tract/timing_bundle.sh run [bundle dir] [out dir]        on the timing machine: restores the bundle and runs benchmark/baseline_join.sh
set -euo pipefail
MODE="${1:?export or run}"; ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
PM25=us_2014_2019_monthly_pm25_by_tract_cdc
if [ "$MODE" = export ]; then
  C="${2:-gaia-db-tract-build}"; B="${3:-timing_bundle}"; mkdir -p "$B"
  docker exec "$C" pg_dump -U postgres -d gaiacore -Fc -t public.us_2019_tract_tl -t public.$PM25 -t working.geom_$PM25 -t working.attr_$PM25 > "$B/tract_tables.dump"
  docker exec "$C" pg_dump -U postgres -d gaiacore -a -n backbone --inserts --on-conflict-do-nothing > "$B/backbone_data.sql"
  cp syntheticDataGIS/tract/build/out/synthetic_omop_gis_tract.sql.gz "$B/"
  grep -E "gaia_db_image:" syntheticDataGIS/tract/build/out/BUILD_INFO.txt | sed 's/gaia_db_image: //' > "$B/image.txt"
  ls -l "$B"; exit 0
fi
B="${2:-timing_bundle}"; OUT="${3:-timing_results}"; mkdir -p "$OUT"
DB=gaia-timing-db; IMAGE="$(cat "$B/image.txt")"; WORK="$(mktemp -d)"; mkdir -p "$WORK/secrets"
printf 'timing-pw' > "$WORK/secrets/PG"; printf 'timing-auth' > "$WORK/secrets/AUTH"
docker rm -f "$DB" > /dev/null 2>&1 || true
docker run -d --name "$DB" --platform linux/amd64 -u postgres:postgres \
  -e POSTGRES_USER=postgres -e PGUSER=postgres -e POSTGRES_DB=gaiacore -e PGDATABASE=gaiacore \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/PG -e PG_PASSWORD_FILE=/run/secrets/PG -e INIT_WITH_DATASOURCE_MOUNT=TRUE -e AUTHENTICATOR_PASSWORD_FILE=/run/secrets/AUTH \
  -v "$WORK/secrets/PG:/run/secrets/PG:ro" -v "$WORK/secrets/AUTH:/run/secrets/AUTH:ro" "$IMAGE" > /dev/null
for i in $(seq 1 180); do docker logs "$DB" 2>&1 | grep -q "init process complete" && break; sleep 2; done
for i in $(seq 1 90); do docker exec "$DB" psql -U postgres -d gaiacore -Atc "select 1" > /dev/null 2>&1 && break; sleep 2; done
q() { docker exec -i "$DB" psql -U postgres -d gaiacore -v ON_ERROR_STOP=1 -q "$@"; }
gunzip -c "$B/synthetic_omop_gis_tract.sql.gz" | q > /dev/null
q < "$B/backbone_data.sql" > /dev/null
docker exec -i "$DB" pg_restore -U postgres -d gaiacore --no-owner < "$B/tract_tables.dump"
q -c "
INSERT INTO working.location (location_id, address_1, address_2, city, state, zip, county, location_source_value, country_concept_id, country_source_value, latitude, longitude, geom)
SELECT location_id, address_1, address_2, city, state, zip, county, location_source_value, country_concept_id, country_source_value, latitude, longitude, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) FROM omopgis.location;
INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date)
SELECT location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date FROM omopgis.location_history;" > /dev/null
{ date; uname -a; lscpu | grep -E "Model name|^CPU\(s\)|MHz"; free -m | head -2; docker --version; echo "$IMAGE"; } > "$OUT/hardware.txt" 2>&1 || true
RESOLUTION=tract bash syntheticDataGIS/benchmark/baseline_join.sh "$DB" "$OUT"
docker rm -f "$DB" > /dev/null; rm -rf "$WORK"
