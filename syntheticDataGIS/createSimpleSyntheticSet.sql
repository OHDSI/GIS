--postgresql CDM DDL Specification for OMOP Common Data Model 5.4
-- Synthetic Dataset with GIS/SDOH Extension
-- Focus: Respiratory conditions (Asthma) with environmental and socioeconomic determinants
-- Dataset: 10,000 patients with ~3,000 asthma cases correlated with air pollution exposure

CREATE SCHEMA IF NOT EXISTS omopgis;

DROP TABLE IF EXISTS omopgis.DEATH CASCADE;
DROP TABLE IF EXISTS omopgis.MEASUREMENT CASCADE;
DROP TABLE IF EXISTS omopgis.CONDITION_OCCURRENCE CASCADE;
DROP TABLE IF EXISTS omopgis.OBSERVATION CASCADE;
DROP TABLE IF EXISTS omopgis.DRUG_EXPOSURE CASCADE;
DROP TABLE IF EXISTS omopgis.PROCEDURE_OCCURRENCE CASCADE;
DROP TABLE IF EXISTS omopgis.OBSERVATION_PERIOD CASCADE;
DROP TABLE IF EXISTS omopgis.CDM_SOURCE CASCADE;
DROP TABLE IF EXISTS omopgis.VISIT_OCCURRENCE CASCADE;
DROP TABLE IF EXISTS omopgis.PERSON CASCADE;
DROP TABLE IF EXISTS omopgis.DRUG_ERA CASCADE;
DROP TABLE IF EXISTS omopgis.CONDITION_ERA CASCADE;
DROP TABLE IF EXISTS omopgis.FACT_RELATIONSHIP CASCADE;
DROP TABLE IF EXISTS omopgis.PROVIDER CASCADE;
DROP TABLE IF EXISTS omopgis.CARE_SITE CASCADE;
DROP TABLE IF EXISTS omopgis.VISIT_DETAIL CASCADE;
DROP TABLE IF EXISTS omopgis.DEVICE_EXPOSURE CASCADE;
DROP TABLE IF EXISTS omopgis.SPECIMEN CASCADE;
DROP TABLE IF EXISTS omopgis.NOTE CASCADE;
DROP TABLE IF EXISTS omopgis.COST CASCADE;
DROP TABLE IF EXISTS omopgis.DOSE_ERA CASCADE;
DROP TABLE IF EXISTS omopgis.LOCATION CASCADE;
DROP TABLE IF EXISTS omopgis.NOTE_NLP CASCADE;
DROP TABLE IF EXISTS omopgis.PAYER_PLAN_PERIOD CASCADE;
DROP TABLE IF EXISTS omopgis.METADATA CASCADE;
DROP TABLE IF EXISTS omopgis.EPISODE CASCADE;
DROP TABLE IF EXISTS omopgis.EPISODE_EVENT CASCADE;


CREATE TABLE IF NOT EXISTS omopgis.PERSON
(
    person_id                   integer     NOT NULL,
    gender_concept_id           integer     NOT NULL,
    year_of_birth               integer     NOT NULL,
    month_of_birth              integer     NULL,
    day_of_birth                integer     NULL,
    birth_datetime              TIMESTAMP   NULL,
    race_concept_id             integer     NOT NULL,
    ethnicity_concept_id        integer     NOT NULL,
    location_id                 integer     NULL,
    provider_id                 integer     NULL,
    care_site_id                integer     NULL,
    person_source_value         varchar(50) NULL,
    gender_source_value         varchar(50) NULL,
    gender_source_concept_id    integer     NULL,
    race_source_value           varchar(50) NULL,
    race_source_concept_id      integer     NULL,
    ethnicity_source_value      varchar(50) NULL,
    ethnicity_source_concept_id integer     NULL
);


CREATE TABLE IF NOT EXISTS omopgis.OBSERVATION_PERIOD
(
    observation_period_id         serial  PRIMARY KEY,
    person_id                     integer NOT NULL,
    observation_period_start_date date    NOT NULL,
    observation_period_end_date   date    NOT NULL,
    period_type_concept_id        integer NOT NULL
);


CREATE TABLE IF NOT EXISTS omopgis.VISIT_OCCURRENCE
(
    visit_occurrence_id           integer     NOT NULL,
    person_id                     integer     NOT NULL,
    visit_concept_id              integer     NOT NULL,
    visit_start_date              date        NOT NULL,
    visit_start_datetime          TIMESTAMP   NULL,
    visit_end_date                date        NOT NULL,
    visit_end_datetime            TIMESTAMP   NULL,
    visit_type_concept_id         Integer     NOT NULL,
    provider_id                   integer     NULL,
    care_site_id                  integer     NULL,
    visit_source_value            varchar(50) NULL,
    visit_source_concept_id       integer     NULL,
    admitted_from_concept_id      integer     NULL,
    admitted_from_source_value    varchar(50) NULL,
    discharged_to_concept_id      integer     NULL,
    discharged_to_source_value    varchar(50) NULL,
    preceding_visit_occurrence_id integer     NULL
);


CREATE TABLE IF NOT EXISTS omopgis.VISIT_DETAIL
(
    visit_detail_id                integer     NOT NULL,
    person_id                      integer     NOT NULL,
    visit_detail_concept_id        integer     NOT NULL,
    visit_detail_start_date        date        NOT NULL,
    visit_detail_start_datetime    TIMESTAMP   NULL,
    visit_detail_end_date          date        NOT NULL,
    visit_detail_end_datetime      TIMESTAMP   NULL,
    visit_detail_type_concept_id   integer     NOT NULL,
    provider_id                    integer     NULL,
    care_site_id                   integer     NULL,
    visit_detail_source_value      varchar(50) NULL,
    visit_detail_source_concept_id integer     NULL,
    admitted_from_concept_id       integer     NULL,
    admitted_from_source_value     varchar(50) NULL,
    discharged_to_source_value     varchar(50) NULL,
    discharged_to_concept_id       integer     NULL,
    preceding_visit_detail_id      integer     NULL,
    parent_visit_detail_id         integer     NULL,
    visit_occurrence_id            integer     NOT NULL
);


CREATE TABLE IF NOT EXISTS omopgis.CONDITION_OCCURRENCE
(
    condition_occurrence_id       integer     NOT NULL,
    person_id                     integer     NOT NULL,
    condition_concept_id          integer     NOT NULL,
    condition_start_date          date        NOT NULL,
    condition_start_datetime      TIMESTAMP   NULL,
    condition_end_date            date        NULL,
    condition_end_datetime        TIMESTAMP   NULL,
    condition_type_concept_id     integer     NOT NULL,
    condition_status_concept_id   integer     NULL,
    stop_reason                   varchar(20) NULL,
    provider_id                   integer     NULL,
    visit_occurrence_id           integer     NULL,
    visit_detail_id               integer     NULL,
    condition_source_value        varchar(50) NULL,
    condition_source_concept_id   integer     NULL,
    condition_status_source_value varchar(50) NULL
);


