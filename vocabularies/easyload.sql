-- For each vocab table, create a temp table, copy the data from the fragment file, and insert into the vocab table.
-- For concept_class, domain, relationship, vocabulary, only insert rows that don't already exist in the table.

-- ADD VOCABULARIES
CREATE TABLE @devVocabSchema.temp_vocabulary_data (
    vocabulary_id varchar(20) NOT NULL,
    vocabulary_name varchar(255) NULL,
    vocabulary_reference varchar(255) NULL,
    vocabulary_version varchar(255) NULL,
    vocabulary_concept_id int4 NULL
);
\COPY @devVocabSchema.temp_vocabulary_data FROM '@absolutePath\gis_vocabulary_fragment.csv' DELIMITER ',' CSV HEADER;
-- Insert new vocabulary concept_ids (that are not in vocabulary) into concept table
INSERT INTO @devVocabSchema.concept
SELECT vocabulary_concept_id AS concept_id
        , vocabulary_name AS concept_name 
        , 'Metadata' AS domain_id
        , 'Vocabulary' AS vocabulary_id
        , 'Vocabulary' AS concept_class_id
        , '' AS standard_concept
        , 'OMOP generated' AS concept_code
        , '1970-01-01' AS valid_start_date
        , '2099-12-31' AS valid_end_date
        , '' AS invalid_reason
FROM @devVocabSchema.temp_vocabulary_data
WHERE vocabulary_id NOT IN (
    SELECT vocabulary_id
    FROM @devVocabSchema.vocabulary
);
INSERT INTO @devVocabSchema.vocabulary SELECT * FROM @devVocabSchema.temp_vocabulary_data WHERE vocabulary_id NOT IN (SELECT vocabulary_id FROM @devVocabSchema.vocabulary);

-- ADD CONCEPT_CLASSES
CREATE TABLE @devVocabSchema.temp_concept_class_data (
    concept_class_id varchar(20) NOT NULL,
    concept_class_name varchar(255) NULL,
    concept_class_concept_id int4 NULL
);
\COPY @devVocabSchema.temp_concept_class_data FROM '@absolutePath\gis_concept_class_fragment.csv' DELIMITER ',' CSV HEADER;
-- Insert new concept_class concept_ids (that are not in concept_class) into concept table
INSERT INTO @devVocabSchema.concept
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
FROM @devVocabSchema.temp_concept_class_data
WHERE concept_class_id NOT IN (
    SELECT concept_class_id
    FROM @devVocabSchema.concept_class
);
INSERT INTO @devVocabSchema.concept_class SELECT * FROM @devVocabSchema.temp_concept_class_data WHERE concept_class_id NOT IN (SELECT concept_class_id FROM @devVocabSchema.concept_class);

-- ADD DOMAINS
CREATE TABLE @devVocabSchema.temp_domain_data (
    domain_id varchar(20) NOT NULL,
    domain_name varchar(255) NULL,
    domain_concept_id int4 NULL
);
\COPY @devVocabSchema.temp_domain_data FROM '@absolutePath\gis_domain_fragment.csv' DELIMITER ',' CSV HEADER;
-- Insert new domain concept_ids (that are not in domain) into concept table
INSERT INTO @devVocabSchema.concept
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
FROM @devVocabSchema.temp_domain_data
WHERE domain_id NOT IN (
    SELECT domain_id
    FROM @devVocabSchema.domain
);
INSERT INTO @devVocabSchema.domain SELECT * FROM @devVocabSchema.temp_domain_data WHERE domain_id NOT IN (SELECT domain_id FROM @devVocabSchema.domain);

-- ADD CONCEPTS
CREATE TABLE @devVocabSchema.temp_concept_data (
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
\COPY @devVocabSchema.temp_concept_data FROM '@absolutePath\gis_concept_fragment.csv' DELIMITER ',' CSV HEADER;
INSERT INTO @devVocabSchema.concept SELECT * FROM @devVocabSchema.temp_concept_data;

-- ADD RELATIONSHIPS
CREATE TABLE @devVocabSchema.temp_relationship_data (
    relationship_id varchar(20) NOT NULL,
	relationship_name varchar(255) NULL,
	is_hierarchical varchar(1) NULL,
	defines_ancestry varchar(1) NULL,
	reverse_relationship_id varchar(20) NULL,
	relationship_concept_id int4 NULL
);
\COPY @devVocabSchema.temp_relationship_data FROM '@absolutePath\gis_relationship_fragment.csv' DELIMITER ',' CSV HEADER;
-- Insert new relationship concept_ids (that are not in relationship) into concept table
INSERT INTO @devVocabSchema.concept
SELECT relationship_concept_id AS concept_id
        , relationship_name AS concept_name 
        , 'Metadata' AS domain_id
        , 'Relationship' AS vocabulary_id
        , 'Relationship' AS concept_class_id
        , '' AS standard_concept
        , 'OMOP generated' AS concept_code
        , '1970-01-01' AS valid_start_date
        , '2099-12-31' AS valid_end_date
        , '' AS invalid_reason
FROM @devVocabSchema.temp_relationship_data;
INSERT INTO @devVocabSchema.relationship SELECT * FROM @devVocabSchema.temp_relationship_data;

-- ADD CONCEPT_RELATIONSHIPS
CREATE TABLE @devVocabSchema.temp_concept_relationship_data (
    concept_id_1 int4 NULL,
    concept_id_2 int4 NULL,
    relationship_id varchar(20) NULL,
    valid_start_date date NULL,
    valid_end_date date NULL,
    invalid_reason varchar(1) NULL
);
\COPY @devVocabSchema.temp_concept_relationship_data FROM '@absolutePath\gis_concept_relationship_fragment.csv' DELIMITER ',' CSV HEADER;
INSERT INTO @devVocabSchema.concept_relationship SELECT * FROM @devVocabSchema.temp_concept_relationship_data;

-- ADD REVERSE CONCEPT_RELATIONSHIPS (WHERE MISSING)
INSERT INTO @devVocabSchema.concept_relationship
select rev.*
from (
	select cr.concept_id_2 as concept_id_1
			, cr.concept_id_1 as concept_id_2 
			, r.reverse_relationship_id as relationship_id
			, cr.valid_start_date 
			, cr.valid_end_date 
			, cr.invalid_reason
	from @devVocabSchema.concept_relationship cr
	inner join relationship r 
	on cr.relationship_id = r.relationship_id 
	and  cr.concept_id_1 > 2000000000
) rev
left join (
	select *
	from @devVocabSchema.concept_relationship
		where concept_id_1 > 2000000000
) orig
on rev.concept_id_1 = orig.concept_id_1
and rev.concept_id_2 = orig.concept_id_2
and rev.relationship_id = orig.relationship_id
where orig.concept_id_1 is NULL;

-- Drop all temporary tables
DROP TABLE @devVocabSchema.temp_concept_data;
DROP TABLE @devVocabSchema.temp_concept_relationship_data;
DROP TABLE @devVocabSchema.temp_concept_class_data;
DROP TABLE @devVocabSchema.temp_domain_data;
DROP TABLE @devVocabSchema.temp_vocabulary_data;