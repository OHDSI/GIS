--HINT DISTRIBUTE ON RANDOM
CREATE TABLE @cdmDatabaseSchema.location_history  
USING DELTA
 AS
SELECT
CAST(NULL AS integer) AS location_id,
	CAST(NULL AS integer) AS relationship_type_concept_id,
	CAST(NULL AS integer) AS domain_id,
	CAST(NULL AS integer) AS entity_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS start_date,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS end_date  WHERE 1 = 0;
--HINT DISTRIBUTE ON KEY (person_id)
CREATE TABLE @cdmDatabaseSchema.external_exposure  
USING DELTA
 AS
SELECT
CAST(NULL AS integer) AS external_exposure_id,
	CAST(NULL AS integer) AS location_id,
	CAST(NULL AS integer) AS person_id,
	CAST(NULL AS integer) AS exposure_concept_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS exposure_start_date,
	CAST(NULL AS TIMESTAMP) AS exposure_start_datetime,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS exposure_end_date,
	CAST(NULL AS TIMESTAMP) AS exposure_end_datetime,
	CAST(NULL AS integer) AS exposure_type_concept_id,
	CAST(NULL AS integer) AS exposure_relationship_concept_id,
	CAST(NULL AS integer) AS exposure_source_concept_id,
	CAST(NULL AS STRING) AS exposure_source_value,
	CAST(NULL AS STRING) AS exposure_relationship_source_value,
	CAST(NULL AS STRING) AS dose_unit_source_value,
	CAST(NULL AS integer) AS quantity,
	CAST(NULL AS STRING) AS modifier_source_value,
	CAST(NULL AS integer) AS operator_concept_id,
	CAST(NULL AS float) AS value_as_number,
	CAST(NULL AS integer) AS value_as_concept_id,
	CAST(NULL AS integer) AS unit_concept_id  WHERE 1 = 0;