CREATE TABLE IF NOT EXISTS omopgis.DRUG_EXPOSURE
(
    drug_exposure_id             integer      NOT NULL,
    person_id                    integer      NOT NULL,
    drug_concept_id              integer      NOT NULL,
    drug_exposure_start_date     date         NOT NULL,
    drug_exposure_start_datetime TIMESTAMP    NULL,
    drug_exposure_end_date       date         NOT NULL,
    drug_exposure_end_datetime   TIMESTAMP    NULL,
    verbatim_end_date            date         NULL,
    drug_type_concept_id         integer      NOT NULL,
    stop_reason                  varchar(20)  NULL,
    refills                      integer      NULL,
    quantity                     NUMERIC      NULL,
    days_supply                  integer      NULL,
    sig                          TEXT         NULL,
    route_concept_id             integer      NULL,
    lot_number                   varchar(50)  NULL,
    provider_id                  integer      NULL,
    visit_occurrence_id          integer      NULL,
    visit_detail_id              integer      NULL,
    drug_source_value            varchar(50)  NULL,
    drug_source_concept_id       integer      NULL,
    route_source_value           varchar(50)  NULL,
    dose_unit_source_value       varchar(50)  NULL
);


CREATE TABLE IF NOT EXISTS omopgis.PROCEDURE_OCCURRENCE
(
    procedure_occurrence_id     integer      NOT NULL,
    person_id                   integer      NOT NULL,
    procedure_concept_id        integer      NOT NULL,
    procedure_date              date         NOT NULL,
    procedure_datetime          TIMESTAMP    NULL,
    procedure_end_date          date         NULL,
    procedure_end_datetime      TIMESTAMP    NULL,
    procedure_type_concept_id   integer      NOT NULL,
    modifier_concept_id         integer      NULL,
    quantity                    integer      NULL,
    provider_id                 integer      NULL,
    visit_occurrence_id         integer      NULL,
    visit_detail_id             integer      NULL,
    procedure_source_value      varchar(50)  NULL,
    procedure_source_concept_id integer      NULL,
    modifier_source_value       varchar(50)  NULL
);


CREATE TABLE IF NOT EXISTS omopgis.DEVICE_EXPOSURE
(
    device_exposure_id             integer      NOT NULL,
    person_id                      integer      NOT NULL,
    device_concept_id              integer      NOT NULL,
    device_exposure_start_date     date         NOT NULL,
    device_exposure_start_datetime TIMESTAMP    NULL,
    device_exposure_end_date       date         NULL,
    device_exposure_end_datetime   TIMESTAMP    NULL,
    device_type_concept_id         integer      NOT NULL,
    unique_device_id               varchar(255) NULL,
    production_id                  varchar(255) NULL,
    quantity                       integer      NULL,
    provider_id                    integer      NULL,
    visit_occurrence_id            integer      NULL,
    visit_detail_id                integer      NULL,
    device_source_value            varchar(50)  NULL,
    device_source_concept_id       integer      NULL,
    unit_concept_id                integer      NULL,
    unit_source_value              varchar(50)  NULL,
    unit_source_concept_id         integer      NULL
);


CREATE TABLE IF NOT EXISTS omopgis.MEASUREMENT
(
    measurement_id                integer      NOT NULL,
    person_id                     integer      NOT NULL,
    measurement_concept_id        integer      NOT NULL,
    measurement_date              date         NOT NULL,
    measurement_datetime          TIMESTAMP    NULL,
    measurement_time              varchar(10)  NULL,
    measurement_type_concept_id   integer      NOT NULL,
    operator_concept_id           integer      NULL,
    value_as_number               NUMERIC      NULL,
    value_as_concept_id           integer      NULL,
    unit_concept_id               integer      NULL,
    range_low                     NUMERIC      NULL,
    range_high                    NUMERIC      NULL,
    provider_id                   integer      NULL,
    visit_occurrence_id           integer      NULL,
    visit_detail_id               integer      NULL,
    measurement_source_value      varchar(50)  NULL,
    measurement_source_concept_id integer      NULL,
    unit_source_value             varchar(50)  NULL,
    unit_source_concept_id        integer      NULL,
    value_source_value            varchar(50)  NULL,
    measurement_event_id          integer      NULL,
    meas_event_field_concept_id   integer      NULL
);


CREATE TABLE IF NOT EXISTS omopgis.OBSERVATION
(
    observation_id                integer      NOT NULL,
    person_id                     integer      NOT NULL,
    observation_concept_id        integer      NOT NULL,
    observation_date              date         NOT NULL,
    observation_datetime          TIMESTAMP    NULL,
    observation_type_concept_id   integer      NOT NULL,
    value_as_number               NUMERIC      NULL,
    value_as_string               varchar(60)  NULL,
    value_as_concept_id           Integer      NULL,
    qualifier_concept_id          integer      NULL,
    unit_concept_id               integer      NULL,
    provider_id                   integer      NULL,
    visit_occurrence_id           integer      NULL,
    visit_detail_id               integer      NULL,
    observation_source_value      varchar(50)  NULL,
    observation_source_concept_id integer      NULL,
    unit_source_value             varchar(50)  NULL,
    qualifier_source_value        varchar(50)  NULL,
    value_source_value            varchar(50)  NULL,
    observation_event_id          integer      NULL,
    obs_event_field_concept_id    integer      NULL
);


CREATE TABLE IF NOT EXISTS omopgis.DEATH
(
    person_id               integer     NOT NULL,
    death_date              date        NOT NULL,
    death_datetime          TIMESTAMP   NULL,
    death_type_concept_id   integer     NULL,
    cause_concept_id        integer     NULL,
    cause_source_value      varchar(50) NULL,
    cause_source_concept_id integer     NULL
);


CREATE TABLE IF NOT EXISTS omopgis.NOTE
(
    note_id                  integer      NOT NULL,
    person_id                integer      NOT NULL,
    note_date                date         NOT NULL,
    note_datetime            TIMESTAMP    NULL,
    note_type_concept_id     integer      NOT NULL,
    note_class_concept_id    integer      NOT NULL,
    note_title               varchar(250) NULL,
    note_text                TEXT         NOT NULL,
    encoding_concept_id      integer      NOT NULL,
    language_concept_id      integer      NOT NULL,
    provider_id              integer      NULL,
    visit_occurrence_id      integer      NULL,
    visit_detail_id          integer      NULL,
    note_source_value        varchar(50)  NULL,
    note_event_id            integer      NULL,
    note_event_field_concept_id integer   NULL
);


CREATE TABLE IF NOT EXISTS omopgis.NOTE_NLP
(
    note_nlp_id                integer      NOT NULL,
    note_id                    integer      NOT NULL,
    section_concept_id         integer      NULL,
    snippet                    varchar(250) NULL,
    "offset"                   varchar(50)  NULL,
    lexical_variant            varchar(250) NOT NULL,
    note_nlp_concept_id        integer      NULL,
    note_nlp_source_concept_id integer      NULL,
    nlp_system                 varchar(250) NULL,
    nlp_date                   date         NOT NULL,
    nlp_datetime               TIMESTAMP    NULL,
    term_exists                varchar(1)   NULL,
    term_temporal              varchar(50)  NULL,
    term_modifiers             varchar(2000) NULL
);


CREATE TABLE IF NOT EXISTS omopgis.SPECIMEN
(
    specimen_id                 integer      NOT NULL,
    person_id                   integer      NOT NULL,
    specimen_concept_id         integer      NOT NULL,
    specimen_type_concept_id    integer      NOT NULL,
    specimen_date               date         NOT NULL,
    specimen_datetime           TIMESTAMP    NULL,
    quantity                    NUMERIC      NULL,
    unit_concept_id             integer      NULL,
    anatomic_site_concept_id    integer      NULL,
    disease_status_concept_id   integer      NULL,
    specimen_source_id          varchar(50)  NULL,
    specimen_source_value       varchar(50)  NULL,
    unit_source_value           varchar(50)  NULL,
    anatomic_site_source_value  varchar(50)  NULL,
    disease_status_source_value varchar(50)  NULL
);


