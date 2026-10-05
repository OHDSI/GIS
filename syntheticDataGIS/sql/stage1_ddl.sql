-- Stage 1a: OMOP CDM 5.4 DDL + Gaia extension tables + demo schema (run by build_tutorial_dataset.sh)

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
DROP TABLE IF EXISTS omopgis.COUNTY_REFERENCE CASCADE;
DROP TABLE IF EXISTS omopgis.EXTERNAL_EXPOSURE CASCADE;
DROP TABLE IF EXISTS omopgis.LOCATION_HISTORY CASCADE;
DROP TABLE IF EXISTS omopgis.CONCEPT CASCADE;
DROP TABLE IF EXISTS omopgis.VOCABULARY CASCADE;
DROP TABLE IF EXISTS omopgis.DOMAIN CASCADE;
DROP TABLE IF EXISTS omopgis.CONCEPT_CLASS CASCADE;
DROP TABLE IF EXISTS omopgis.RELATIONSHIP CASCADE;
DROP TABLE IF EXISTS omopgis.CONCEPT_RELATIONSHIP CASCADE;
DROP TABLE IF EXISTS omopgis.CONCEPT_ANCESTOR CASCADE;
DROP TABLE IF EXISTS omopgis.CONCEPT_SYNONYM CASCADE;
DROP SCHEMA IF EXISTS demo CASCADE;
CREATE SCHEMA demo;

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
    condition_occurrence_id       serial      NOT NULL,
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
    drug_exposure_id             serial       NOT NULL,
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
    procedure_occurrence_id     serial       NOT NULL,
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
    measurement_id                serial       NOT NULL,
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
    observation_id                serial       NOT NULL,
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
    provider_id               integer      NULL,
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
    unit_concept_id              integer      NULL,
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
    county                varchar(50)  NULL,
    location_source_value varchar(50)  NULL,
    country_concept_id    integer      NULL,
    country_source_value  varchar(80)  NULL,
    latitude              NUMERIC      NULL,
    longitude             NUMERIC      NULL,
    county_ref_id          integer      NULL  -- Extension: FK to omopgis.county_reference
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
    plan_concept_id                integer     NULL,
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

-- Mini vocabulary (loaded by build_tutorial_dataset.sh from vocabulary/ and vocab_temp/)
CREATE TABLE omopgis.CONCEPT (
    concept_id integer NOT NULL PRIMARY KEY, concept_name varchar(255) NOT NULL, domain_id varchar(50) NOT NULL,
    vocabulary_id varchar(50) NOT NULL, concept_class_id varchar(50) NOT NULL, standard_concept varchar(1) NULL,
    concept_code varchar(50) NOT NULL, valid_start_date date NOT NULL, valid_end_date date NOT NULL, invalid_reason varchar(1) NULL);
CREATE TABLE omopgis.VOCABULARY (
    vocabulary_id varchar(50) NOT NULL PRIMARY KEY, vocabulary_name varchar(255) NOT NULL, vocabulary_reference varchar(255) NULL,
    vocabulary_version varchar(255) NULL, vocabulary_concept_id integer NULL);
CREATE TABLE omopgis.DOMAIN (
    domain_id varchar(50) NOT NULL PRIMARY KEY, domain_name varchar(255) NOT NULL, domain_concept_id integer NULL);
CREATE TABLE omopgis.CONCEPT_CLASS (
    concept_class_id varchar(50) NOT NULL PRIMARY KEY, concept_class_name varchar(255) NOT NULL, concept_class_concept_id integer NULL);
CREATE TABLE omopgis.RELATIONSHIP (
    relationship_id varchar(50) NOT NULL PRIMARY KEY, relationship_name varchar(255) NOT NULL, is_hierarchical varchar(1) NULL,
    defines_ancestry varchar(1) NULL, reverse_relationship_id varchar(50) NULL, relationship_concept_id integer NULL);
CREATE TABLE omopgis.CONCEPT_RELATIONSHIP (
    concept_id_1 integer NOT NULL, concept_id_2 integer NOT NULL, relationship_id varchar(50) NOT NULL,
    valid_start_date date NULL, valid_end_date date NULL, invalid_reason varchar(1) NULL);
CREATE TABLE omopgis.CONCEPT_ANCESTOR (
    ancestor_concept_id integer NOT NULL, descendant_concept_id integer NOT NULL,
    min_levels_of_separation integer NOT NULL, max_levels_of_separation integer NOT NULL);
CREATE TABLE omopgis.CONCEPT_SYNONYM (
    concept_id integer NOT NULL, concept_synonym_name varchar(1000) NOT NULL, language_concept_id integer NOT NULL);

-- Gaia CDM extension tables (inst/csv/Gaia_*_Level.csv)

CREATE TABLE IF NOT EXISTS omopgis.LOCATION_HISTORY
(
    location_id                   integer NOT NULL,
    relationship_type_concept_id  integer NOT NULL,
    domain_id                     integer NOT NULL,       -- concept id of the entity domain (1147314 = Person)
    entity_id                     integer NOT NULL,
    start_date                    date    NOT NULL,
    end_date                      date    NULL
);

CREATE TABLE IF NOT EXISTS omopgis.EXTERNAL_EXPOSURE
(
    external_exposure_id              serial      NOT NULL,
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
    operator_concept_id                integer     NULL,
    value_as_number                   float       NULL,
    value_as_concept_id                integer     NULL,
    unit_concept_id                   integer     NULL
);

-- COUNTY_REFERENCE (demo-only): real counties; ses_index is simulated

CREATE TABLE IF NOT EXISTS omopgis.COUNTY_REFERENCE
(
    county_ref_id            integer      NOT NULL,
    county_name              varchar(80)  NOT NULL,
    state                    varchar(2)   NOT NULL,
    county_fips              varchar(10)  NULL,      -- real 5-digit Census GEOID
    urban_density_category   varchar(20)  NOT NULL, -- Urban Core / Suburban / Small Town / Rural (from 2019 pop. density)
    pm25_baseline_mean       NUMERIC      NOT NULL,  -- real county mean of monthly PM2.5, 2014-2019, ug/m3
    ses_index                NUMERIC      NOT NULL,  -- SIMULATED 0-100 composite SES, higher = more affluent
    centroid_lat             NUMERIC      NOT NULL,
    centroid_lon             NUMERIC      NOT NULL,
    land_area_sqmi           NUMERIC      NOT NULL,
    population_2019          integer      NOT NULL
);

-- POPULATE SYNTHETIC DATA
