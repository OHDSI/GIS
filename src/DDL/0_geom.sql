CREATE TABLE geom
(
	    geom_record_id serial primary key,
	    name varchar,
	    geom_source_coding varchar,
	    geom_source_value varchar,
	    geom_wgs84 geometry CHECK ( st_srid(geom_wgs84) = 4326 ),
	    geom_local geometry
);
