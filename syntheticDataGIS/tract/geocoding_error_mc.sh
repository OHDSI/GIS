#!/usr/bin/env bash
# Monte Carlo displacement of the persons' locations, for the geocoding-error propagation analysis
# (benchmark/geocoding_error_propagation.R).
#
# For every replicate, each residence location is displaced by a distance drawn from an empirical geocoding error distribution
# (stratified urban / rural by the county's density category) in a uniformly random direction, and the displaced point is
# assigned to the census tract that contains it, and to that tract's county. Locations that land in no tract (water, outside
# the study states) get NULL for both (a county polygon lookup is not needed: tracts nest in counties, and it is much slower). The result is written to mc_assignment.csv.gz (rep, location_id, tract_geoid, county_fips, error_m).
#
# Run it against a gaia-db that holds the finished tract benchmark build (build with --keep-running, or start a container on the
# build volume).
#
#   tract/geocoding_error_mc.sh --errors errors.csv [--container gaia-db-tract-build] [--reps 200] [--seed 20261020] [--out DIR]
#   errors.csv: two columns, stratum (urban or rural; or all, used for both) and error_m (one geocoding error in metres per row).
#   --demo-lognormal MEDIAN_M,SIGMA   a PLACEHOLDER distribution to test the pipeline before the empirical errors are available.
set -euo pipefail
CONTAINER=gaia-db-tract-build; REPS=200; SEED=20261020; OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build/out"; ERRORS=""; DEMO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --container) CONTAINER="$2"; shift ;; --reps) REPS="$2"; shift ;; --seed) SEED="$2"; shift ;; --out) OUT="$2"; shift ;;
    --errors) ERRORS="$2"; shift ;; --demo-lognormal) DEMO="$2"; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$ERRORS" ] || [ -n "$DEMO" ] || { echo "give --errors errors.csv (or --demo-lognormal MEDIAN_M,SIGMA to test the pipeline)" >&2; exit 2; }
psql_() { docker exec -i "$CONTAINER" psql -U postgres -d gaiacore -v ON_ERROR_STOP=1 -q "$@"; }
mkdir -p "$OUT"

psql_ -c "CREATE SCHEMA IF NOT EXISTS mc; DROP TABLE IF EXISTS mc.error_raw, mc.error_sorted, mc.error_n, mc.location_stratum, mc.assign CASCADE;
          CREATE TABLE mc.error_raw (stratum text NOT NULL, error_m double precision NOT NULL);"
if [ -n "$ERRORS" ]; then
  psql_ -c "\\copy mc.error_raw FROM STDIN WITH (FORMAT csv, HEADER true)" < "$ERRORS"
else
  MEDIAN="${DEMO%%,*}"; SIGMA="${DEMO##*,}"
  echo "NOTE: using a PLACEHOLDER lognormal error distribution (median ${MEDIAN} m, sigma ${SIGMA}); not the empirical distribution" >&2
  psql_ -c "INSERT INTO mc.error_raw SELECT s.stratum, exp(ln($MEDIAN) + $SIGMA * sqrt(-2 * ln(random())) * cos(2 * pi() * random()))
            FROM (VALUES ('urban'), ('rural')) s(stratum), generate_series(1, 5000)"
fi
# 'all' rows serve both strata
psql_ -c "INSERT INTO mc.error_raw SELECT s.stratum, r.error_m FROM mc.error_raw r, (VALUES ('urban'), ('rural')) s(stratum) WHERE r.stratum = 'all';
          DELETE FROM mc.error_raw WHERE stratum = 'all';
          CREATE TABLE mc.error_sorted AS SELECT stratum, row_number() OVER (PARTITION BY stratum ORDER BY error_m) AS k, error_m FROM mc.error_raw;
          CREATE TABLE mc.error_n AS SELECT stratum, count(*) AS n FROM mc.error_sorted GROUP BY stratum;
          CREATE INDEX ON mc.error_sorted (stratum, k);"
