--sql server DDL Specification for Gaia Results Exposure Occurrence 001
--HINT DISTRIBUTE ON KEY (person_id)
CREATE TABLE @cdmDatabaseSchema.exposure_occurrence (
			exposure_occurrence_id integer NOT NULL,
			location_id integer NOT NULL,
			person_id integer NOT NULL,
			cohort_definition_id integer NULL,
			exposure_concept_id integer NOT NULL,
			exposure_start_date date NOT NULL,
			exposure_start_datetime datetime NULL,
			exposure_end_date date NOT NULL,
			exposure_end_datetime datetime NULL,
			exposure_type_concept_id integer NOT NULL,
			exposure_relationship_concept_id integer NOT NULL,
			exposure_source_concept_id integer NULL,
			exposure_source_value varchar(50) NULL,
			exposure_relationship_source_value varchar(50) NULL,
			dose_unit_source_value varchar(50) NULL,
			quantity integer NULL,
			modifier_source_value varchar(50) NULL,
			operator_concept_id integer NULL,
			value_as_number float NULL,
			value_as_concept_id integer NULL,
			unit_concept_id integer NULL );