--impala CDM DDL Specification for OMOP Common Data Model 5.4
--HINT DISTRIBUTE ON RANDOM
CREATE TABLE @cdmDatabaseSchema.location_history (
			location_id INT,
			relationship_type_concept_id INT,
			domain_id INT,
			entity_id INT,
			start_date TIMESTAMP,
			end_date TIMESTAMP );
--HINT DISTRIBUTE ON KEY (person_id)
CREATE TABLE @cdmDatabaseSchema.external_exposure (
			external_exposure_id INT,
			location_id INT,
			person_id INT,
			exposure_concept_id INT,
			exposure_start_date TIMESTAMP,
			exposure_start_datetime TIMESTAMP,
			exposure_end_date TIMESTAMP,
			exposure_end_datetime TIMESTAMP,
			exposure_type_concept_id INT,
			exposure_relationship_concept_id INT,
			exposure_source_concept_id integer NULL,
			exposure_source_value VARCHAR(50),
			exposure_relationship_source_value VARCHAR(50),
			dose_unit_source_value VARCHAR(50),
			quantity integer NULL,
			modifier_source_value VARCHAR(50),
			operator_concept_id integer NULL,
			value_as_number FLOAT,
			value_as_concept_id integer NULL,
			unit_concept_id integer NULL );