[ "$(psql_ -At -c "SELECT count(*) FROM mc.error_n")" = 2 ] || { echo "the error file needs urban and rural (or all) rows" >&2; exit 1; }

# tract polygons subdivided into small pieces (point-in-polygon on the full polygons is two orders of magnitude slower)
psql_ -c "CREATE TABLE IF NOT EXISTS mc.tract_pieces AS SELECT geoid, ST_Subdivide(geom, 128) AS geom FROM public.us_2019_tract_tl;
          CREATE INDEX IF NOT EXISTS tract_pieces_geom_idx ON mc.tract_pieces USING gist (geom); ANALYZE mc.tract_pieces"
psql_ -c "CREATE TABLE mc.location_stratum AS
          SELECT l.location_id, ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS pt,
                 CASE WHEN c.urban_density_category IN ('Urban Core', 'Suburban') THEN 'urban' ELSE 'rural' END AS stratum
          FROM omopgis.location l JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id;
          CREATE TABLE mc.assign (rep integer, location_id integer, tract_geoid varchar(11), county_fips varchar(5), error_m double precision);"

# replicate 0: no displacement, the reference assignment by the same polygon method
psql_ -c "INSERT INTO mc.assign
          SELECT 0, ls.location_id, t.geoid, left(t.geoid, 5), 0
          FROM mc.location_stratum ls
          LEFT JOIN LATERAL (SELECT p.geoid FROM mc.tract_pieces p WHERE ST_Intersects(p.geom, ST_Transform(ls.pt, 4269)) ORDER BY p.geoid LIMIT 1) t ON true"
for rep in $(seq 1 "$REPS"); do
  psql_ -c "SELECT setseed(0.1 + ($SEED % 1000) / 10000.0 + $rep / 1000000.0);
    INSERT INTO mc.assign
    SELECT $rep, d.location_id, t.geoid, left(t.geoid, 5), d.err
    FROM (SELECT ls.location_id, e.error_m AS err,
                 ST_Transform(ST_Project(ls.pt::geography, e.error_m, b.az)::geometry, 4269) AS pt2
          FROM mc.location_stratum ls
          JOIN LATERAL (SELECT 2 * pi() * random() AS az) b ON true
          JOIN LATERAL (SELECT 1 + floor(random() * n.n)::int AS k FROM mc.error_n n WHERE n.stratum = ls.stratum) kk ON true
          JOIN mc.error_sorted e ON e.stratum = ls.stratum AND e.k = kk.k) d
    LEFT JOIN LATERAL (SELECT p.geoid FROM mc.tract_pieces p WHERE ST_Intersects(p.geom, d.pt2) ORDER BY p.geoid LIMIT 1) t ON true" >/dev/null
  [ $((rep % 10)) -ne 0 ] || echo "   replicate $rep / $REPS"
done
[ "$(psql_ -At -c "SELECT count(*) FROM (SELECT rep FROM mc.assign GROUP BY rep HAVING count(*) <> (SELECT count(*) FROM mc.location_stratum)) x")" = 0 ] \
  || { echo "a replicate does not have exactly one assignment per location" >&2; exit 1; }
psql_ -At -c "\\copy (SELECT rep, location_id, tract_geoid, county_fips, round(error_m::numeric, 1) AS error_m FROM mc.assign ORDER BY rep, location_id) TO STDOUT WITH (FORMAT csv, HEADER true)" | gzip -9 > "$OUT/mc_assignment.csv.gz"
psql_ -At -c "\\copy (SELECT l.location_id, l.tract_geoid, c.county_fips, ls.stratum FROM omopgis.location l JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id JOIN mc.location_stratum ls ON ls.location_id = l.location_id ORDER BY 1) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$OUT/mc_location_truth.csv"
ls -l "$OUT/mc_assignment.csv.gz" "$OUT/mc_location_truth.csv"
