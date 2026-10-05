-- Standard slice (vocabulary/) plus the OMOP GIS / SDOH / Exposome delta (vocab_temp/); relationships, ancestors
-- and synonyms are kept only when the concepts they mention are in the slice.
INSERT INTO omopgis.concept SELECT DISTINCT ON (concept_id) * FROM stg_concept ORDER BY concept_id;
INSERT INTO omopgis.vocabulary SELECT DISTINCT ON (vocabulary_id) * FROM stg_vocabulary ORDER BY vocabulary_id;
INSERT INTO omopgis.domain SELECT DISTINCT ON (domain_id) * FROM stg_domain ORDER BY domain_id;
INSERT INTO omopgis.concept_class SELECT DISTINCT ON (concept_class_id) * FROM stg_concept_class ORDER BY concept_class_id;
INSERT INTO omopgis.relationship SELECT DISTINCT ON (relationship_id) * FROM stg_relationship ORDER BY relationship_id;
INSERT INTO omopgis.concept_relationship
SELECT r.* FROM stg_concept_relationship r
WHERE EXISTS (SELECT 1 FROM omopgis.concept c WHERE c.concept_id = r.concept_id_1)
  AND EXISTS (SELECT 1 FROM omopgis.concept c WHERE c.concept_id = r.concept_id_2)
ORDER BY 1, 2, 3;
INSERT INTO omopgis.concept_ancestor
SELECT DISTINCT a.* FROM stg_concept_ancestor a
WHERE EXISTS (SELECT 1 FROM omopgis.concept c WHERE c.concept_id = a.ancestor_concept_id)
  AND EXISTS (SELECT 1 FROM omopgis.concept c WHERE c.concept_id = a.descendant_concept_id)
ORDER BY 1, 2;
INSERT INTO omopgis.concept_ancestor
SELECT c.concept_id, c.concept_id, 0, 0 FROM omopgis.concept c
WHERE NOT EXISTS (SELECT 1 FROM omopgis.concept_ancestor a WHERE a.ancestor_concept_id = c.concept_id AND a.descendant_concept_id = c.concept_id);
INSERT INTO omopgis.concept_synonym
SELECT DISTINCT s.* FROM stg_concept_synonym s
WHERE EXISTS (SELECT 1 FROM omopgis.concept c WHERE c.concept_id = s.concept_id)
ORDER BY 1, 2;
