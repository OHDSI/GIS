-- DDL Specification for gaiaDB version 001
CREATE TABLE backbone.data_source (
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
			download_url varchar(255) NOT NULL,
			download_auth varchar(100) NULL,
			documentation_url varchar(255) NULL );
CREATE TABLE backbone.variable_source (
			variable_source_id serial4 NOT NULL,
			geom_dependency_uuid int4 NULL,
			variable_name varchar NOT NULL,
			variable_desc text NOT NULL,
			data_source_uuid int4 NOT NULL,
			attr_spec text NOT NULL );
CREATE TABLE backbone.attr_index (
			attr_index_id numeric NOT NULL,
			variable_source_id numeric NOT NULL,
			attr_of_geom_index_id numeric NOT NULL,
			database_schema varchar(255) NOT NULL,
			table_name varchar(255) NOT NULL,
			data_source_id numeric NOT NULL );
CREATE TABLE backbone.geom_index (
			geom_index_id numeric NOT NULL,
			data_type_id numeric NULL,
			data_type_name varchar(255) NOT NULL,
			geom_type_concept_id numeric NULL,
			geom_type_source_value varchar(255) NULL,
			database_schema varchar(255) NOT NULL,
			table_name varchar(255) NOT NULL,
			table_desc varchar(255) NOT NULL,
			data_source_id numeric NOT NULL );
CREATE TABLE backbone.attr_template (
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
CREATE TABLE backbone.geom_template (
			geom_record_id serial4 NOT NULL,
			geom_name varchar NOT NULL,
			geom_source_coding varchar NOT NULL,
			geom_source_value varchar NOT NULL,
			geom_wgs84 geometry NULL,
			geom_local_epsg int4 NOT NULL,
			geom_local_value geometry NOT NULL );