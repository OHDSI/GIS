-- concept_ancestor_delta.csv to concept_ancestor
INSERT INTO test_concept_ancestor (ancestor_concept_id,descendant_concept_id,min_levels_of_separation,max_levels_of_separation)
SELECT ancestor_concept_id,descendant_concept_id,min_levels_of_separation,max_levels_of_separation
FROM   concept_ancestor_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_concept_ancestor ca
                   WHERE  ca.ancestor_concept_id = concept_ancestor_delta.ancestor_concept_id
                     AND ca.descendant_concept_id = concept_ancestor_delta.descendant_concept_id);

-- concept_class_delta.csv to concept_class
INSERT INTO test_concept_class (concept_class_id,concept_class_name,concept_class_concept_id)
SELECT concept_class_id,concept_class_name,concept_class_concept_id
FROM   concept_class_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_concept_class cc
                   WHERE  cc.concept_class_id = concept_class_delta.concept_class_id);

-- concept_delta.csv to concept
INSERT INTO test_concept (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
SELECT concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason
FROM   concept_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_concept c
                   WHERE  c.concept_id = concept_delta.concept_id);
                   
-- concept_relationship_delta.csv to concept_relationship
INSERT INTO test_concept_relationship (concept_id_1,concept_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
SELECT concept_id_1,concept_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason
FROM   concept_relationship_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_concept_relationship cr
                   WHERE  cr.concept_id_1 = concept_relationship_delta.concept_id_1
                     AND cr.concept_id_2 = concept_relationship_delta.concept_id_2
                     AND cr.relationship_id = concept_relationship_delta.relationship_id);

-- concept_synonym_delta.csv to concept_synonym
INSERT INTO test_concept_synonym (concept_id,concept_synonym_name,language_concept_id)
SELECT concept_id,concept_synonym_name,language_concept_id
FROM   concept_synonym_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_concept_synonym cs
                   WHERE  cs.concept_id = concept_synonym_delta.concept_id
                     AND cs.concept_synonym_name = concept_synonym_delta.concept_synonym_name
                     AND cs.language_concept_id = concept_synonym_delta.language_concept_id);
                     
-- domain_delta.csv to domain
INSERT INTO test_domain (domain_id,domain_name,domain_concept_id)
SELECT domain_id,domain_name,domain_concept_id
FROM   domain_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_domain d
                   WHERE  d.domain_concept_id = domain_delta.domain_concept_id); 

-- relationship_delta.csv to relationship
INSERT INTO test_relationship (relationship_id,relationship_name,is_hierarchical,defines_ancestry,reverse_relationship_id,relationship_concept_id)
SELECT relationship_id,relationship_name,is_hierarchical,defines_vocabulary,reverse_relationship_id,relationship_concept_id
FROM   relationship_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_relationship r
                   WHERE  r.relationship_concept_id =
                          relationship_delta.relationship_concept_id);
                          
-- vocabulary_delta.csv to vocabulary
INSERT INTO test_vocabulary (vocabulary_id,vocabulary_name,vocabulary_reference,vocabulary_version,vocabulary_concept_id)
SELECT vocabulary_id,vocabulary_name,vocabulary_reference,vocabulary_version,vocabulary_concept_id
FROM   vocabulary_delta
WHERE  NOT EXISTS (SELECT 1
                   FROM   test_vocabulary v
                   WHERE  v.vocabulary_id = vocabulary_delta.vocabulary_id);
