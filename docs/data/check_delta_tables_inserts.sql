-- concept_ancestor
SELECT * FROM concept_ancestor 
WHERE ancestor_concept_id IN (SELECT ancestor_concept_id FROM concept_ancestor_delta) 
   OR descendant_concept_id IN (SELECT descendant_concept_id FROM concept_ancestor_delta) 
LIMIT 10;

-- concept_class
SELECT * FROM concept_class 
WHERE concept_class_id IN (SELECT concept_class_id FROM concept_class_delta) 
LIMIT 10;

-- concept
SELECT * FROM concept WHERE concept_id IN (SELECT concept_id FROM concept_delta) 
LIMIT 10;

-- concept_relationship
SELECT * FROM concept_relationship 
WHERE concept_id_1 IN (SELECT concept_id_1 FROM concept_relationship_delta) 
   OR concept_id_2 IN (SELECT concept_id_2 FROM concept_relationship_delta) 
LIMIT 10;

-- concept_synonym
SELECT * FROM concept_synonym 
WHERE concept_id IN (SELECT concept_id FROM concept_synonym_delta) 
LIMIT 10;

-- domain
SELECT * FROM domain 
WHERE domain_id IN (SELECT domain_id FROM domain_delta) 
LIMIT 10;

-- relationship
SELECT * FROM relationship 
WHERE relationship_id IN (SELECT relationship _id FROM relationship_delta) 
LIMIT 10;

-- vocabulary
SELECT * FROM vocabulary 
WHERE vocabulary_id IN (SELECT vocabulary_id FROM vocabulary_delta) 
LIMIT 10;
