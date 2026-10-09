#!/usr/bin/env bash
# Baseline for the Gaia spatial join: the same join as plain PostGIS SQL, with row agreement and runtimes.
#   baseline_join.sh [container] [output dir]
set -euo pipefail
CONTAINER="${1:-gaia-db-synth-build}"
OUT="${2:-syntheticDataGIS/benchmark/output}"
RUNS=3
mkdir -p "$OUT"
psql_() { docker exec -i "$CONTAINER" psql -U postgres -d gaiacore -v ON_ERROR_STOP=1 -q -At "$@"; }
RESOLUTION="${RESOLUTION:-county}"
if [ "$RESOLUTION" = tract ]; then
  PM25_TABLE=us_2014_2019_monthly_pm25_by_tract_cdc; POLYGONS=us_2019_tract_tl
else
  PM25_TABLE=us_2014_2019_monthly_pm25_by_county_cdc; POLYGONS=us_2023_county_tl
fi
SRC="$(psql_ -c "SELECT variable_source_id FROM backbone.attr_index WHERE table_name = '$PM25_TABLE' AND variable_name = 'pm25_mean_pred'")"

: > "$OUT/baseline_join_timing.csv"
echo "method,run,seconds,rows" >> "$OUT/baseline_join_timing.csv"

for run in $(seq 1 $RUNS); do
  psql_ -c "DELETE FROM working.external_exposure WHERE exposure_source_value = '$SRC'"
  start=$(python3 -c 'import time; print(time.time())')
  rows=$(psql_ -c "SELECT working.spatial_join_from_catalog('pm25_mean_pred', '$PM25_TABLE', p_exposure_type_concept_id => 2052499878)" 2>/dev/null | tail -1)
  end=$(python3 -c 'import time; print(time.time())')
  echo "Gaia spatial_join_from_catalog ($RESOLUTION),$run,$(python3 -c "print(round($end-$start,2))"),$rows" >> "$OUT/baseline_join_timing.csv"
done

BASELINE_SQL="
SELECT lh.entity_id AS person_id, lh.location_id,
       GREATEST(m.m_start, lh.start_date) AS exposure_start_date, LEAST(m.m_end, lh.end_date) AS exposure_end_date, m.v AS value_as_number
FROM omopgis.location_history lh
JOIN omopgis.location l ON l.location_id = lh.location_id
JOIN public.$POLYGONS t
  ON ST_Within(ST_Transform(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326), 4269), t.geom)
JOIN (SELECT c.geoid, split_part(k.key, '/', 1)::date AS m_start, split_part(k.key, '/', 2)::date AS m_end, k.value::double precision AS v
      FROM public.$PM25_TABLE c, jsonb_each_text(c.pm25_mean_pred) k) m
  ON m.geoid = t.geoid AND m.m_start <= lh.end_date AND m.m_end >= lh.start_date"

WIDE_SQL="
SELECT lh.location_id, lh.entity_id AS person_id, 2052499839::integer AS exposure_concept_id,
       GREATEST(m.m_start, lh.start_date) AS exposure_start_date, GREATEST(m.m_start, lh.start_date)::timestamp AS exposure_start_datetime,
       LEAST(m.m_end, lh.end_date) AS exposure_end_date, LEAST(m.m_end, lh.end_date)::timestamp AS exposure_end_datetime,
       2052499878::integer AS exposure_type_concept_id, 2052496943::integer AS exposure_relationship_concept_id,
       2052499839::integer AS exposure_source_concept_id, '$SRC'::varchar(50) AS exposure_source_value,
       'ST_Within'::varchar(50) AS exposure_relationship_source_value, NULL::varchar(50) AS dose_unit_source_value, NULL::integer AS quantity,
       NULL::varchar(50) AS modifier_source_value, NULL::integer AS operator_concept_id, m.v AS value_as_number,
       NULL::integer AS value_as_concept_id, NULL::integer AS unit_concept_id
FROM omopgis.location_history lh
JOIN omopgis.location l ON l.location_id = lh.location_id
JOIN public.$POLYGONS t
  ON ST_Within(ST_Transform(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326), 4269), t.geom)
JOIN (SELECT c.geoid, split_part(k.key, '/', 1)::date AS m_start, split_part(k.key, '/', 2)::date AS m_end, k.value::double precision AS v
      FROM public.$PM25_TABLE c, jsonb_each_text(c.pm25_mean_pred) k) m
  ON m.geoid = t.geoid AND m.m_start <= lh.end_date AND m.m_end >= lh.start_date"
for run in $(seq 1 $RUNS); do
  psql_ -c "DROP TABLE IF EXISTS public.baseline_join_wide"
  start=$(python3 -c 'import time; print(time.time())')
  psql_ -c "CREATE TABLE public.baseline_join_wide AS $WIDE_SQL"
  end=$(python3 -c 'import time; print(time.time())')
  rows=$(psql_ -c "SELECT count(*) FROM public.baseline_join_wide")
  echo "Plain PostGIS SQL - all output columns ($RESOLUTION),$run,$(python3 -c "print(round($end-$start,2))"),$rows" >> "$OUT/baseline_join_timing.csv"
done
psql_ -c "DROP TABLE IF EXISTS public.baseline_join_wide"

for run in $(seq 1 $RUNS); do
  psql_ -c "DROP TABLE IF EXISTS public.baseline_join_result"
  start=$(python3 -c 'import time; print(time.time())')
  psql_ -c "CREATE TABLE public.baseline_join_result AS $BASELINE_SQL"
  end=$(python3 -c 'import time; print(time.time())')
  rows=$(psql_ -c "SELECT count(*) FROM public.baseline_join_result")
  echo "Plain PostGIS SQL ($RESOLUTION),$run,$(python3 -c "print(round($end-$start,2))"),$rows" >> "$OUT/baseline_join_timing.csv"
done

psql_ -F, -c "
WITH g AS (SELECT person_id, location_id, exposure_start_date, exposure_end_date, value_as_number FROM working.external_exposure WHERE exposure_source_value = '$SRC'),
     b AS (SELECT * FROM public.baseline_join_result)
SELECT 'rows in Gaia result', count(*) FROM g
UNION ALL SELECT 'rows in baseline result', count(*) FROM b
UNION ALL SELECT 'rows only in Gaia', count(*) FROM (SELECT person_id, location_id, exposure_start_date, exposure_end_date FROM g EXCEPT SELECT person_id, location_id, exposure_start_date, exposure_end_date FROM b) x
UNION ALL SELECT 'rows only in baseline', count(*) FROM (SELECT person_id, location_id, exposure_start_date, exposure_end_date FROM b EXCEPT SELECT person_id, location_id, exposure_start_date, exposure_end_date FROM g) x
UNION ALL SELECT 'matched rows with a different value (> 1e-9)', count(*) FROM g JOIN b USING (person_id, location_id, exposure_start_date, exposure_end_date) WHERE abs(g.value_as_number - b.value_as_number) > 1e-9" \
  | sed 's/^/agreement,/' > "$OUT/baseline_join_agreement.csv"
psql_ -c "DROP TABLE public.baseline_join_result"
cat "$OUT/baseline_join_timing.csv" "$OUT/baseline_join_agreement.csv"