CREATE TABLE IF NOT EXISTS omopgis.FACT_RELATIONSHIP
(
    domain_concept_id_1     integer NOT NULL,
    fact_id_1               integer NOT NULL,
    domain_concept_id_2     integer NOT NULL,
    fact_id_2               integer NOT NULL,
    relationship_concept_id integer NOT NULL
);


CREATE TABLE IF NOT EXISTS omopgis.LOCATION
(
    location_id           integer      NOT NULL,
    address_1             varchar(50)  NULL,
    address_2             varchar(50)  NULL,
    city                  varchar(50)  NULL,
    state                 varchar(2)   NULL,
    zip                   varchar(9)   NULL,
    county                varchar(20)  NULL,
    location_source_value varchar(50)  NULL,
    country_concept_id    integer      NULL,
    country_source_value  varchar(80)  NULL,
    latitude              NUMERIC      NULL,
    longitude             NUMERIC      NULL
);


CREATE TABLE IF NOT EXISTS omopgis.CARE_SITE
(
    care_site_id                  integer      NOT NULL,
    care_site_name                varchar(255) NULL,
    place_of_service_concept_id   integer      NULL,
    location_id                   integer      NULL,
    care_site_source_value        varchar(50)  NULL,
    place_of_service_source_value varchar(50)  NULL
);


CREATE TABLE IF NOT EXISTS omopgis.PROVIDER
(
    provider_id                 integer      NOT NULL,
    provider_name               varchar(255) NULL,
    npi                         varchar(20)  NULL,
    dea                         varchar(20)  NULL,
    specialty_concept_id        integer      NULL,
    care_site_id                integer      NULL,
    year_of_birth               integer      NULL,
    gender_concept_id           integer      NULL,
    provider_source_value       varchar(50)  NULL,
    specialty_source_value      varchar(50)  NULL,
    specialty_source_concept_id integer      NULL,
    gender_source_value         varchar(50)  NULL,
    gender_source_concept_id    integer      NULL
);


CREATE TABLE IF NOT EXISTS omopgis.PAYER_PLAN_PERIOD
(
    payer_plan_period_id          integer     NOT NULL,
    person_id                     integer     NOT NULL,
    payer_plan_period_start_date  date        NOT NULL,
    payer_plan_period_end_date    date        NOT NULL,
    payer_concept_id              integer     NULL,
    payer_source_value            varchar(50) NULL,
    payer_source_concept_id       integer     NULL,
    plan_concept_id               integer     NULL,
    plan_source_value             varchar(50) NULL,
    plan_source_concept_id        integer     NULL,
    sponsor_concept_id            integer     NULL,
    sponsor_source_value          varchar(50) NULL,
    sponsor_source_concept_id     integer     NULL,
    family_source_value           varchar(50) NULL,
    stop_reason_concept_id        integer     NULL,
    stop_reason_source_value      varchar(50) NULL,
    stop_reason_source_concept_id integer     NULL
);


CREATE TABLE IF NOT EXISTS omopgis.COST
(
    cost_id                  integer   NOT NULL,
    cost_event_id            integer   NOT NULL,
    cost_domain_id           varchar(20) NOT NULL,
    cost_type_concept_id     integer   NOT NULL,
    currency_concept_id      integer   NULL,
    total_charge             NUMERIC   NULL,
    total_cost               NUMERIC   NULL,
    total_paid               NUMERIC   NULL,
    paid_by_payer            NUMERIC   NULL,
    paid_by_patient          NUMERIC   NULL,
    paid_patient_copay       NUMERIC   NULL,
    paid_patient_coinsurance NUMERIC   NULL,
    paid_patient_deductible  NUMERIC   NULL,
    paid_by_primary          NUMERIC   NULL,
    paid_ingredient_cost     NUMERIC   NULL,
    paid_dispensing_fee      NUMERIC   NULL,
    payer_plan_period_id     integer   NULL,
    amount_allowed           NUMERIC   NULL,
    revenue_code_concept_id  integer   NULL,
    revenue_code_source_value varchar(50) NULL,
    drg_concept_id           integer   NULL,
    drg_source_value         varchar(3) NULL
);


CREATE TABLE IF NOT EXISTS omopgis.DRUG_ERA
(
    drug_era_id         integer NOT NULL,
    person_id           integer NOT NULL,
    drug_concept_id     integer NOT NULL,
    drug_era_start_date date    NOT NULL,
    drug_era_end_date   date    NOT NULL,
    drug_exposure_count integer NULL,
    gap_days            integer NULL
);


CREATE TABLE IF NOT EXISTS omopgis.DOSE_ERA
(
    dose_era_id         integer NOT NULL,
    person_id           integer NOT NULL,
    drug_concept_id     integer NOT NULL,
    unit_concept_id     integer NOT NULL,
    dose_value          NUMERIC NOT NULL,
    dose_era_start_date date    NOT NULL,
    dose_era_end_date   date    NOT NULL
);


CREATE TABLE IF NOT EXISTS omopgis.CONDITION_ERA
(
    condition_era_id           integer NOT NULL,
    person_id                  integer NOT NULL,
    condition_concept_id       integer NOT NULL,
    condition_era_start_date   date    NOT NULL,
    condition_era_end_date     date    NOT NULL,
    condition_occurrence_count integer NULL
);


CREATE TABLE IF NOT EXISTS omopgis.EPISODE
(
    episode_id                  integer     NOT NULL,
    person_id                   integer     NOT NULL,
    episode_concept_id          integer     NOT NULL,
    episode_start_date          date        NOT NULL,
    episode_start_datetime      TIMESTAMP   NULL,
    episode_end_date            date        NULL,
    episode_end_datetime        TIMESTAMP   NULL,
    episode_parent_id           integer     NULL,
    episode_number              integer     NULL,
    episode_object_concept_id   integer     NOT NULL,
    episode_type_concept_id     integer     NOT NULL,
    episode_source_value        varchar(50) NULL,
    episode_source_concept_id   integer     NULL
);


CREATE TABLE IF NOT EXISTS omopgis.EPISODE_EVENT
(
    episode_id                integer NOT NULL,
    event_id                  integer NOT NULL,
    episode_event_field_concept_id integer NOT NULL
);


CREATE TABLE IF NOT EXISTS omopgis.METADATA
(
    metadata_id              integer      NOT NULL,
    metadata_concept_id      integer      NOT NULL,
    metadata_type_concept_id integer      NOT NULL,
    name                     varchar(250) NOT NULL,
    value_as_string          varchar(250) NULL,
    value_as_concept_id      integer      NULL,
    value_as_number          NUMERIC      NULL,
    metadata_date            date         NULL,
    metadata_datetime        TIMESTAMP    NULL
);


CREATE TABLE IF NOT EXISTS omopgis.CDM_SOURCE
(
    cdm_source_name                varchar(255) NOT NULL,
    cdm_source_abbreviation        varchar(25)  NOT NULL,
    cdm_holder                     varchar(255) NOT NULL,
    source_description             TEXT         NULL,
    source_documentation_reference varchar(255) NULL,
    cdm_etl_reference              varchar(255) NULL,
    source_release_date            date         NOT NULL,
    cdm_release_date               date         NOT NULL,
    cdm_version                    varchar(10)  NULL,
    cdm_version_concept_id         integer      NOT NULL,
    vocabulary_version             varchar(20)  NOT NULL
);


