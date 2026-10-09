#!/usr/bin/env bash
# Benchmark checks that need nothing outside this repository: tutorial restore, exposure agreement with the answer key, synthetic surfaces through Gaia.
#   .github/benchmark/run_checks.sh [--keep]
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1
WORK="$(mktemp -d)"; DB=gaia-ci-db; NET=gaia-ci-net; PORT="${FEATURE_PORT:-8097}"; OUT="syntheticDataGIS/benchmark/output/ci"
PLATFORM="--platform linux/amd64"; STATUS=0
cleanup() { [ "$KEEP" = 1 ] && return; docker rm -f "$DB" > /dev/null 2>&1 || true; docker network rm "$NET" > /dev/null 2>&1 || true
            [ -n "${HTTP_PID:-}" ] && kill "$HTTP_PID" 2> /dev/null || true; rm -rf "$WORK"; }
trap cleanup EXIT
mkdir -p "$OUT" "$WORK/secrets" "$WORK/catalog" "$WORK/features"; rm -f "$OUT/ingest_errors.txt"; touch "$OUT/ingest_errors.txt"

echo "== generate the surface catalog entries and features"
python3 syntheticDataGIS/tract/build_surface_entries.py --catalog "$WORK/catalog" --features-dir "$WORK/features" --url-base "http://host.docker.internal:$PORT"
for k in 100m 1km 10km; do
  cmp "$WORK/features/surface_${k}_features.csv" "syntheticDataGIS/tract/data/surface_${k}_features.csv" \
    || { echo "committed surface_${k}_features.csv differs from what tract/build_surface_entries.py generates" >&2; exit 1; }
done
chmod -R 777 "$WORK/catalog"
(cd "$WORK/features" && exec python3 -m http.server "$PORT" --bind 0.0.0.0 > "$WORK/http.log" 2>&1) & HTTP_PID=$!

echo "== start gaia-db"
printf 'ci-postgres-pw' > "$WORK/secrets/PG"; printf 'ci-auth-pw' > "$WORK/secrets/AUTH"
docker network create "$NET" > /dev/null
docker run -d --name "$DB" $PLATFORM --network "$NET" --network-alias gaia-db --add-host host.docker.internal:host-gateway -u postgres:postgres \
  -e POSTGRES_USER=postgres -e PGUSER=postgres -e POSTGRES_DB=gaiacore -e PGDATABASE=gaiacore \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/PG -e PG_PASSWORD_FILE=/run/secrets/PG -e INIT_WITH_DATASOURCE_MOUNT=TRUE -e AUTHENTICATOR_PASSWORD_FILE=/run/secrets/AUTH \
  -v "$WORK/secrets/PG:/run/secrets/PG:ro" -v "$WORK/secrets/AUTH:/run/secrets/AUTH:ro" -v "$WORK/catalog:/data" ohdsi/gaia-db:main > /dev/null
for i in $(seq 1 120); do docker logs "$DB" 2>&1 | grep -q "init process complete" && break; sleep 2; done
for i in $(seq 1 60); do docker exec "$DB" psql -U postgres -d gaiacore -Atc "select count(*) from backbone.data_source" > /dev/null 2>&1 && break; sleep 2; done
docker exec "$DB" psql -U postgres -d gaiacore -Atc "select count(*) from backbone.data_source" > /dev/null || { echo "gaia-db did not start" >&2; docker logs "$DB" | tail -20; exit 1; }

rscript() { docker run --rm $PLATFORM --network "$NET" -e GAIA_POSTGRES_PASSWORD=ci-postgres-pw -e OPENBLAS_NUM_THREADS=1 -v "$ROOT":/repo -w /repo --entrypoint Rscript ohdsi/gaia-core:main "$@"; }

echo "== 1. tutorial restore (Exercise 2, step 1)"
bash .github/benchmark/tutorial_restore_check.sh "$DB" "$ROOT" | tee "$OUT/tutorial_restore_check.txt" || STATUS=1

echo "== 2. exposure agreement with the independent answer key"
rscript syntheticDataGIS/benchmark/exposure_agreement.R --out "$OUT" > "$OUT/exposure_agreement.log" 2>&1 || { tail -20 "$OUT/exposure_agreement.log"; STATUS=1; }
python3 .github/benchmark/assert_agreement.py "$OUT/exposure_agreement.csv" | tee "$OUT/exposure_agreement_check.txt" || STATUS=1

echo "== 3. synthetic surfaces through Gaia"
for k in 100m 1km 10km; do
  docker exec "$DB" psql -U postgres -d gaiacore -Atc "SELECT step || ': ' || left(message, 200) FROM backbone.ingest_datasource('synthetic_surface_${k}') WHERE status = 'error'" | tee -a "$OUT/ingest_errors.txt"
done
[ ! -s "$OUT/ingest_errors.txt" ] || STATUS=1
rscript syntheticDataGIS/benchmark/geocoding_gaia_check.R --features-dir syntheticDataGIS/tract/data --errors syntheticDataGIS/tract/data/geocoding_errors \
  --n-synthetic 300 --reps 3 --assert --out "$OUT" 2>&1 | tee "$OUT/gaia_check.log" | tail -25 || STATUS=1

echo; [ "$STATUS" = 0 ] && echo "ALL BENCHMARK CHECKS PASSED" || echo "BENCHMARK CHECKS FAILED"
exit "$STATUS"
