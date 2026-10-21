#!/usr/bin/env bash
# Usage: tower/load_for_qgis.sh [--container gaia-db] [--db gaiacore] [--user postgres]
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER=gaia-db; DB=gaiacore; DBUSER=postgres
while [ $# -gt 0 ]; do case "$1" in --container) CONTAINER="$2"; shift ;; --db) DB="$2"; shift ;; --user) DBUSER="$2"; shift ;; *) echo "unknown option $1" >&2; exit 2 ;; esac; shift; done
[ -f "$HERE/data/tower_floors.csv" ] || python3 -I "$HERE/build_tower_dataset.py"

python3 -I - "$HERE/data" <<'PY' | docker exec -i "$CONTAINER" psql -U "$DBUSER" -d "$DB" -v ON_ERROR_STOP=1 -q
import csv, sys
d = sys.argv[1]
def copy(table, cols, rows):
    print(f"CREATE TEMP TABLE {table} ({cols});")
    print(f"COPY {table} FROM STDIN WITH (FORMAT csv);")
    w = csv.writer(sys.stdout, lineterminator="\n")
    for r in rows: w.writerow(r)
    print("\\.")
def read(f): return csv.DictReader(open(f"{d}/{f}", newline=""))
print("BEGIN;")
copy("raw_floor", "floor_id int, floor_number int, wkt text, series jsonb", ([r["floor_id"], r["floor_number"], r["wkt"], r["pm25_floor_mean"]] for r in read("tower_floors.csv")))
copy("raw_sensor", "sensor_id int, floor_number int, sensor_type text, wkt text, series jsonb", ([r["sensor_id"], r["floor_number"], r["sensor_type"], r["wkt"], r["pm25_sensor"]] for r in read("tower_sensors.csv")))
copy("raw_loc", "location_id int, source_value text, lat float8, lon float8, floor_number int", ([r["location_id"], r["location_source_value"], r["latitude"], r["longitude"], r["floor_number"]] for r in read("location.csv")))
copy("raw_lh", "location_id int, entity_id int, start_date date, end_date date", ([r["location_id"], r["entity_id"], r["start_date"], r["end_date"]] for r in read("location_history.csv")))
copy("raw_truth", "person_id int, floor_first int, floor_last int, days int, pm25 float8, ses float8, age int, female int", ([r[c] for c in ("person_id", "floor_first", "floor_last", "days", "pm25_day_weighted", "ses_index", "age", "female")] for r in read("person_exposure_truth.csv")))
copy("raw_cond", "person_id int, outcome text", ([r["person_id"], r["condition_source_value"]] for r in read("condition_occurrence.csv")))
print("""
DROP TABLE IF EXISTS tower_floors, tower_sensors, tower_people;
CREATE TABLE tower_floors AS
SELECT f.floor_number, ST_SetSRID(ST_GeomFromText(f.wkt), 4269)::geometry(Polygon, 4269) AS geom,
       round((SELECT avg(value::numeric) FROM jsonb_each_text(f.series)), 3) AS pm25_annual_mean,
       (SELECT count(*) FROM raw_loc l JOIN raw_lh h USING (location_id) WHERE l.floor_number = f.floor_number AND h.end_date = DATE '2019-12-31') AS residents_at_year_end
FROM raw_floor f ORDER BY f.floor_number;
ALTER TABLE tower_floors ADD PRIMARY KEY (floor_number);
CREATE INDEX tower_floors_geom_idx ON tower_floors USING gist (geom);
CREATE TABLE tower_sensors AS
SELECT s.sensor_id, s.floor_number, s.sensor_type, ST_SetSRID(ST_GeomFromText(s.wkt), 4269)::geometry(Point, 4269) AS geom,
       round((SELECT avg(value::numeric) FROM jsonb_each_text(s.series)), 3) AS pm25_annual_mean
FROM raw_sensor s ORDER BY s.sensor_id;
ALTER TABLE tower_sensors ADD PRIMARY KEY (sensor_id);
CREATE INDEX tower_sensors_geom_idx ON tower_sensors USING gist (geom);
CREATE TABLE tower_people AS
SELECT h.location_id, h.entity_id AS person_id, l.floor_number, h.start_date, h.end_date,
       ST_SetSRID(ST_MakePoint(l.lon, l.lat), 4326)::geometry(Point, 4326) AS geom,
       t.pm25 AS pm25_day_weighted, t.ses AS ses_index, t.age, t.female::boolean AS female,
       EXISTS (SELECT 1 FROM raw_cond c WHERE c.person_id = h.entity_id AND c.outcome = 'COPD') AS copd,
       EXISTS (SELECT 1 FROM raw_cond c WHERE c.person_id = h.entity_id AND c.outcome = 'ASTHMA') AS asthma,
       EXISTS (SELECT 1 FROM raw_cond c WHERE c.person_id = h.entity_id AND c.outcome = 'CKD') AS ckd,
       EXISTS (SELECT 1 FROM raw_cond c WHERE c.person_id = h.entity_id AND c.outcome = 'T2DM') AS t2dm
FROM raw_lh h JOIN raw_loc l USING (location_id) JOIN raw_truth t ON t.person_id = h.entity_id ORDER BY h.location_id;
ALTER TABLE tower_people ADD PRIMARY KEY (location_id);
CREATE INDEX tower_people_geom_idx ON tower_people USING gist (geom);
COMMIT;""")
PY
docker exec "$CONTAINER" psql -U "$DBUSER" -d "$DB" -c "SELECT 'tower_floors' AS tbl, count(*) AS n, min(pm25_annual_mean) AS pm25_min, max(pm25_annual_mean) AS pm25_max FROM tower_floors UNION ALL SELECT 'tower_sensors', count(*), min(pm25_annual_mean), max(pm25_annual_mean) FROM tower_sensors UNION ALL SELECT 'tower_people', count(*), min(pm25_day_weighted)::numeric(6,2), max(pm25_day_weighted)::numeric(6,2) FROM tower_people"
