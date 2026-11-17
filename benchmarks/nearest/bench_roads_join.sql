-- :nloc persons uniform in the extent of the roads (bench_roads.sh sets up the roads); times the nearest join on them; :k and :maxd as in bench_nearest.sql
\set ON_ERROR_STOP on
\if :{?k} \else \set k 1 \endif
\if :{?maxd} \else \set maxd NULL \endif
SET client_min_messages = warning;
BEGIN;
SELECT setseed(0.42);
SELECT ST_XMin(e) AS x0, ST_XMax(e) AS x1, ST_YMin(e) AS y0, ST_YMax(e) AS y1 FROM (SELECT ST_Extent(geom_wgs84) e FROM working.geom_bn_roads) t \gset
INSERT INTO working.location (location_id, geom, longitude, latitude)
SELECT 700000 + i, ST_SetSRID(ST_MakePoint(:x0 + (:x1 - :x0) * random(), :y0 + (:y1 - :y0) * random()), 4326), 0, 0 FROM generate_series(1, :nloc) i;
INSERT INTO working.location_history (location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date)
SELECT 700000 + i, 2052496995, 1147314, 700000 + i, '2014-01-01', '2019-12-31' FROM generate_series(1, :nloc) i;
ANALYZE working.location; ANALYZE working.location_history;
SELECT clock_timestamp() AS t0 \gset
SELECT working.spatial_join_nearest_from_catalog('length_m', 'bn_roads', :k, :maxd) AS n \gset
SELECT clock_timestamp() AS t1 \gset
SELECT :nloc AS nloc, :k AS k, :'maxd' AS maxd, round(extract(epoch FROM (:'t1'::timestamptz - :'t0'::timestamptz))::numeric, 2) AS seconds, :n AS rows;
ROLLBACK;
