-- Verify CONCEPT_ANCESTOR_DELTA table:
SELECT COUNT(*) AS concept_ancestor_count FROM concept_ancestor_delta;
SELECT * FROM concept_ancestor_delta LIMIT 10; -- Display first 10 rows for a quick check

-- Verify CONCEPT_CLASS_DELTA table:
SELECT COUNT(*) AS concept_class_count FROM concept_class_delta;
SELECT * FROM concept_class_delta LIMIT 10; -- Display first 10 rows for a quick check

-- Verify CONCEPT_DELTA table:
SELECT COUNT(*) AS concept_count FROM concept_delta;
SELECT * FROM concept_delta LIMIT 10; -- Display first 10 rows for a quick check

-- Verify CONCEPT_RELATIONSHIP_DELTA table:
SELECT COUNT(*) AS concept_relationship_count FROM concept_relationship_delta;
SELECT * FROM concept_relationship_delta LIMIT 10; -- Display first 10 rows for a quick check

-- Verify CONCEPT_SYNONYM_DELTA table:
SELECT COUNT(*) AS concept_synonym_count FROM concept_synonym_delta;
SELECT * FROM concept_synonym_delta LIMIT 10; -- Display first 10 rows for a quick check

-- Verify DOMAIN_DELTA table:
SELECT COUNT(*) AS domain_count FROM domain_delta;
SELECT * FROM domain_delta LIMIT 10; -- Display first 10 rows for a quick check

-- Verify MAPPING_METADATA table:
SELECT COUNT(*) AS mm_count FROM mapping_metadata;
SELECT * FROM mapping_metadata LIMIT 10; -- Display first 10 rows for a quick check

-- Verify RELATIONSHIP_DELTA table:
SELECT COUNT(*) AS relationship_count FROM relationship_delta;
SELECT * FROM relationship_delta LIMIT 10; -- Display first 10 rows for a quick check

-- Verify SOURCE_TO_CONCEPT_MAP table:
SELECT COUNT(*) AS stcm_count FROM source_to_concept_map;
SELECT * FROM source_to_concept_map LIMIT 10; -- Display first 10 rows for a quick check

-- Verify VOCABULARY_DELTA table:
SELECT COUNT(*) AS vocabulary_count FROM vocabulary_delta;
SELECT * FROM vocabulary_delta LIMIT 10; -- Display first 10 rows for a quick check