CREATE TABLE IF NOT EXISTS omopgis.DRUG_STRENGTH
(
    drug_concept_id             integer    NOT NULL,
    ingredient_concept_id       integer    NOT NULL,
    amount_value                NUMERIC    NULL,
    amount_unit_concept_id      integer    NULL,
    numerator_value             NUMERIC    NULL,
    numerator_unit_concept_id   integer    NULL,
    denominator_value           NUMERIC    NULL,
    denominator_unit_concept_id integer    NULL,
    box_size                    integer    NULL,
    valid_start_date            date       NOT NULL,
    valid_end_date              date       NOT NULL,
    invalid_reason              varchar(1) NULL
);


CREATE TABLE IF NOT EXISTS omopgis.COHORT
(
    cohort_definition_id integer NOT NULL,
    subject_id           integer NOT NULL,
    cohort_start_date    date    NOT NULL,
    cohort_end_date      date    NOT NULL
);


CREATE TABLE IF NOT EXISTS omopgis.COHORT_DEFINITION
(
    cohort_definition_id          integer      NOT NULL,
    cohort_definition_name        varchar(255) NOT NULL,
    cohort_definition_description TEXT         NULL,
    definition_type_concept_id    integer      NOT NULL,
    cohort_definition_syntax      TEXT         NULL,
    subject_concept_id            integer      NOT NULL,
    cohort_initiation_date        date         NULL
);


-- ============================================================================
-- GAIA CDM EXTENSION TABLES
-- ============================================================================
-- These tables extend the OMOP CDM to support GIS and external exposure data
-- Based on Gaia_Table_Level.csv and Gaia_Field_Level.csv specifications

CREATE TABLE IF NOT EXISTS omopgis.LOCATION_HISTORY
(
    location_id                   integer NOT NULL,
    relationship_type_concept_id  integer NOT NULL,
    domain_id                     varchar(20) NOT NULL,
    entity_id                     integer NOT NULL,
    start_date                    date    NOT NULL,
    end_date                      date    NULL
);


CREATE TABLE IF NOT EXISTS omopgis.EXTERNAL_EXPOSURE
(
    external_exposure_id              integer     NOT NULL,
    location_id                       integer     NOT NULL,
    person_id                         integer     NOT NULL,
    exposure_concept_id               integer     NOT NULL,
    exposure_start_date               date        NOT NULL,
    exposure_start_datetime           TIMESTAMP   NULL,
    exposure_end_date                 date        NOT NULL,
    exposure_end_datetime             TIMESTAMP   NULL,
    exposure_type_concept_id          integer     NOT NULL,
    exposure_relationship_concept_id  integer     NOT NULL,
    exposure_source_concept_id        integer     NULL,
    exposure_source_value             varchar(50) NULL,
    exposure_relationship_source_value varchar(50) NULL,
    dose_unit_source_value            varchar(50) NULL,
    quantity                          integer     NULL,
    modifier_source_value             varchar(50) NULL,
    operator_concept_id               integer     NULL,
    value_as_number                   float       NULL,
    value_as_concept_id               integer     NULL,
    unit_concept_id                   integer     NULL
);

-- ============================================================================
-- POPULATE SYNTHETIC DATA
-- ============================================================================

-- ============================================================================
-- PEOPLE (10,000 patients)
-- ============================================================================

INSERT INTO omopgis.PERSON(person_id,
                           gender_concept_id,
                           year_of_birth,
                           month_of_birth,
                           day_of_birth,
                           birth_datetime,
                           race_concept_id,
                           ethnicity_concept_id,
                           location_id,
                           provider_id,
                           care_site_id,
                           person_source_value,
                           gender_source_value,
                           gender_source_concept_id,
                           race_source_value,
                           race_source_concept_id,
                           ethnicity_source_value,
                           ethnicity_source_concept_id)
SELECT row_number() over (),
       (select (array [8532, 8507])[floor(random() * 2 * (i / i) + 1)]),
       (select floor(random() * 30 * (i / i) + 1940)),
       (select floor(random() * 11.99 * (i / i) + 1)),
       NULL,
       NULL,
       0,
       0,
       row_number() over (), -- Link to location_id (will create locations below)
       NULL,
       NULL,
       (select CONCAT('FAKE PERSON: ', substr(md5(i::text), 0, 10))),
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL
FROM generate_series(1, 10000) s(i);

UPDATE omopgis.PERSON
SET gender_source_value = 'M'
WHERE gender_concept_id = 8507;

UPDATE omopgis.PERSON
SET gender_source_value = 'F'
WHERE gender_concept_id = 8532;

-- ============================================================================
-- LOCATIONS (Geographic features for each person)
-- ============================================================================
-- Create realistic locations:
--   - Urban patients (1-3000): Boston area (high pollution)
--   - Suburban patients (3001-7000): Suburban Massachusetts (moderate pollution)
--   - Rural patients (7001-10000): Vermont (low pollution)

INSERT INTO omopgis.LOCATION(location_id,
                             address_1,
                             address_2,
                             city,
                             state,
                             zip,
                             county,
                             location_source_value,
                             country_concept_id,
                             country_source_value,
                             latitude,
                             longitude)
