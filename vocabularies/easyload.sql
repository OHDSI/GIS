-- For each vocab table, create a temp table, copy the data from the fragment file, and insert into the vocab table.
-- For concept_class, domain, vocabulary, only insert rows that don't already exist in the table.

CREATE TABLE gisdev.temp_concept_data (
    concept_id integer NOT NULL,
    concept_name varchar(255) NOT NULL,
    domain_id varchar(20) NOT NULL,
    vocabulary_id varchar(20) NOT NULL,
    concept_class_id varchar(20) NOT NULL,
    standard_concept varchar(1) NULL,
    concept_code varchar(50) NOT NULL,
    valid_start_date date NOT NULL,
    valid_end_date date NOT NULL,
    invalid_reason varchar(1) NULL
);
\COPY gisdev.temp_concept_data FROM '.\vocabularies\gis_concept_fragment.csv' DELIMITER ',' CSV HEADER;
INSERT INTO gisdev.concept SELECT * FROM gisdev.temp_concept_data;

CREATE TABLE gisdev.temp_concept_relationship_data (
    concept_id_1 int4 NULL,
    concept_id_2 int4 NULL,
    relationship_id varchar(20) NULL,
    valid_start_date date NULL,
    valid_end_date date NULL,
    invalid_reason varchar(1) NULL
);
\COPY gisdev.temp_concept_relationship_data FROM '.\vocabularies\gis_concept_relationship_fragment.csv' DELIMITER ',' CSV HEADER;
INSERT INTO gisdev.concept_relationship SELECT * FROM gisdev.temp_concept_relationship_data;

CREATE TABLE gisdev.temp_concept_class_data (
    concept_class_id varchar(20) NOT NULL,
    concept_class_name varchar(255) NULL,
    concept_class_concept_id int4 NULL
);
\COPY gisdev.temp_concept_class_data FROM '.\vocabularies\gis_concept_class_fragment.csv' DELIMITER ',' CSV HEADER;
-- Insert new concept_class concept_ids (that are not in concept_class) into concept table
INSERT INTO gisdev.concept
SELECT concept_class_concept_id AS concept_id
        , concept_class_name AS concept_name 
        , 'Metadata' AS domain_id
        , 'Concept Class' AS vocabulary_id
        , 'Concept Class' AS concept_class_id
        , '' AS standard_concept
        , 'OMOP generated' AS concept_code
        , '1970-01-01' AS valid_start_date
        , '2099-12-31' AS valid_end_date
        , '' AS invalid_reason
FROM gisdev.temp_concept_class_data
WHERE concept_class_id NOT IN (
    SELECT concept_class_id
    FROM prod.concept_class
);
INSERT INTO gisdev.concept_class SELECT * FROM gisdev.temp_concept_class_data WHERE concept_class_id NOT IN (SELECT concept_class_id FROM gisdev.concept_class);



CREATE TABLE gisdev.temp_domain_data (
    domain_id varchar(20) NOT NULL,
    domain_name varchar(255) NULL,
    domain_concept_id int4 NULL
);
\COPY gisdev.temp_domain_data FROM '.\vocabularies\gis_domain_fragment.csv' DELIMITER ',' CSV HEADER;
-- Insert new domain concept_ids (that are not in domain) into concept table
INSERT INTO gisdev.concept
SELECT domain_concept_id AS concept_id
        , domain_name AS concept_name 
        , 'Metadata' AS domain_id
        , 'Domain' AS vocabulary_id
        , 'Domain' AS concept_class_id
        , '' AS standard_concept
        , 'OMOP generated' AS concept_code
        , '1970-01-01' AS valid_start_date
        , '2099-12-31' AS valid_end_date
        , '' AS invalid_reason
FROM gisdev.temp_domain_data
WHERE domain_id NOT IN (
    SELECT domain_id
    FROM prod.domain
);
INSERT INTO gisdev.domain SELECT * FROM gisdev.temp_domain_data WHERE domain_id NOT IN (SELECT domain_id FROM gisdev.domain);

CREATE TABLE gisdev.temp_vocabulary_data (
    vocabulary_id varchar(20) NOT NULL,
    vocabulary_name varchar(255) NULL,
    vocabulary_reference varchar(255) NULL,
    vocabulary_version varchar(255) NULL,
    vocabulary_concept_id int4 NULL
);
\COPY gisdev.temp_vocabulary_data FROM '.\vocabularies\gis_vocabulary_fragment.csv' DELIMITER ',' CSV HEADER;
-- Insert new vocabulary concept_ids (that are not in vocabulary) into concept table
INSERT INTO gisdev.concept
SELECT vocabulary_concept_id AS concept_id
        , vocabulary_name AS concept_name 
        , 'Metadata' AS vocabulary_id
        , 'Vocabulary' AS domain_id
        , 'Vocabulary' AS concept_class_id
        , '' AS standard_concept
        , 'OMOP generated' AS concept_code
        , '1970-01-01' AS valid_start_date
        , '2099-12-31' AS valid_end_date
        , '' AS invalid_reason
FROM gisdev.temp_vocabulary_data
WHERE vocabulary_id NOT IN (
    SELECT vocabulary_id
    FROM prod.vocabulary
);
INSERT INTO gisdev.vocabulary SELECT * FROM gisdev.temp_vocabulary_data WHERE vocabulary_id NOT IN (SELECT vocabulary_id FROM gisdev.vocabulary);

-- Drop all temporary tables
DROP TABLE gisdev.temp_concept_data;
DROP TABLE gisdev.temp_concept_relationship_data;
DROP TABLE gisdev.temp_concept_class_data;
DROP TABLE gisdev.temp_domain_data;
DROP TABLE gisdev.temp_vocabulary_data;