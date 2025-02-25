--pdw CDM DDL Specification for OMOP Common Data Model 5.4
--HINT DISTRIBUTE ON RANDOM
IF XACT_STATE() = 1 COMMIT; CREATE TABLE @cdmDatabaseSchema.location_history  (location_id integer NOT NULL,
			relationship_type_concept_id integer NOT NULL,
			domain_id integer NOT NULL,
			entity_id integer NOT NULL,
			start_date date NOT NULL,
			end_date date NULL )
WITH (DISTRIBUTION = REPLICATE);
--HINT DISTRIBUTE ON KEY (person_id)
IF XACT_STATE() = 1 COMMIT; CREATE TABLE @cdmDatabaseSchema.external_exposure  (external_exposure_id integer NOT NULL,
			location_id integer NOT NULL,
			 person_id integer NOT NULL,
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
			unit_concept_id integer NULL )
WITH (DISTRIBUTION = HASH(person_id));