SELECT row_number() over (),
       -- Address generation
       CASE
           WHEN i <= 3000 THEN CONCAT((floor(random() * 1000 + 1)::integer)::text, ' ',
                                     (ARRAY['Washington', 'Tremont', 'Boylston', 'Commonwealth', 'Beacon', 'Newbury', 'Huntington', 'Cambridge', 'Broadway', 'Massachusetts'])[floor(random() * 10 + 1)::integer],
                                     ' ',
                                     (ARRAY['St', 'Ave', 'Blvd', 'Rd'])[floor(random() * 4 + 1)::integer])
           WHEN i <= 7000 THEN CONCAT((floor(random() * 500 + 1)::integer)::text, ' ',
                                     (ARRAY['Main', 'Elm', 'Oak', 'Maple', 'Cedar', 'Pine', 'Lincoln', 'Washington', 'Park', 'Central'])[floor(random() * 10 + 1)::integer],
                                     ' ',
                                     (ARRAY['St', 'Ave', 'Dr', 'Ln', 'Rd'])[floor(random() * 5 + 1)::integer])
           ELSE CONCAT((floor(random() * 300 + 1)::integer)::text, ' ',
                      (ARRAY['Mountain', 'Valley', 'River', 'Lake', 'Forest', 'Hillside', 'Maple', 'Church', 'School', 'Green'])[floor(random() * 10 + 1)::integer],
                      ' ',
                      (ARRAY['Rd', 'Ln', 'Dr', 'Way'])[floor(random() * 4 + 1)::integer])
       END,
       NULL,
       -- City
       CASE
           WHEN i <= 3000 THEN (ARRAY['Boston', 'Cambridge', 'Somerville', 'Brookline', 'Quincy', 'Revere'])[floor(random() * 6 + 1)::integer]
           WHEN i <= 7000 THEN (ARRAY['Newton', 'Waltham', 'Lexington', 'Wellesley', 'Framingham', 'Natick', 'Needham', 'Dedham'])[floor(random() * 8 + 1)::integer]
           ELSE (ARRAY['Burlington', 'Montpelier', 'Rutland', 'Brattleboro', 'St. Johnsbury', 'Bennington', 'Middlebury', 'Stowe', 'Manchester', 'Newport'])[floor(random() * 10 + 1)::integer]
       END,
       -- State
       CASE
           WHEN i <= 7000 THEN 'MA'
           ELSE 'VT'
       END,
       -- ZIP Code
       CASE
           WHEN i <= 3000 THEN (ARRAY['02101', '02108', '02109', '02110', '02111', '02115', '02116', '02118', '02119', '02120', '02121', '02122', '02124', '02125', '02126', '02127', '02128', '02129', '02130', '02131', '02132', '02134', '02135', '02136', '02139', '02140', '02141', '02142', '02143', '02144', '02145', '02148', '02149', '02151', '02152', '02155', '02163', '02169', '02170', '02171'])[floor(random() * 40 + 1)::integer]
           WHEN i <= 7000 THEN (ARRAY['01701', '01702', '01760', '01773', '01778', '01801', '01803', '01810', '01824', '01826', '01851', '01854', '01915', '01940', '01945', '02026', '02030', '02032', '02035', '02054', '02056', '02061', '02062', '02071', '02090', '02093', '02169', '02176', '02181', '02269'])[floor(random() * 30 + 1)::integer]
           ELSE (ARRAY['05001', '05032', '05033', '05034', '05035', '05036', '05037', '05038', '05039', '05040', '05041', '05042', '05043', '05045', '05046', '05047', '05048', '05050', '05051', '05052', '05053', '05054', '05055', '05056', '05058', '05060', '05061', '05062', '05065', '05067', '05068', '05069', '05070', '05071', '05072', '05073', '05074', '05075', '05076', '05077'])[floor(random() * 40 + 1)::integer]
       END,
       -- County
       CASE
           WHEN i <= 3000 THEN (ARRAY['Suffolk County', 'Middlesex County', 'Norfolk County'])[floor(random() * 3 + 1)::integer]
           WHEN i <= 7000 THEN (ARRAY['Middlesex County', 'Norfolk County', 'Worcester County'])[floor(random() * 3 + 1)::integer]
           ELSE (ARRAY['Chittenden County', 'Washington County', 'Rutland County', 'Windham County', 'Windsor County', 'Addison County', 'Bennington County', 'Franklin County', 'Lamoille County', 'Orange County'])[floor(random() * 10 + 1)::integer]
       END,
       -- Census tract identifier
       CONCAT('TRACT-', LPAD(i::text, 6, '0')),
       NULL,
       NULL,
       -- Latitude
       CASE
           WHEN i <= 3000 THEN (42.3 + random() * 0.2)  -- Boston area: 42.3-42.5°N
           WHEN i <= 7000 THEN (42.2 + random() * 0.4)  -- Suburban MA: 42.2-42.6°N
           ELSE (43.0 + random() * 1.5)                 -- Vermont: 43.0-44.5°N
       END,
       -- Longitude
       CASE
           WHEN i <= 3000 THEN (-71.1 + random() * 0.1)  -- Boston area: -71.1 to -71.0°W
           WHEN i <= 7000 THEN (-71.5 + random() * 0.3)  -- Suburban MA: -71.5 to -71.2°W
           ELSE (-73.0 + random() * 0.8)                 -- Vermont: -73.0 to -72.2°W
       END
FROM generate_series(1, 10000) s(i);

-- ============================================================================
-- LOCATION HISTORY
-- ============================================================================
-- Track when each person resided at their location
-- relationship_type_concept_id: Using 581476 - "Lives at" from SNOMED
-- domain_id: 'Person' domain
-- entity_id: person_id

INSERT INTO omopgis.location_history(location_id,
                                     relationship_type_concept_id,
                                     domain_id,
                                     entity_id,
                                     start_date,
                                     end_date)
SELECT p.location_id,
       581476,  -- "Lives at" relationship from SNOMED
       'Person',
       p.person_id,
       '2020-01-01'::date,
       '2024-12-31'::date
FROM omopgis.person p;

-- ============================================================================
-- RESPIRATORY CONDITIONS
-- ============================================================================
-- Primary focus: Asthma for ~3,000 patients (target cohort)
-- Additional conditions: COPD, Chronic Bronchitis, Allergic Rhinitis

-- Asthma (317009) - Primary condition of interest
-- Correlated with high PM2.5 exposure
INSERT INTO omopgis.condition_occurrence(condition_occurrence_id,
                                         person_id,
                                         condition_concept_id,
                                         condition_start_date,
                                         condition_start_datetime,
                                         condition_end_date,
                                         condition_end_datetime,
                                         condition_type_concept_id,
                                         condition_status_concept_id,
                                         stop_reason,
                                         provider_id,
                                         visit_occurrence_id,
                                         visit_detail_id,
                                         condition_source_value,
                                         condition_source_concept_id,
                                         condition_status_source_value)
SELECT row_number() over (),
       (select (array(select person_id from omopgis.person ORDER BY person_id))[i]),
       317009, -- Asthma
       (select '2020-01-01 00:00:00'::timestamp +
               random() * (i / i) * ('2024-12-31 23:59:59'::timestamp -
                                     '2020-01-01 00:00:00'::timestamp))::date,
       NULL,
       NULL,
       NULL,
       32817, -- EHR
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       'ASTHMA',
       317009,
       NULL
FROM generate_series(1, 3000) s(i);

-- COPD (255573)
INSERT INTO omopgis.condition_occurrence(condition_occurrence_id,
                                         person_id,
                                         condition_concept_id,
                                         condition_start_date,
                                         condition_start_datetime,
                                         condition_end_date,
                                         condition_end_datetime,
                                         condition_type_concept_id,
                                         condition_status_concept_id,
                                         stop_reason,
                                         provider_id,
                                         visit_occurrence_id,
                                         visit_detail_id,
                                         condition_source_value,
                                         condition_source_concept_id,
                                         condition_status_source_value)
SELECT (row_number() over () + 3000),
       (select (array(select person_id from omopgis.person))[floor(random() * 10000 * (i / i) + 1)]),
       255573, -- COPD
       (select '2020-01-01 00:00:00'::timestamp +
               random() * (i / i) * ('2024-12-31 23:59:59'::timestamp -
                                     '2020-01-01 00:00:00'::timestamp))::date,
       NULL,
       NULL,
       NULL,
       32817,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       'COPD',
       255573,
       NULL
FROM generate_series(1, 1500) s(i);

-- Chronic Bronchitis (255848)
INSERT INTO omopgis.condition_occurrence(condition_occurrence_id,
                                         person_id,
                                         condition_concept_id,
                                         condition_start_date,
                                         condition_start_datetime,
                                         condition_end_date,
                                         condition_end_datetime,
                                         condition_type_concept_id,
                                         condition_status_concept_id,
                                         stop_reason,
                                         provider_id,
                                         visit_occurrence_id,
                                         visit_detail_id,
                                         condition_source_value,
                                         condition_source_concept_id,
                                         condition_status_source_value)
SELECT (row_number() over () + 4500),
       (select (array(select person_id from omopgis.person))[floor(random() * 10000 * (i / i) + 1)]),
       255848, -- Chronic Bronchitis
       (select '2020-01-01 00:00:00'::timestamp +
               random() * (i / i) * ('2024-12-31 23:59:59'::timestamp -
                                     '2020-01-01 00:00:00'::timestamp))::date,
       NULL,
       NULL,
       NULL,
       32817,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       'BRONCHITIS',
       255848,
       NULL
FROM generate_series(1, 1200) s(i);

-- Allergic Rhinitis (4170143)
INSERT INTO omopgis.condition_occurrence(condition_occurrence_id,
                                         person_id,
                                         condition_concept_id,
                                         condition_start_date,
                                         condition_start_datetime,
                                         condition_end_date,
                                         condition_end_datetime,
                                         condition_type_concept_id,
                                         condition_status_concept_id,
                                         stop_reason,
                                         provider_id,
                                         visit_occurrence_id,
                                         visit_detail_id,
                                         condition_source_value,
                                         condition_source_concept_id,
                                         condition_status_source_value)
