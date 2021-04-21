CREATE TABLE geom
(
	    geom_record_id integer primary key,
	    name varchar,
	    geom_source_coding varchar,
	    geom_source_value varchar,
	    geom_wgs84 geometry(MultiPolygon,4326),
	    geom_local geometry
);