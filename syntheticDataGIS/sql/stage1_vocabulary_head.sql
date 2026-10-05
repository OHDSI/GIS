-- Staging tables for the mini vocabulary (filled by COPY ... FROM STDIN from the build script)
CREATE TEMP TABLE stg_concept (concept_id integer, concept_name text, domain_id text, vocabulary_id text, concept_class_id text,
    standard_concept text, concept_code text, valid_start_date date, valid_end_date date, invalid_reason text);
CREATE TEMP TABLE stg_vocabulary (vocabulary_id text, vocabulary_name text, vocabulary_reference text, vocabulary_version text, vocabulary_concept_id integer);
CREATE TEMP TABLE stg_domain (domain_id text, domain_name text, domain_concept_id integer);
CREATE TEMP TABLE stg_concept_class (concept_class_id text, concept_class_name text, concept_class_concept_id integer);
CREATE TEMP TABLE stg_relationship (relationship_id text, relationship_name text, is_hierarchical text, defines_ancestry text,
    reverse_relationship_id text, relationship_concept_id integer);
CREATE TEMP TABLE stg_concept_relationship (concept_id_1 integer, concept_id_2 integer, relationship_id text, valid_start_date date, valid_end_date date, invalid_reason text);
CREATE TEMP TABLE stg_concept_ancestor (ancestor_concept_id integer, descendant_concept_id integer, min_levels_of_separation integer, max_levels_of_separation integer);
CREATE TEMP TABLE stg_concept_synonym (concept_id integer, concept_synonym_name text, language_concept_id integer);