SELECT (row_number() over () + 5700),
       (select (array(select person_id from omopgis.person))[floor(random() * 10000 * (i / i) + 1)]),
       4170143, -- Allergic Rhinitis
       (select '2020-01-01 00:00:00'::timestamp +
               random() * (i / i) * ('2024-12-31 23:59:59'::timestamp -
                                     '2020-01-01 00:00:00'::timestamp))::date,
       NULL,
       NULL,
       NULL,
       32817,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       'RHINITIS',
       4170143,
       NULL
FROM generate_series(1, 2500) s(i);

-- Pneumonia (255848)
INSERT INTO omopgis.condition_occurrence(condition_occurrence_id,
                                         person_id,
                                         condition_concept_id,
                                         condition_start_date,
                                         condition_start_datetime,
                                         condition_end_date,
                                         condition_end_datetime,
                                         condition_type_concept_id,
                                         condition_status_concept_id,
                                         stop_reason,
                                         provider_id,
                                         visit_occurrence_id,
                                         visit_detail_id,
                                         condition_source_value,
                                         condition_source_concept_id,
                                         condition_status_source_value)
SELECT (row_number() over () + 8200),
       (select (array(select person_id from omopgis.person))[floor(random() * 10000 * (i / i) + 1)]),
       255848, -- Pneumonia
       (select '2020-01-01 00:00:00'::timestamp +
               random() * (i / i) * ('2024-12-31 23:59:59'::timestamp -
                                     '2020-01-01 00:00:00'::timestamp))::date,
       NULL,
       NULL,
       NULL,
       32817,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       'PNEUMONIA',
       255848,
       NULL
FROM generate_series(1, 800) s(i);

-- ============================================================================
-- EXTERNAL EXPOSURES (Place-based Environmental Exposures)
-- ============================================================================
-- These are place-based environmental exposures stored in the EXTERNAL_EXPOSURE table
-- following the Gaia CDM Extension specification. PM2.5, PM10, and Ozone levels are
-- linked to person locations and show strong correlation with asthma prevalence.
--
-- exposure_type_concept_id: 32817 (EHR) - could be refined to air quality database type
-- exposure_relationship_concept_id: We'll use a standard concept for "exposed to"
--   44818800 - "Exposed to" from SNOMED

-- PM2.5 Air Quality Index (concept: 2052497664)
-- KEY DISCRIMINATIVE FEATURE: Asthma patients have higher PM2.5 exposure
INSERT INTO omopgis.external_exposure(external_exposure_id,
                                      location_id,
                                      person_id,
                                      exposure_concept_id,
                                      exposure_start_date,
                                      exposure_start_datetime,
                                      exposure_end_date,
                                      exposure_end_datetime,
                                      exposure_type_concept_id,
                                      exposure_relationship_concept_id,
                                      exposure_source_concept_id,
                                      exposure_source_value,
                                      exposure_relationship_source_value,
                                      dose_unit_source_value,
                                      quantity,
                                      modifier_source_value,
                                      operator_concept_id,
                                      value_as_number,
                                      value_as_concept_id,
                                      unit_concept_id)
SELECT row_number() over (),
       p.location_id,
       p.person_id,
       2052497664, -- PM2.5 Air Quality Index
       '2020-01-01'::date,
       NULL,
       '2024-12-31'::date,
       NULL,
       32817, -- EHR / Environmental data type
       44818800, -- "Exposed to" relationship
       2052499878, -- Air Quality Database (OMOP SDOH concept)
       'EPA_AQI_PM25',
       'Residential exposure',
       'µg/m³',
       NULL,
       NULL,
       NULL,
       -- KEY DISCRIMINATIVE FEATURE: Asthma patients have higher PM2.5 exposure
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN (25.0 + random() * 40.0)  -- Asthma: 25-65 µg/m³ (Unhealthy for sensitive groups to Very Unhealthy)
           ELSE (5.0 + random() * 20.0)   -- Non-asthma: 5-25 µg/m³ (Good to Moderate)
       END,
       NULL,
       8837  -- µg/m³ (micrograms per cubic meter)
FROM omopgis.person p;

-- PM10 Air Quality Index (concept: 2052497665)
INSERT INTO omopgis.external_exposure(external_exposure_id,
                                      location_id,
                                      person_id,
                                      exposure_concept_id,
                                      exposure_start_date,
                                      exposure_start_datetime,
                                      exposure_end_date,
                                      exposure_end_datetime,
                                      exposure_type_concept_id,
                                      exposure_relationship_concept_id,
                                      exposure_source_concept_id,
                                      exposure_source_value,
                                      exposure_relationship_source_value,
                                      dose_unit_source_value,
                                      quantity,
                                      modifier_source_value,
                                      operator_concept_id,
                                      value_as_number,
                                      value_as_concept_id,
                                      unit_concept_id)
SELECT (row_number() over () + 10000),
       p.location_id,
       p.person_id,
       2052497665, -- PM10 Air Quality Index
       '2020-01-01'::date,
       NULL,
       '2024-12-31'::date,
       NULL,
       32817,
       44818800,
       2052499878, -- Air Quality Database
       'EPA_AQI_PM10',
       'Residential exposure',
       'µg/m³',
       NULL,
       NULL,
       NULL,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN (35.0 + random() * 65.0)  -- Asthma: 35-100 µg/m³
           ELSE (10.0 + random() * 30.0)  -- Non-asthma: 10-40 µg/m³
       END,
       NULL,
       8837
FROM omopgis.person p;

-- Ozone Air Quality Index (concept: 2052497666)
INSERT INTO omopgis.external_exposure(external_exposure_id,
                                      location_id,
                                      person_id,
                                      exposure_concept_id,
                                      exposure_start_date,
                                      exposure_start_datetime,
                                      exposure_end_date,
                                      exposure_end_datetime,
                                      exposure_type_concept_id,
                                      exposure_relationship_concept_id,
                                      exposure_source_concept_id,
                                      exposure_source_value,
                                      exposure_relationship_source_value,
                                      dose_unit_source_value,
                                      quantity,
                                      modifier_source_value,
                                      operator_concept_id,
                                      value_as_number,
                                      value_as_concept_id,
                                      unit_concept_id)
SELECT (row_number() over () + 20000),
       p.location_id,
       p.person_id,
       2052497666, -- Ozone Air Quality Index
       '2020-01-01'::date,
       NULL,
       '2024-12-31'::date,
       NULL,
       32817,
       44818800,
       2052499878, -- Air Quality Database
       'EPA_AQI_OZONE',
       'Residential exposure',
       'ppb',
       NULL,
       NULL,
       NULL,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN (40.0 + random() * 80.0)  -- Asthma: 40-120 ppb
           ELSE (20.0 + random() * 40.0)  -- Non-asthma: 20-60 ppb
       END,
       NULL,
       8482  -- ppb (parts per billion)
FROM omopgis.person p;

-- ============================================================================
-- SOCIOECONOMIC DETERMINANTS (SDOH Observations)
-- ============================================================================
-- Create observations for poverty, education, housing, employment
-- Asthma patients tend to have lower socioeconomic status

