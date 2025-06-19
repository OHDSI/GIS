DROP TABLE IF EXISTS concept_ancestor_delta;
DROP TABLE IF EXISTS concept_class_delta;
DROP TABLE IF EXISTS concept_delta;
DROP TABLE IF EXISTS concept_relationship_delta;
DROP TABLE IF EXISTS concept_synonym_delta;
DROP TABLE IF EXISTS domain_delta;
DROP TABLE IF EXISTS mapping_metadata;
DROP TABLE IF EXISTS relationship_delta;
DROP TABLE IF EXISTS source_to_concept_map;
DROP TABLE IF EXISTS vocabulary_delta;

CREATE TABLE concept_ancestor_delta
  (
     ancestor_concept_id      INTEGER,
     descendant_concept_id    INTEGER,
     min_levels_of_separation INTEGER,
     max_levels_of_separation INTEGER,
     PRIMARY KEY (ancestor_concept_id, descendant_concept_id)
  );

CREATE TABLE concept_class_delta
  (
     concept_class_id         VARCHAR(25) PRIMARY KEY,
     concept_class_name       VARCHAR(255),
     concept_class_concept_id INT
  );

CREATE TABLE concept_delta
  (
     concept_id       INTEGER PRIMARY KEY,
     concept_name     VARCHAR(255),
     domain_id        VARCHAR(25),
     vocabulary_id    VARCHAR(20),
     concept_class_id VARCHAR(25),
     standard_concept VARCHAR(1),
     concept_code     VARCHAR(50),
     valid_start_date DATE,
     valid_end_date   DATE,
     invalid_reason   VARCHAR(1)
  );

CREATE TABLE concept_relationship_delta
  (
     concept_id_1     INTEGER,
     concept_id_2     INTEGER,
     relationship_id  VARCHAR(20),
     valid_start_date DATE,
     valid_end_date   DATE,
     invalid_reason   VARCHAR(1),
     PRIMARY KEY (concept_id_1, concept_id_2, relationship_id)
  );

CREATE TABLE concept_synonym_delta
  (
     concept_id           INTEGER,
     concept_synonym_name VARCHAR(1000),
     language_concept_id  INTEGER
  );

CREATE TABLE domain_delta
  (
     domain_id         VARCHAR(25) PRIMARY KEY,
     domain_name       VARCHAR(255),
     domain_concept_id INTEGER
  );

CREATE TABLE mapping_metadata
  (
     mapping_concept_id    INTEGER,
     mapping_concept_code  VARCHAR(255),
     confidence            FLOAT,
     predicate_id          VARCHAR(255),
     mapping_justification VARCHAR(255),
     mapping_provider      VARCHAR(255),
     author_id             INTEGER,
     author_label          VARCHAR(255),
     reviewer_id           INTEGER,
     reviewer_label        VARCHAR(255),
     mapping_tool          VARCHAR(255),
     mapping_tool_version  VARCHAR(255)
  );

CREATE TABLE relationship_delta
  (
     relationship_id         VARCHAR(20) PRIMARY KEY,
     relationship_name       VARCHAR(255),
     is_hierarchical         INTEGER,
     defines_vocabulary      SMALLINT,
     reverse_relationship_id VARCHAR(20),
     relationship_concept_id INTEGER
  );

CREATE TABLE source_to_concept_map
  (
     source_code             VARCHAR(50) NOT NULL,
     source_vocabulary_id    VARCHAR(20) NOT NULL,
     source_code_description VARCHAR(255) NULL,
     target_concept_id       INTEGER NOT NULL,
     target_vocabulary_id    VARCHAR(20) NOT NULL,
     valid_start_date        DATE NOT NULL,
     valid_end_date          DATE NOT NULL,
     invalid_reason          VARCHAR(1) NULL
  );

CREATE TABLE vocabulary_delta
  (
     vocabulary_id         VARCHAR(20) PRIMARY KEY,
     vocabulary_name       VARCHAR(255),
     vocabulary_reference  VARCHAR(255),
     vocabulary_version    VARCHAR(255),
     vocabulary_concept_id INTEGER,
     latest_update         DATE,
     dev_schema_name       TEXT,
     vocabulary_params     JSONB
  );  
