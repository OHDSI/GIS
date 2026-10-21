#!/bin/bash

psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -c "
DROP TABLE IF EXISTS synthetic_tower_sensors;
CREATE TABLE synthetic_tower_sensors (
  ogc_fid serial PRIMARY KEY,
  geom geometry(Point, 4269),
  sensor_id integer,
  floor_number integer,
  sensor_type varchar,
  pm25_sensor jsonb,
  geom_local geometry(Point, 4269));
INSERT INTO synthetic_tower_sensors (geom, sensor_id, floor_number, sensor_type, pm25_sensor, geom_local)
SELECT geom, sensor_id::integer, floor_number::integer, sensor_type::varchar, pm25_sensor::jsonb, geom
FROM synthetic_tower_sensors_raw ORDER BY sensor_id::integer;
CREATE INDEX synthetic_tower_sensors_geom_geom_idx ON synthetic_tower_sensors USING gist (geom);
DROP TABLE synthetic_tower_sensors_raw;
"
