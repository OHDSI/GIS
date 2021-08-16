CREATE TABLE attr_index
(
    attr_index_id serial primary key,
    attr_type_concept_id integer,
    attr_type_source_value varchar,
    attr_of_geom_index_id integer,
    geom_source_coding varchar,
    schema varchar,
    table_name varchar,
    table_desc varchar,
    data_source_id integer
);
