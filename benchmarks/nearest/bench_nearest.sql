-- Timing of working.spatial_join_nearest_from_catalog (#536): :nloc person locations, :npts monitors, 3 annual windows.
--   psql -U postgres -d gaiacore -v npts=10000 -v nloc=10000 [-v k=1] [-v fn=working.spatial_join_nearest_from_catalog] -f bench_nearest.sql
-- Points and persons are uniform random in a 100 km x 100 km window (EPSG:5070 near Los Angeles), seed 0.42.
-- Prints one line: npts, nloc, k, seconds of the join, rows inserted. Everything rolls back.
\set ON_ERROR_STOP on
\if :{?k} \else \set k 1 \endif
\if :{?fn} \else \set fn working.spatial_join_nearest_from_catalog \endif
\set QUIET on
SET client_min_messages = warning;
BEGIN;
SELECT setseed(0.42);
CREATE TABLE public.bn_pts (ogc_fid serial PRIMARY KEY, geom geometry(Point, 4269), monitor_id integer, pm25 jsonb, geom_local geometry(Point, 4269));
INSERT INTO public.bn_pts (geom, monitor_id, pm25, geom_local)
SELECT g, i, jsonb_build_object('2014-01-01/2014-12-31', v, '2015-01-01/2015-12-31', v + 1, '2016-01-01/2016-12-31', v + 2), g
FROM (SELECT i, 10 + 5 * random() AS v,
             ST_Transform(ST_SetSRID(ST_MakePoint(-2075500 + 100000 * random(), 1413500 + 100000 * random()), 5070), 4269) AS g
      FROM generate_series(1, :npts) i) s;
INSERT INTO working.location (location_id, geom, longitude, latitude)
SELECT 800000 + i, g, ST_X(g), ST_Y(g)
FROM (SELECT i, ST_Transform(ST_SetSRID(ST_MakePoint(-2075500 + 100000 * random(), 1413500 + 100000 * random()), 5070), 4326) AS g
      FROM generate_series(1, :nloc) i) s;
INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date)
SELECT 800000 + i, 2052496995, 1147314, 800000 + i, '2014-01-01', '2016-12-31' FROM generate_series(1, :nloc) i;
SELECT backbone.gdsc_load_variable($${"table_id": "bn_pts", "variable_id": "pm25", "geom_type": "point", "table_description": "bench", "geom_label": "monitor_id",
  "description": "bench", "concept_id": "2052499839", "start_date": "2014-01-01", "end_date": "2016-12-31", "source": "bench"}$$::jsonb) \gset
ANALYZE working.geom_bn_pts; ANALYZE working.attr_bn_pts;
SELECT clock_timestamp() AS t0 \gset
SELECT :fn('pm25', 'bn_pts', :k) AS n \gset
SELECT clock_timestamp() AS t1 \gset
SELECT :npts AS npts, :nloc AS nloc, :k AS k, round(extract(epoch FROM (:'t1'::timestamptz - :'t0'::timestamptz))::numeric, 2) AS seconds, :n AS rows;
ROLLBACK;
