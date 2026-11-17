#!/bin/bash
# Times working.spatial_join_nearest_from_catalog on the California primary and secondary roads (lines), #536.
#
#   benchmarks/nearest/bench_roads.sh <gaia-db container> [persons ...]      (default persons: 1000 10000 100000)
#
# The container needs TRACT_STATES=06 in its environment (the road download of the catalog entry reads it; the default is Alabama),
# /data/us_2019_prisecroads_tl from the gaiaCatalog entry, and the gaiaDB of the working tree. Prints "persons k maxd seconds rows".
set -euo pipefail
C="${1:?gaia-db container}"; shift || true
SIZES=("$@"); [ ${#SIZES[@]} -gt 0 ] || SIZES=(1000 10000 100000)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
q() { docker exec -e PGOPTIONS="-c statement_timeout=1500000" "$C" psql -U postgres -d gaiacore -At -F' ' "$@"; }
vac() { q -qc "VACUUM ANALYZE working.location, working.location_history, working.external_exposure" >/dev/null; }
run() { docker cp "$HERE/bench_roads_join.sql" "$C":/tmp/; q "$@" -f /tmp/bench_roads_join.sql | grep -v '^$' | grep -v ROLLBACK | tail -1; }

q -c "SELECT step || ' ' || status FROM backbone.ingest_datasource('us_2019_prisecroads_tl') WHERE status <> 'in_progress'" | tail -1
q -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
SET client_min_messages = warning;
DROP TABLE IF EXISTS public.bn_roads;
CREATE TABLE public.bn_roads AS SELECT ogc_fid, geom, geom_local, linearid, ST_Length(geom::geography)::float8 AS length_m FROM public.us_2019_prisecroads_tl;
ALTER TABLE public.bn_roads ADD PRIMARY KEY (ogc_fid);
SELECT backbone.gdsc_load_variable($${"table_id": "bn_roads", "variable_id": "length_m", "geom_type": "line", "table_description": "bench roads", "geom_label": "linearid", "description": "bench", "concept_id": "2052499839", "start_date": "2014-01-01", "end_date": "2019-12-31", "source": "bench"}$$::jsonb);
SQL
for n in "${SIZES[@]}"; do vac; run -v nloc="$n"; done
vac; run -v nloc="${SIZES[1]:-${SIZES[0]}}" -v k=3
vac; run -v nloc="${SIZES[1]:-${SIZES[0]}}" -v maxd=5000
