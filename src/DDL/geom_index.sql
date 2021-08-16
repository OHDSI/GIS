CREATE TABLE geom_index
(
    geom_index_id serial primary key,
    -- point, polygon...
    data_type_id integer,
    data_type_name varchar,
    -- county, census tract...
    geom_type_concept_id integer,
    geom_type_source_value varchar,
    -- 
    schema varchar,
    table_name varchar,
    table_desc varchar,
    data_source_id integer,
    epsg_local integer,
    epsg_local_name varchar 
);
