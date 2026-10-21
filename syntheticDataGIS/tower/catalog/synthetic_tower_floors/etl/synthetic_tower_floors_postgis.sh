#!/bin/bash

psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -c "
DROP TABLE IF EXISTS synthetic_tower_floors;
CREATE TABLE synthetic_tower_floors (
  ogc_fid serial PRIMARY KEY,
  geom geometry(MultiPolygon, 4269),
  floor_id integer,
  floor_number integer,
  pm25_floor_mean jsonb,
  geom_local geometry(MultiPolygon, 4269));
INSERT INTO synthetic_tower_floors (geom, floor_id, floor_number, pm25_floor_mean, geom_local)
SELECT ST_Multi(geom), floor_id::integer, floor_number::integer, pm25_floor_mean::jsonb, ST_Multi(geom)
FROM synthetic_tower_floors_raw ORDER BY floor_id::integer;
CREATE INDEX synthetic_tower_floors_geom_geom_idx ON synthetic_tower_floors USING gist (geom);
DROP TABLE synthetic_tower_floors_raw;
"
