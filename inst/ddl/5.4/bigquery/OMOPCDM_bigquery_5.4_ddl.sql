--bigquery CDM DDL Specification for OMOP Common Data Model 5.4
--HINT DISTRIBUTE ON RANDOM
create table @cdmDatabaseSchema.location_history (
			location_id INT64 not null,
			relationship_type_concept_id INT64 not null,
			domain_id INT64 not null,
			entity_id INT64 not null,
			start_date date not null,
			end_date DATE );
--HINT DISTRIBUTE ON KEY (person_id)
create table @cdmDatabaseSchema.external_exposure (
			external_exposure_id INT64 not null,
			location_id INT64 not null,
			person_id INT64 not null,
			exposure_concept_id INT64 not null,
			exposure_start_date date not null,
			exposure_start_datetime DATETIME,
			exposure_end_date date not null,
			exposure_end_datetime DATETIME,
			exposure_type_concept_id INT64 not null,
			exposure_relationship_concept_id INT64 not null,
			exposure_source_concept_id INT64,
			exposure_source_value STRING,
			exposure_relationship_source_value STRING,
			dose_unit_source_value STRING,
			quantity INT64,
			modifier_source_value STRING,
			operator_concept_id INT64,
			value_as_number FLOAT64,
			value_as_concept_id INT64,
			unit_concept_id INT64 );