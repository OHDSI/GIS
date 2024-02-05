CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS backbone;

SET search_path = backbone, public;

CREATE TABLE data_source (
			data_source_uuid int4 NOT NULL,
			org_id varchar(100) NOT NULL,
			org_set_id varchar(100) NOT NULL,
			dataset_name varchar(100) NOT NULL,
			dataset_version varchar(100) NOT NULL,
			geom_type varchar(100) NULL,
			geom_spec text NULL,
			boundary_type varchar(100) NULL,
			has_attributes int4 NULL,
			download_method varchar(100) NOT NULL,
			download_subtype varchar(100) NOT NULL,
			download_data_standard varchar(100) NOT NULL,
			download_filename varchar(100) NOT NULL,
			download_url varchar(100) NOT NULL,
			download_auth varchar(100) NULL,
			documentation_url varchar(100) NULL );
CREATE TABLE variable_source (
			variable_source_id serial4 NOT NULL,
			geom_dependency_uuid int4 NULL,
			variable_name varchar NOT NULL,
			variable_desc text NOT NULL,
			data_source_uuid int4 NOT NULL,
			attr_spec text NOT NULL );
CREATE TABLE attr_index (
			attr_index_id numeric NOT NULL,
			variable_source_id numeric NOT NULL,
			attr_of_geom_index_id numeric NOT NULL,
			database_schema varchar(255) NOT NULL,
			table_name varchar(255) NOT NULL,
			data_source_id numeric NOT NULL );
CREATE TABLE geom_index (
			geom_index_id numeric NOT NULL,
			data_type_id numeric NULL,
			data_type_name varchar(255) NOT NULL,
			geom_type_concept_id numeric NULL,
			geom_type_source_value varchar(255) NULL,
			database_schema varchar(255) NOT NULL,
			table_name varchar(255) NOT NULL,
			table_desc varchar(255) NOT NULL,
			data_source_id numeric NOT NULL );
CREATE TABLE attr_template (
			attr_record_id serial4 NOT NULL,
			geom_record_id int4 NOT NULL,
			variable_source_record_id int4 NOT NULL,
			attr_concept_id int4 NULL,
			attr_start_date date NOT NULL,
			attr_end_date date NOT NULL,
			value_as_number float8 NULL,
			value_as_string varchar NULL,
			value_as_concept_id int4 NULL,
			unit_concept_id int4 NULL,
			unit_source_value varchar NULL,
			qualifier_concept_id int4 NULL,
			qualifier_source_value varchar NULL,
			attr_source_concept_id int4 NULL,
			attr_source_value varchar NOT NULL,
			value_source_value varchar NOT NULL );
CREATE TABLE geom_template (
			geom_record_id serial4 NOT NULL,
			geom_name varchar NOT NULL,
			geom_source_coding varchar NOT NULL,
			geom_source_value varchar NOT NULL,
			geom_wgs84 geometry NULL,
			geom_local_epsg int4 NOT NULL,
			geom_local_value geometry NOT NULL );

CREATE SEQUENCE IF NOT EXISTS attr_index_attr_index_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS attr_template_attr_record_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS variable_source_variable_source_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS geom_index_geom_index_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS geom_template_geom_record_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;-- attr_index definition

\COPY data_source (data_source_uuid, org_id, org_set_id, dataset_name, dataset_version, geom_type, geom_spec, boundary_type, has_attributes, download_method, download_subtype, download_data_standard, download_filename, download_url, download_auth, documentation_url) FROM './inst/csv/data_source.csv' (FORMAT csv, HEADER);
\COPY variable_source (variable_source_id, geom_dependency_uuid, variable_name, variable_desc, data_source_uuid, attr_spec) FROM './inst/csv/variable_source.csv' (FORMAT csv, HEADER);

truncate geom_index;
truncate attr_index;

insert into geom_index
select row_number() over() as geom_index_id
		, null as data_type_id
		, geom_type as data_type_name
		, null as geom_type_concept_id 
		, boundary_type as geom_type_source_value
		, regexp_replace(regexp_replace(lower(concat(org_id, '_', org_set_id)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as database_schema
		, regexp_replace(regexp_replace(lower(concat(dataset_name)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as table_name
		, concat_ws(' ', org_id, org_set_id, dataset_name) as table_desc
		, data_source_uuid as data_source_id
from data_source
where geom_type <> ''
and geom_type is not null
and data_source_uuid not in (
	select data_source_uuid
	from geom_index
);

insert into attr_index 
select row_number() over() as attr_index_id
		, vs.variable_source_id as variable_source_id
		, gi.geom_index_id as attr_of_geom_index_id
		, regexp_replace(regexp_replace(lower(concat(ds.org_id, '_', ds.org_set_id)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as database_schema
		, regexp_replace(regexp_replace(lower(concat(ds.dataset_name)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as table_name
		, ds.data_source_uuid as data_source_id
from data_source ds
inner join variable_source vs
on ds.data_source_uuid = vs.data_source_uuid 
and ds.has_attributes=1
inner join geom_index gi
on gi.data_source_id = vs.geom_dependency_uuid;