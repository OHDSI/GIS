#!/bin/bash

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.concept_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.concept_gis FROM './vocab_temp/concept_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.vocabulary_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.vocabulary_gis FROM './vocab_temp/vocabulary_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.domain_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.domain_gis FROM './vocab_temp/domain_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.concept_class_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.concept_class_gis FROM './vocab_temp/concept_class_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.concept_relationship_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.concept_relationship_gis FROM './vocab_temp/concept_relationship_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.relationship_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.relationship_gis FROM './vocab_temp/relationship_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.concept_synonym_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.concept_synonym_gis FROM './vocab_temp/concept_synonym_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.concept_ancestor_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.concept_ancestor_gis FROM './vocab_temp/concept_ancestor_delta.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

# drug_strength - no file available
# psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.drug_strength_gis;" 2>/dev/null || true

psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.source_to_concept_map_gis;" 2>/dev/null || true
psql postgresql://localhost:5432 -U postgres -c "\COPY omopgis.source_to_concept_map_gis FROM './vocab_temp/source_to_concept_map.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"')" 2>/dev/null || true

# concept_recommended - no file available
# psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.concept_recommended_gis;" 2>/dev/null || true

# concept_hierarchy - no file available
# psql postgresql://localhost:5432 -U postgres -c "TRUNCATE TABLE omopgis.concept_hierarchy_gis;" 2>/dev/null || true