-- Poverty Rate by Census Tract (using concept 2051503454 - Poverty)
INSERT INTO omopgis.observation(observation_id,
                                person_id,
                                observation_concept_id,
                                observation_date,
                                observation_datetime,
                                observation_type_concept_id,
                                value_as_number,
                                value_as_string,
                                value_as_concept_id,
                                qualifier_concept_id,
                                unit_concept_id,
                                provider_id,
                                visit_occurrence_id,
                                visit_detail_id,
                                observation_source_value,
                                observation_source_concept_id,
                                unit_source_value,
                                qualifier_source_value,
                                value_source_value,
                                observation_event_id,
                                obs_event_field_concept_id)
SELECT (row_number() over () + 30000),
       p.person_id,
       2051503454, -- Poverty
       '2022-01-01'::date,
       NULL,
       32817,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN (15.0 + random() * 25.0)  -- Asthma: 15-40% poverty rate (higher poverty)
           ELSE (2.0 + random() * 13.0)   -- Non-asthma: 2-15% poverty rate (lower poverty)
       END,
       NULL,
       NULL,
       NULL,
       8554, -- percent
       NULL,
       NULL,
       NULL,
       'POVERTY_RATE',
       2051503454,
       'percent',
       NULL,
       NULL,
       NULL,
       NULL
FROM omopgis.person p;

-- Education Level (concept: 2051502048 - Education_Level)
-- Lower education correlated with asthma
INSERT INTO omopgis.observation(observation_id,
                                person_id,
                                observation_concept_id,
                                observation_date,
                                observation_datetime,
                                observation_type_concept_id,
                                value_as_number,
                                value_as_string,
                                value_as_concept_id,
                                qualifier_concept_id,
                                unit_concept_id,
                                provider_id,
                                visit_occurrence_id,
                                visit_detail_id,
                                observation_source_value,
                                observation_source_concept_id,
                                unit_source_value,
                                qualifier_source_value,
                                value_source_value,
                                observation_event_id,
                                obs_event_field_concept_id)
SELECT (row_number() over () + 40000),
       p.person_id,
       2051502048, -- Education Level
       '2022-01-01'::date,
       NULL,
       32817,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN (8.0 + random() * 6.0)   -- Asthma: 8-14 years of education (lower)
           ELSE (12.0 + random() * 6.0)  -- Non-asthma: 12-18 years of education (higher)
       END,
       NULL,
       NULL,
       NULL,
       8505, -- year
       NULL,
       NULL,
       NULL,
       'EDUCATION_YEARS',
       2051502048,
       'years',
       NULL,
       NULL,
       NULL,
       NULL
FROM omopgis.person p;

-- Housing Cost Burden (concept: 2051503305 - Housing_Cost)
INSERT INTO omopgis.observation(observation_id,
                                person_id,
                                observation_concept_id,
                                observation_date,
                                observation_datetime,
                                observation_type_concept_id,
                                value_as_number,
                                value_as_string,
                                value_as_concept_id,
                                qualifier_concept_id,
                                unit_concept_id,
                                provider_id,
                                visit_occurrence_id,
                                visit_detail_id,
                                observation_source_value,
                                observation_source_concept_id,
                                unit_source_value,
                                qualifier_source_value,
                                value_source_value,
                                observation_event_id,
                                obs_event_field_concept_id)
SELECT (row_number() over () + 50000),
       p.person_id,
       2051503305, -- Housing Cost
       '2022-01-01'::date,
       NULL,
       32817,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN (35.0 + random() * 25.0)  -- Asthma: 35-60% income on housing (high burden)
           ELSE (15.0 + random() * 25.0)  -- Non-asthma: 15-40% income on housing
       END,
       NULL,
       NULL,
       NULL,
       8554, -- percent
       NULL,
       NULL,
       NULL,
       'HOUSING_COST_PCT',
       2051503305,
       'percent',
       NULL,
       NULL,
       NULL,
       NULL
FROM omopgis.person p;

-- Employment Status (concept: 2051501588 - Employment_Status)
-- Using value_as_concept_id to indicate employed (1) or unemployed (0)
INSERT INTO omopgis.observation(observation_id,
                                person_id,
                                observation_concept_id,
                                observation_date,
                                observation_datetime,
                                observation_type_concept_id,
                                value_as_number,
                                value_as_string,
                                value_as_concept_id,
                                qualifier_concept_id,
                                unit_concept_id,
                                provider_id,
                                visit_occurrence_id,
                                visit_detail_id,
                                observation_source_value,
                                observation_source_concept_id,
                                unit_source_value,
                                qualifier_source_value,
                                value_source_value,
                                observation_event_id,
                                obs_event_field_concept_id)
SELECT (row_number() over () + 60000),
       p.person_id,
       2051501588, -- Employment Status
       '2022-01-01'::date,
       NULL,
       32817,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN CASE WHEN random() < 0.35 THEN 0 ELSE 1 END  -- Asthma: 35% unemployed
           ELSE CASE WHEN random() < 0.10 THEN 0 ELSE 1 END  -- Non-asthma: 10% unemployed
       END,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN CASE WHEN random() < 0.35 THEN 'Unemployed' ELSE 'Employed' END
           ELSE CASE WHEN random() < 0.10 THEN 'Unemployed' ELSE 'Employed' END
       END,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       'EMPLOYMENT',
       2051501588,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL
FROM omopgis.person p;

-- Neighborhood Concentrated Disadvantage (concept: 2051502386)
INSERT INTO omopgis.observation(observation_id,
                                person_id,
                                observation_concept_id,
                                observation_date,
                                observation_datetime,
                                observation_type_concept_id,
                                value_as_number,
                                value_as_string,
                                value_as_concept_id,
                                qualifier_concept_id,
                                unit_concept_id,
                                provider_id,
                                visit_occurrence_id,
                                visit_detail_id,
                                observation_source_value,
                                observation_source_concept_id,
                                unit_source_value,
                                qualifier_source_value,
                                value_source_value,
                                observation_event_id,
                                obs_event_field_concept_id)
SELECT (row_number() over () + 70000),
       p.person_id,
       2051502386, -- Neighborhood Concentrated Disadvantage
       '2022-01-01'::date,
       NULL,
       32817,
       CASE
           WHEN EXISTS (SELECT 1 FROM omopgis.condition_occurrence co
                        WHERE co.person_id = p.person_id AND co.condition_concept_id = 317009)
           THEN (0.6 + random() * 0.4)  -- Asthma: 0.6-1.0 index score (high disadvantage)
           ELSE (0.0 + random() * 0.5)  -- Non-asthma: 0.0-0.5 index score (low disadvantage)
       END,
       NULL,
       NULL,
       NULL,
       NULL, -- index score (unitless)
       NULL,
       NULL,
       NULL,
       'NEIGHBORHOOD_DISADVANTAGE',
       2051502386,
       'index',
       NULL,
       NULL,
       NULL,
       NULL
FROM omopgis.person p;

-- ============================================================================
-- RESPIRATORY DRUGS
-- ============================================================================
-- Asthma medications for patients with asthma

-- Albuterol (Inhaler) - 1154343
INSERT INTO omopgis.drug_exposure(drug_exposure_id,
                                  person_id,
                                  drug_concept_id,
                                  drug_exposure_start_date,
                                  drug_exposure_start_datetime,
                                  drug_exposure_end_date,
                                  drug_exposure_end_datetime,
                                  verbatim_end_date,
                                  drug_type_concept_id,
                                  stop_reason,
                                  refills,
                                  quantity,
                                  days_supply,
                                  sig,
                                  route_concept_id,
                                  lot_number,
                                  provider_id,
                                  visit_occurrence_id,
                                  visit_detail_id,
                                  drug_source_value,
                                  drug_source_concept_id,
                                  route_source_value,
                                  dose_unit_source_value)
