-- DROP SCHEMA backbone;

CREATE SCHEMA IF NOT EXISTS backbone AUTHORIZATION postgres;

-- DROP SEQUENCE backbone.attr_index_attr_index_id_seq;

CREATE SEQUENCE IF NOT EXISTS backbone.attr_index_attr_index_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE backbone.attr_template_attr_record_id_seq;

CREATE SEQUENCE IF NOT EXISTS backbone.attr_template_attr_record_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE backbone.variable_source_variable_source_id_seq;

CREATE SEQUENCE IF NOT EXISTS backbone.variable_source_variable_source_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE backbone.geom_index_geom_index_id_seq;

CREATE SEQUENCE IF NOT EXISTS backbone.geom_index_geom_index_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE backbone.geom_template_geom_record_id_seq;

CREATE SEQUENCE IF NOT EXISTS backbone.geom_template_geom_record_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;-- backbone.attr_index definition

-- Drop table

-- DROP TABLE backbone.attr_index;

CREATE TABLE IF NOT EXISTS backbone.attr_index (
	attr_index_id serial4 NOT NULL,
	attr_of_geom_index_id int4 NULL,
	table_schema varchar NULL,
	table_name varchar NULL,
	data_source_id int4 NULL,
	CONSTRAINT attr_index_pkey PRIMARY KEY (attr_index_id)
);


-- backbone.attr_template definition

-- Drop table

-- DROP TABLE backbone.attr_template;

CREATE TABLE IF NOT EXISTS backbone.attr_template (
	attr_record_id serial4 NOT NULL,
	geom_record_id int4 NULL,
	variable_source_record_id int4 NOT NULL,
	attr_concept_id int4 NULL,
	attr_start_date date NULL,
	attr_end_date date NULL,
	value_as_number float8 NULL,
	value_as_string varchar NULL,
	value_as_concept_id int4 NULL,
	unit_concept_id int4 NULL,
	unit_source_value varchar NULL,
	qualifier_concept_id int4 NULL,
	qualifier_source_value varchar NULL,
	attr_source_concept_id int4 NULL,
	attr_source_value varchar NULL,
	value_source_value varchar NULL
);


-- backbone.data_source definition

-- Drop table

-- DROP TABLE backbone.data_source;

CREATE TABLE IF NOT EXISTS backbone.data_source (
	data_source_uuid int4 NULL,
	org_id varchar(100) NULL,
	org_set_id varchar(100) NULL,
	dataset_name varchar(100) NULL,
	dataset_version varchar(100) NULL,
	geom_type varchar(100) NULL,
	geom_spec text NULL,
	boundary_type varchar(100) NULL,
	has_attributes int4 NULL,
	geom_dependency_uuid int4 NULL,
	download_method varchar(100) NULL,
	download_subtype varchar(100) NULL,
	download_data_standard varchar(100) NULL,
	download_filename varchar(100) NULL,
	download_url varchar(100) NULL,
	download_auth varchar(100) NULL,
	documentation_url varchar(100) NULL
);


-- backbone.variable_source definition

-- Drop table

-- DROP TABLE backbone.variable_source;

CREATE TABLE IF NOT EXISTS backbone.variable_source (
	variable_source_id serial4 NOT NULL,
	variable_name varchar NOT NULL,
	variable_desc text NULL,
	data_source_uuid int4 NOT NULL,
	attr_spec text NULL
);


-- backbone.geom_index definition

-- Drop table

-- DROP TABLE backbone.geom_index;

CREATE TABLE IF NOT EXISTS backbone.geom_index (
	geom_index_id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
	data_type_id int4 NULL,
	data_type_name varchar NULL,
	geom_type_concept_id int4 NULL,
	geom_type_source_value varchar NULL,
	table_schema varchar NULL,
	table_name varchar NULL,
	table_desc varchar NULL,
	data_source_id int4 NULL,
	CONSTRAINT geom_index_pkey PRIMARY KEY (geom_index_id)
);


-- backbone.geom_template definition

-- Drop table

-- DROP TABLE backbone.geom_template;

CREATE TABLE IF NOT EXISTS backbone.geom_template (
	geom_record_id serial4 NOT NULL,
	geom_name varchar NULL,
	geom_source_coding varchar NULL,
	geom_source_value varchar NULL,
	geom_wgs84 public.geometry NULL,
	geom_local_epsg int4 NULL,
	geom_local_value public.geometry NULL
);
