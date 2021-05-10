CREATE TABLE attr
(
	    attr_record_id serial primary key,
	    geom_record_id integer REFERENCES geom(geom_record_id),
	    attr_concept_id integer,
	    attr_start_date date,
	    attr_end_date date,
	    value_as_number double precision,
	    value_as_string varchar,
	    value_as_concept_id integer,
	    unit_concept_id integer,
	    unit_source_value varchar,
	    qualifier_concept_id integer,
	    qualifier_source_value varchar,
	    attr_source_concept_id integer,
	    attr_source_value varchar,
	    value_source_value varchar,
	    geom_source_value varchar
);