SELECT row_number() over (),
       co.person_id,
       1154343, -- Albuterol
       co.condition_start_date + floor(random() * 30)::integer,
       NULL,
       co.condition_start_date + floor(random() * 30 + 90)::integer,
       NULL,
       NULL,
       32817,
       NULL,
       3, -- refills
       1, -- quantity (1 inhaler)
       90, -- days supply
       '2 puffs every 4-6 hours as needed',
       4186831, -- Inhalation
       NULL,
       NULL,
       NULL,
       NULL,
       'ALBUTEROL',
       1154343,
       'Inhalation',
       'puffs'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009; -- Asthma patients only

-- Fluticasone (Inhaled Corticosteroid) - 1115008
INSERT INTO omopgis.drug_exposure(drug_exposure_id,
                                  person_id,
                                  drug_concept_id,
                                  drug_exposure_start_date,
                                  drug_exposure_start_datetime,
                                  drug_exposure_end_date,
                                  drug_exposure_end_datetime,
                                  verbatim_end_date,
                                  drug_type_concept_id,
                                  stop_reason,
                                  refills,
                                  quantity,
                                  days_supply,
                                  sig,
                                  route_concept_id,
                                  lot_number,
                                  provider_id,
                                  visit_occurrence_id,
                                  visit_detail_id,
                                  drug_source_value,
                                  drug_source_concept_id,
                                  route_source_value,
                                  dose_unit_source_value)
SELECT (row_number() over () + 3000),
       co.person_id,
       1115008, -- Fluticasone
       co.condition_start_date + floor(random() * 30)::integer,
       NULL,
       co.condition_start_date + floor(random() * 30 + 180)::integer,
       NULL,
       NULL,
       32817,
       NULL,
       5,
       1,
       180,
       '2 puffs twice daily',
       4186831,
       NULL,
       NULL,
       NULL,
       NULL,
       'FLUTICASONE',
       1115008,
       'Inhalation',
       'puffs'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.7; -- 70% of asthma patients

-- Montelukast (Singulair) - 1547504
INSERT INTO omopgis.drug_exposure(drug_exposure_id,
                                  person_id,
                                  drug_concept_id,
                                  drug_exposure_start_date,
                                  drug_exposure_start_datetime,
                                  drug_exposure_end_date,
                                  drug_exposure_end_datetime,
                                  verbatim_end_date,
                                  drug_type_concept_id,
                                  stop_reason,
                                  refills,
                                  quantity,
                                  days_supply,
                                  sig,
                                  route_concept_id,
                                  lot_number,
                                  provider_id,
                                  visit_occurrence_id,
                                  visit_detail_id,
                                  drug_source_value,
                                  drug_source_concept_id,
                                  route_source_value,
                                  dose_unit_source_value)
SELECT (row_number() over () + 6000),
       co.person_id,
       1547504, -- Montelukast
       co.condition_start_date + floor(random() * 30)::integer,
       NULL,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       NULL,
       NULL,
       32817,
       NULL,
       11,
       30,
       365,
       '10mg once daily at bedtime',
       4132161, -- Oral
       NULL,
       NULL,
       NULL,
       NULL,
       'MONTELUKAST',
       1547504,
       'Oral',
       'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.5; -- 50% of asthma patients

-- ============================================================================
-- RESPIRATORY PROCEDURES
-- ============================================================================
-- Pulmonary Function Test (Spirometry) - 40757101

INSERT INTO omopgis.procedure_occurrence(procedure_occurrence_id,
                                        person_id,
                                        procedure_concept_id,
                                        procedure_date,
                                        procedure_datetime,
                                        procedure_end_date,
                                        procedure_end_datetime,
                                        procedure_type_concept_id,
                                        modifier_concept_id,
                                        quantity,
                                        provider_id,
                                        visit_occurrence_id,
                                        visit_detail_id,
                                        procedure_source_value,
                                        procedure_source_concept_id,
                                        modifier_source_value)
SELECT row_number() over (),
       co.person_id,
       40757101, -- Spirometry
       co.condition_start_date + floor(random() * 365)::integer,
       NULL,
       NULL,
       NULL,
       32817,
       NULL,
       1,
       NULL,
       NULL,
       NULL,
       'SPIROMETRY',
       40757101,
       NULL
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.8; -- 80% of asthma patients get spirometry

-- ============================================================================
-- RESPIRATORY MEASUREMENTS
-- ============================================================================
-- Peak Expiratory Flow Rate (PEFR) - 3034006

INSERT INTO omopgis.measurement(measurement_id,
                                person_id,
                                measurement_concept_id,
                                measurement_date,
                                measurement_datetime,
                                measurement_time,
                                measurement_type_concept_id,
                                operator_concept_id,
                                value_as_number,
                                value_as_concept_id,
                                unit_concept_id,
                                range_low,
                                range_high,
                                provider_id,
                                visit_occurrence_id,
                                visit_detail_id,
                                measurement_source_value,
                                measurement_source_concept_id,
                                unit_source_value,
                                unit_source_concept_id,
                                value_source_value,
                                measurement_event_id,
                                meas_event_field_concept_id)
SELECT row_number() over (),
       co.person_id,
       3034006, -- Peak Expiratory Flow Rate
       co.condition_start_date + floor(random() * 365)::integer,
       NULL,
       NULL,
       32817,
       NULL,
       -- Lower PEFR for asthma patients
       CASE
           WHEN co.condition_concept_id = 317009
           THEN (200.0 + random() * 200.0)  -- Asthma: 200-400 L/min (reduced)
           ELSE (400.0 + random() * 200.0)  -- Normal: 400-600 L/min
       END,
       NULL,
       8698, -- L/min
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       'PEFR',
       3034006,
       'L/min',
       NULL,
       NULL,
       NULL,
       NULL
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317009, 255573)  -- Asthma and COPD
AND random() < 0.6;

-- ============================================================================
-- OBSERVATION PERIODS
-- ============================================================================
-- Everyone has observation period from 2020-2024

INSERT INTO omopgis.observation_period(person_id,
                                       observation_period_start_date,
                                       observation_period_end_date,
                                       period_type_concept_id)
SELECT person_id,
       '2020-01-01'::date,
       '2024-12-31'::date,
       32817
FROM omopgis.person;

-- ============================================================================
-- CDM SOURCE METADATA
-- ============================================================================

INSERT INTO omopgis.cdm_source(cdm_source_name,
                               cdm_source_abbreviation,
                               cdm_holder,
                               source_description,
                               source_documentation_reference,
                               cdm_etl_reference,
                               source_release_date,
                               cdm_release_date,
                               cdm_version,
                               cdm_version_concept_id,
                               vocabulary_version)
VALUES ('Synthetic GIS/SDOH Dataset',
        'SYNTH-GIS',
        'OMOP CDM GIS Extension Demo',
        'Synthetic dataset with 10,000 patients demonstrating respiratory conditions (particularly asthma) correlated with environmental exposures (air pollution - PM2.5, PM10, Ozone) and socioeconomic determinants (poverty, education, housing, employment, neighborhood disadvantage). Designed for OHDSI patient-level prediction pipelines.',
        'https://github.com/OHDSI/CommonDataModel',
        'Synthetic Data Generator v1.0',
        '2025-01-21'::date,
        '2025-01-21'::date,
        '5.4',
        756265,
        'GIS v1.0');
