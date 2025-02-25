--hive CDM DDL Specification for OMOP Common Data Model 5.4
--HINT DISTRIBUTE ON RANDOM
CREATE TABLE @cdmDatabaseSchema.location_history (
			location_id integer NOT NULL,
			relationship_type_concept_id integer NOT NULL,
			domain_id integer NOT NULL,
			entity_id integer NOT NULL,
			start_date TIMESTAMP,
			end_date TIMESTAMP );
--HINT DISTRIBUTE ON KEY (person_id)
CREATE TABLE @cdmDatabaseSchema.external_exposure (
			external_exposure_id integer NOT NULL,
			location_id integer NOT NULL,
			person_id integer NOT NULL,
			exposure_concept_id integer NOT NULL,
			exposure_start_date TIMESTAMP,
			exposure_start_datetime TIMESTAMP,
			exposure_end_date TIMESTAMP,
			exposure_end_datetime TIMESTAMP,
			exposure_type_concept_id integer NOT NULL,
			exposure_relationship_concept_id integer NOT NULL,
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