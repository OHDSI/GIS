#!/usr/bin/env bash
# Restores the tutorial dump (Exercise 2, step 1), loads the fallback exposure and compares the counts with demo.expected_result.
#   tutorial_restore_check.sh <db container> [repo root]
set -euo pipefail
DB="$1"; ROOT="${2:-$(git rev-parse --show-toplevel)}"; DATA="$ROOT/syntheticDataGIS/data"
q() { docker exec -i "$DB" psql -U postgres -d gaiacore -v ON_ERROR_STOP=1 -At "$@"; }
fail() { echo "Tutorial restore check FAILED: $*" >&2; exit 1; }

gunzip -c "$DATA/synthetic_omop_gis.sql.gz" | docker exec -i "$DB" psql -q -U postgres -d gaiacore -v ON_ERROR_STOP=1 > /dev/null
[ "$(q -c "SELECT count(*) FROM omopgis.person")" = 10000 ] || fail "omopgis.person does not have 10,000 rows"
[ "$(q -c "SELECT count(*) FROM omopgis.external_exposure")" = 0 ] || fail "omopgis.external_exposure is not empty after the restore"
[ "$(q -c "SELECT count(*) FROM demo.rejected_exposure_row")" = 4 ] || fail "demo.rejected_exposure_row does not have the four bad rows"

gunzip -c "$DATA/external_exposure_fallback.csv.gz" | q -c "\\copy omopgis.external_exposure FROM STDIN WITH (FORMAT csv, HEADER true)" > /dev/null
pm25=$(q -c "SELECT count(*) FROM omopgis.external_exposure WHERE exposure_concept_id = 2052499839")
ses=$(q -c "SELECT count(*) FROM omopgis.external_exposure WHERE exposure_concept_id = 2052497744")
want_pm25=$(q -c "SELECT value FROM demo.expected_result WHERE fixture_tag = 'GLOBAL' AND metric = 'n_pm25_monthly_rows'")
want_ses=$(q -c "SELECT value FROM demo.expected_result WHERE fixture_tag = 'GLOBAL' AND metric = 'n_ses_rows'")
[ "$pm25" = "${want_pm25%%.*}" ] || fail "PM2.5 rows: $pm25, answer key $want_pm25"
[ "$ses" = "${want_ses%%.*}" ] || fail "SES rows: $ses, answer key $want_ses"
per_person=$(q -c "SELECT string_agg(n || ':' || c, ' ' ORDER BY n) FROM (SELECT n, count(*) c FROM (SELECT person_id, count(*) n FROM omopgis.external_exposure WHERE exposure_concept_id = 2052499839 GROUP BY 1) x GROUP BY n) y")
[ "$per_person" = "72:9075 73:925" ] || fail "rows per person: $per_person (expected 72:9075 73:925)"
echo "Tutorial restore check passed: $pm25 PM2.5 rows, $ses SES rows, rows per person $per_person"
