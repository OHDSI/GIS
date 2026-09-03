--postgresql CDM DDL Specification for OMOP Common Data Model 5.4
-- Synthetic Dataset with GIS/SDOH Extension
-- Focus: Respiratory + cardiometabolic conditions correlated with PM2.5 air pollution
--   and county-level socioeconomic status (SES)
-- Dataset: 10,000 patients drawn from ~3,100 US counties/county-equivalents
--   (1) Urban density of the assigned county drives PM2.5 (and PM10/Ozone) exposure
--   (2) County SES drives comorbidity frequency (respiratory, cardiovascular, metabolic)
--   PM2.5 exposure additionally drives respiratory + cardiovascular condition risk

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


-- ============================================================================
-- COUNTY_REFERENCE (non-OMOP-standard demo dimension table)
-- ============================================================================
-- One row per synthetic US county / county-equivalent, covering every state
-- plus DC with approximately the real per-state county counts (~3,100 rows
-- total, well beyond the "700+ counties" target). Each county carries an
-- urban-density classification (which drives its baseline PM2.5/PM10/Ozone)
-- and a composite socioeconomic status (SES) index 0-100 (higher = more
-- affluent) which drives county-level SDOH observations and comorbidity
-- frequency. county_fips is a synthetic, FIPS-shaped code (not a real FIPS
-- code) intended to illustrate how this table would join to real gridded or
-- county-level PM2.5 datasets of differing spatial granularity.

CREATE TABLE IF NOT EXISTS omopgis.COUNTY_REFERENCE
(
    county_ref_id            integer      NOT NULL,
    county_name              varchar(80)  NOT NULL,
    state                    varchar(2)   NOT NULL,
    county_fips              varchar(10)  NULL,
    urban_density_category   varchar(20)  NOT NULL, -- Urban Core / Suburban / Small Town / Rural
    pm25_baseline_mean       NUMERIC      NOT NULL,  -- county-level PM2.5 mean, ug/m3
    ses_index                NUMERIC      NOT NULL,  -- 0-100 composite SES, higher = more affluent
    centroid_lat             NUMERIC      NOT NULL,
    centroid_lon             NUMERIC      NOT NULL
);


-- ============================================================================
-- POPULATE SYNTHETIC DATA
-- ============================================================================

-- ============================================================================
-- COUNTIES (nationwide, ~3,100 counties / county-equivalents)
-- ============================================================================
-- state_seed carries, per state: an approximate real county count, a rough
-- lat/lon bounding box for scattering county centroids, an urban_bias
-- (0-1, higher = state skews more urban/metro) and the local naming
-- convention for county-equivalents (County/Parish/Borough).

INSERT INTO omopgis.county_reference(county_ref_id, county_name, state, county_fips,
                                     urban_density_category, pm25_baseline_mean,
                                     ses_index, centroid_lat, centroid_lon)
WITH state_seed(state_abbr, county_count, lat_min, lat_max, lon_min, lon_max, urban_bias, area_suffix) AS (
    VALUES
    ('AL', 67,  32.3, 35.0,  -88.5,  -85.0, 0.35, 'County'),
    ('AK', 29,  55.0, 71.0, -165.0, -141.0, 0.25, 'Borough'),
    ('AZ', 15,  31.3, 37.0, -114.8, -109.0, 0.55, 'County'),
    ('AR', 75,  33.0, 36.5,  -94.6,  -89.6, 0.25, 'County'),
    ('CA', 58,  32.5, 42.0, -124.4, -114.1, 0.65, 'County'),
    ('CO', 64,  37.0, 41.0, -109.1, -102.0, 0.45, 'County'),
    ('CT',  8,  41.0, 42.1,  -73.7,  -71.8, 0.70, 'County'),
    ('DE',  3,  38.4, 39.8,  -75.8,  -75.0, 0.55, 'County'),
    ('FL', 67,  24.5, 31.0,  -87.6,  -80.0, 0.55, 'County'),
    ('GA',159,  30.4, 35.0,  -85.6,  -80.8, 0.35, 'County'),
    ('HI',  5,  18.9, 22.2, -160.2, -154.8, 0.50, 'County'),
    ('ID', 44,  42.0, 49.0, -117.2, -111.0, 0.20, 'County'),
    ('IL',102,  37.0, 42.5,  -91.5,  -87.0, 0.45, 'County'),
    ('IN', 92,  37.8, 41.8,  -88.1,  -84.8, 0.35, 'County'),
    ('IA', 99,  40.4, 43.5,  -96.6,  -90.1, 0.25, 'County'),
    ('KS',105,  37.0, 40.0, -102.1,  -94.6, 0.25, 'County'),
    ('KY',120,  36.5, 39.1,  -89.6,  -81.9, 0.30, 'County'),
    ('LA', 64,  29.0, 33.0,  -94.0,  -89.0, 0.40, 'Parish'),
    ('ME', 16,  43.0, 47.5,  -71.1,  -66.9, 0.25, 'County'),
    ('MD', 24,  37.9, 39.7,  -79.5,  -75.0, 0.55, 'County'),
    ('MA', 14,  41.2, 42.9,  -73.5,  -69.9, 0.70, 'County'),
    ('MI', 83,  41.7, 48.2,  -90.4,  -82.4, 0.40, 'County'),
    ('MN', 87,  43.5, 49.4,  -97.2,  -89.5, 0.35, 'County'),
    ('MS', 82,  30.2, 35.0,  -91.6,  -88.1, 0.25, 'County'),
    ('MO',114,  36.0, 40.6,  -95.8,  -89.1, 0.35, 'County'),
    ('MT', 56,  44.4, 49.0, -116.0, -104.0, 0.15, 'County'),
    ('NE', 93,  40.0, 43.0, -104.1,  -95.3, 0.20, 'County'),
    ('NV', 17,  35.0, 42.0, -120.0, -114.0, 0.45, 'County'),
    ('NH', 10,  42.7, 45.3,  -72.6,  -70.6, 0.40, 'County'),
    ('NJ', 21,  38.9, 41.4,  -75.6,  -73.9, 0.75, 'County'),
    ('NM', 33,  31.3, 37.0, -109.1, -103.0, 0.30, 'County'),
    ('NY', 62,  40.5, 45.0,  -79.8,  -71.9, 0.55, 'County'),
    ('NC',100,  33.8, 36.6,  -84.3,  -75.5, 0.40, 'County'),
    ('ND', 53,  45.9, 49.0, -104.0,  -96.6, 0.20, 'County'),
    ('OH', 88,  38.4, 42.0,  -84.8,  -80.5, 0.45, 'County'),
    ('OK', 77,  33.6, 37.0, -103.0,  -94.4, 0.30, 'County'),
    ('OR', 36,  42.0, 46.3, -124.6, -116.5, 0.40, 'County'),
    ('PA', 67,  39.7, 42.3,  -80.5,  -74.7, 0.50, 'County'),
    ('RI',  5,  41.1, 42.0,  -71.9,  -71.1, 0.75, 'County'),
    ('SC', 46,  32.0, 35.2,  -83.4,  -78.5, 0.35, 'County'),
    ('SD', 66,  42.5, 45.9, -104.1,  -96.4, 0.20, 'County'),
    ('TN', 95,  35.0, 36.7,  -90.3,  -81.6, 0.35, 'County'),
    ('TX',254,  25.8, 36.5, -106.6,  -93.5, 0.40, 'County'),
    ('UT', 29,  37.0, 42.0, -114.1, -109.0, 0.40, 'County'),
    ('VT', 14,  42.7, 45.0,  -73.4,  -71.5, 0.25, 'County'),
    ('VA', 95,  36.5, 39.5,  -83.7,  -75.2, 0.45, 'County'),
    ('WA', 39,  45.5, 49.0, -124.8, -116.9, 0.50, 'County'),
    ('WV', 55,  37.2, 40.6,  -82.6,  -77.7, 0.20, 'County'),
    ('WI', 72,  42.5, 47.1,  -92.9,  -86.8, 0.35, 'County'),
    ('WY', 23,  41.0, 45.0, -111.1, -104.1, 0.15, 'County'),
    ('DC',  1,  38.8, 39.0,  -77.1,  -76.9, 0.90, '')
),
name_pool(nm) AS (
    VALUES
    ('Washington'), ('Jefferson'), ('Franklin'), ('Lincoln'), ('Madison'),
    ('Jackson'), ('Monroe'), ('Union'), ('Clay'), ('Marion'),
    ('Adams'), ('Wayne'), ('Greene'), ('Warren'), ('Fayette'),
    ('Montgomery'), ('Lake'), ('Grant'), ('Douglas'), ('Hamilton'),
    ('Perry'), ('Pike'), ('Polk'), ('Randolph'), ('Scott'),
    ('Clark'), ('Carroll'), ('Harrison'), ('Johnson'), ('Knox'),
    ('Lawrence'), ('Morgan'), ('Orange'), ('Ross'), ('Shelby'),
    ('Sullivan'), ('Wilson'), ('Benton'), ('Cass'), ('Chester')
),
numbered_names AS (
    SELECT nm, row_number() OVER () AS rn FROM name_pool
),
counties_raw AS (
    SELECT s.state_abbr,
           s.lat_min, s.lat_max, s.lon_min, s.lon_max,
           s.urban_bias, s.area_suffix,
           g AS county_seq,
           CASE WHEN s.state_abbr = 'DC' THEN 'District of Columbia'
                ELSE (SELECT nm FROM numbered_names WHERE rn = ((g - 1) % 40) + 1)
           END AS base_name
    FROM state_seed s
    CROSS JOIN LATERAL generate_series(1, s.county_count) AS g
),
counties_scored AS (
    SELECT *,
           LEAST(1.0, GREATEST(0.0, random() * 0.5 + urban_bias * 0.5)) AS density_score
    FROM counties_raw
)
SELECT row_number() OVER (),
       CASE WHEN state_abbr = 'DC' THEN base_name
            WHEN area_suffix = '' THEN base_name
            ELSE base_name || ' ' || area_suffix
       END,
       state_abbr,
       state_abbr || '-' || lpad(county_seq::text, 3, '0'),
       CASE
           WHEN density_score >= 0.75 THEN 'Urban Core'
           WHEN density_score >= 0.50 THEN 'Suburban'
           WHEN density_score >= 0.25 THEN 'Small Town'
           ELSE 'Rural'
       END,
       -- KEY DISCRIMINATIVE FEATURE: urban density drives baseline PM2.5
       CASE
           WHEN density_score >= 0.75 THEN 12.0 + random() * 8.0   -- Urban Core: 12-20 ug/m3
           WHEN density_score >= 0.50 THEN  8.0 + random() * 4.0   -- Suburban:    8-12 ug/m3
           WHEN density_score >= 0.25 THEN  6.0 + random() * 3.0   -- Small Town:  6-9  ug/m3
           ELSE                              3.5 + random() * 3.0  -- Rural:     3.5-6.5 ug/m3
       END,
       ROUND((10 + random() * 85)::numeric, 2),  -- ses_index: 10-95
       lat_min + random() * (lat_max - lat_min),
       lon_min + random() * (lon_max - lon_min)
FROM counties_scored;

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
       (select floor(random() * 80 * (i / i) + 1940)),
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
-- LOCATIONS (each patient is randomly assigned to one of the ~3,100 counties)
-- ============================================================================

-- Note: an uncorrelated "ORDER BY random() LIMIT 1" subquery (even written
-- as a LATERAL join) gets flattened by the planner and evaluated ONCE,
-- assigning every patient to the same county. Assigning a per-row random
-- rank and joining it to a numbered county list forces a genuine per-person
-- draw instead.
CREATE TEMP TABLE county_numbered AS
SELECT county_ref_id, row_number() OVER () AS rn FROM omopgis.county_reference;

CREATE TEMP TABLE person_county AS
SELECT p.person_id, cn.county_ref_id
FROM (
    SELECT person_id, floor(random() * (SELECT count(*) FROM county_numbered)) + 1 AS rn
    FROM omopgis.person
) p
JOIN county_numbered cn ON cn.rn = p.rn;

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
                             longitude,
                             county_ref_id)
SELECT p.person_id,
       CONCAT((floor(random() * 1000 + 1)::integer)::text, ' ',
              (ARRAY['Washington', 'Main', 'Maple', 'Oak', 'Cedar', 'Park', 'Lincoln', 'Elm',
                     'Church', 'Mill', 'River', 'Highland', 'Franklin', 'Chestnut', 'Union'])[floor(random() * 15 + 1)::integer],
              ' ',
              (ARRAY['St', 'Ave', 'Rd', 'Dr', 'Ln', 'Blvd', 'Way'])[floor(random() * 7 + 1)::integer]),
       NULL,
       CONCAT(c.county_name, ' ',
              (ARRAY['Heights', 'Springs', 'Falls', 'Junction', 'Center', 'Crossing',
                     'Village', 'City', 'Corner', 'Landing'])[floor(random() * 10 + 1)::integer]),
       c.state,
       lpad(floor(random() * 99999)::text, 5, '0'),
       c.county_name,
       CONCAT('TRACT-', LPAD(p.person_id::text, 6, '0')),
       NULL,
       NULL,
       -- jitter around the county centroid so patients within a county aren't co-located
       c.centroid_lat + (random() - 0.5) * 0.1,
       c.centroid_lon + (random() - 0.5) * 0.1,
       c.county_ref_id
FROM person_county p
JOIN omopgis.county_reference c ON c.county_ref_id = p.county_ref_id;

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
       '2014-01-01'::date,
       '2019-12-31'::date
FROM omopgis.person p;

-- ============================================================================
-- EXTERNAL EXPOSURES (Place-based Environmental Exposures)
-- ============================================================================
-- Place-based environmental exposures stored in EXTERNAL_EXPOSURE, following
-- the Gaia CDM Extension. PM2.5, PM10, and Ozone are drawn from each
-- person's COUNTY baseline, so urban-core counties show systematically
-- higher pollution than suburban/small-town/rural counties.
--
-- exposure_type_concept_id: 32817 (EHR) - could be refined to air quality database type
-- exposure_relationship_concept_id: 44818800 - "Exposed to" from SNOMED

-- PM2.5 Air Quality Index (concept: 2052497664)
-- KEY DISCRIMINATIVE FEATURE: urban-core counties have higher PM2.5 exposure
INSERT INTO omopgis.external_exposure(location_id,
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
SELECT p.location_id,
       p.person_id,
       2052497664, -- PM2.5 Air Quality Index
       '2014-01-01'::date,
       NULL,
       '2019-12-31'::date,
       NULL,
       32817, -- EHR / Environmental data type
       44818800, -- "Exposed to" relationship
       2052499878, -- Air Quality Database (OMOP SDOH concept)
       'EPA_AQI_PM25',
       'Residential exposure',
       'ug/m3',
       NULL,
       NULL,
       NULL,
       GREATEST(2.0, c.pm25_baseline_mean + (random() - 0.5) * 6.0),
       NULL,
       8837  -- ug/m3 (micrograms per cubic meter)
FROM omopgis.person p
JOIN omopgis.location l ON l.location_id = p.location_id
JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id;

-- PM10 Air Quality Index (concept: 2052497665)
INSERT INTO omopgis.external_exposure(location_id,
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
SELECT p.location_id,
       p.person_id,
       2052497665, -- PM10 Air Quality Index
       '2014-01-01'::date,
       NULL,
       '2019-12-31'::date,
       NULL,
       32817,
       44818800,
       2052499878, -- Air Quality Database
       'EPA_AQI_PM10',
       'Residential exposure',
       'ug/m3',
       NULL,
       NULL,
       NULL,
       GREATEST(4.0, c.pm25_baseline_mean * 1.6 + (random() - 0.5) * 10.0),
       NULL,
       8837
FROM omopgis.person p
JOIN omopgis.location l ON l.location_id = p.location_id
JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id;

-- Ozone Air Quality Index (concept: 2052497666)
INSERT INTO omopgis.external_exposure(location_id,
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
SELECT p.location_id,
       p.person_id,
       2052497666, -- Ozone Air Quality Index
       '2014-01-01'::date,
       NULL,
       '2019-12-31'::date,
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
       GREATEST(15.0, 25.0 + c.pm25_baseline_mean * 1.2 + (random() - 0.5) * 20.0),
       NULL,
       8482  -- ppb (parts per billion)
FROM omopgis.person p
JOIN omopgis.location l ON l.location_id = p.location_id
JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id;

-- Nitrogen Dioxide, NO2 (concept: 2052497667) - traffic-related pollutant, tracks PM2.5
INSERT INTO omopgis.external_exposure(location_id,
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
SELECT p.location_id,
       p.person_id,
       2052497667, -- Nitrogen Dioxide (NO2) Air Quality Index
       '2014-01-01'::date,
       NULL,
       '2019-12-31'::date,
       NULL,
       32817,
       44818800,
       2052499878, -- Air Quality Database
       'EPA_AQI_NO2',
       'Residential exposure',
       'ppb',
       NULL,
       NULL,
       NULL,
       GREATEST(2.0, c.pm25_baseline_mean * 1.1 + (random() - 0.5) * 8.0),
       NULL,
       8482
FROM omopgis.person p
JOIN omopgis.location l ON l.location_id = p.location_id
JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id;

-- Ambient Noise Level (concept: 2052497668) - louder in denser counties
INSERT INTO omopgis.external_exposure(location_id,
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
SELECT p.location_id,
       p.person_id,
       2052497668, -- Ambient Noise Level
       '2014-01-01'::date,
       NULL,
       '2019-12-31'::date,
       NULL,
       32817,
       44818800,
       2052499878, -- Air Quality Database
       'NOISE_DB',
       'Residential exposure',
       'dB',
       NULL,
       NULL,
       NULL,
       GREATEST(35.0, 40.0 + c.pm25_baseline_mean * 1.3 + (random() - 0.5) * 10.0),
       NULL,
       8534 -- decibel
FROM omopgis.person p
JOIN omopgis.location l ON l.location_id = p.location_id
JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id;

-- Tree Canopy / Green Space Coverage (concept: 2052497669) - inversely tied to urban density
INSERT INTO omopgis.external_exposure(location_id,
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
SELECT p.location_id,
       p.person_id,
       2052497669, -- Tree Canopy / Green Space Coverage
       '2014-01-01'::date,
       NULL,
       '2019-12-31'::date,
       NULL,
       32817,
       44818800,
       2052499878, -- Air Quality Database
       'GREEN_SPACE_PCT',
       'Residential exposure',
       'percent',
       NULL,
       NULL,
       NULL,
       GREATEST(2.0, LEAST(80.0, 60.0 - c.pm25_baseline_mean * 2.0 + (random() - 0.5) * 12.0)),
       NULL,
       8554 -- percent
FROM omopgis.person p
JOIN omopgis.location l ON l.location_id = p.location_id
JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id;

-- ============================================================================
-- PERSON RISK FACTORS (helper table for condition generation)
-- ============================================================================
-- One row per person carrying their PM2.5 exposure and county SES, reused
-- across every condition below so probabilities stay consistent.

CREATE TEMP TABLE person_risk_factors AS
SELECT p.person_id,
       ee.value_as_number AS pm25_value,
       c.ses_index,
       c.urban_density_category,
       c.county_ref_id
FROM omopgis.person p
JOIN omopgis.location l ON p.location_id = l.location_id
JOIN omopgis.county_reference c ON l.county_ref_id = c.county_ref_id
JOIN omopgis.external_exposure ee
     ON ee.person_id = p.person_id AND ee.exposure_concept_id = 2052497664;

-- ============================================================================
-- CONDITIONS / COMORBIDITIES
-- ============================================================================
-- Three groups of conditions, each with its own risk formula built from the
-- same two drivers:
--   pm_term  = GREATEST(0, pm25_value - 10) * <pm coefficient>
--   ses_term = GREATEST(0, 60 - ses_index)   * <ses coefficient>
-- Respiratory conditions weight pm_term heavily; cardiovascular conditions
-- weight both; metabolic/renal comorbidities weight ses_term heavily -
-- matching the literature on PM2.5 and socioeconomic drivers of disease.

-- Asthma (317009)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 317009,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'ASTHMA', 317009
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.08 + GREATEST(0, prf.pm25_value - 10) * 0.012 + GREATEST(0, 60 - prf.ses_index) * 0.0008);

-- COPD (255573)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 255573,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'COPD', 255573
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.05 + GREATEST(0, prf.pm25_value - 10) * 0.010 + GREATEST(0, 60 - prf.ses_index) * 0.0010);

-- Chronic Bronchitis (258780)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 258780,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'BRONCHITIS', 258780
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.04 + GREATEST(0, prf.pm25_value - 10) * 0.009 + GREATEST(0, 60 - prf.ses_index) * 0.0008);

-- Allergic Rhinitis (4170143)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 4170143,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'RHINITIS', 4170143
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.12 + GREATEST(0, prf.pm25_value - 10) * 0.006 + GREATEST(0, 60 - prf.ses_index) * 0.0003);

-- Pneumonia (255848) - previously miscoded to reuse the Chronic Bronchitis concept; fixed here.
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 255848,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'PNEUMONIA', 255848
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.04 + GREATEST(0, prf.pm25_value - 10) * 0.008 + GREATEST(0, 60 - prf.ses_index) * 0.0010);

-- Hypertension (320128)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 320128,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'HYPERTENSION', 320128
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.15 + GREATEST(0, prf.pm25_value - 10) * 0.003 + GREATEST(0, 60 - prf.ses_index) * 0.0020);

-- Coronary Arteriosclerosis / CAD (317576)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 317576,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'CAD', 317576
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.04 + GREATEST(0, prf.pm25_value - 10) * 0.005 + GREATEST(0, 60 - prf.ses_index) * 0.0022);

-- Congestive Heart Failure (319835)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 319835,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'CHF', 319835
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.025 + GREATEST(0, prf.pm25_value - 10) * 0.004 + GREATEST(0, 60 - prf.ses_index) * 0.0022);

-- Acute Myocardial Infarction (4329847)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 4329847,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'MI', 4329847
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.02 + GREATEST(0, prf.pm25_value - 10) * 0.005 + GREATEST(0, 60 - prf.ses_index) * 0.0020);

-- Cerebrovascular Disease / Stroke (381316)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 381316,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'STROKE', 381316
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.02 + GREATEST(0, prf.pm25_value - 10) * 0.005 + GREATEST(0, 60 - prf.ses_index) * 0.0020);

-- Type 2 Diabetes Mellitus (201826)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 201826,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'T2DM', 201826
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.07 + GREATEST(0, prf.pm25_value - 10) * 0.001 + GREATEST(0, 60 - prf.ses_index) * 0.0030);

-- Obesity (433736)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 433736,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'OBESITY', 433736
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.12 + GREATEST(0, prf.pm25_value - 10) * 0.0005 + GREATEST(0, 60 - prf.ses_index) * 0.0025);

-- Hyperlipidemia (432867)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 432867,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'HYPERLIPIDEMIA', 432867
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.14 + GREATEST(0, prf.pm25_value - 10) * 0.001 + GREATEST(0, 60 - prf.ses_index) * 0.0022);

-- Chronic Kidney Disease (46271022)
INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT prf.person_id, 46271022,
       ('2014-01-01'::timestamp + random() * ('2019-12-31'::timestamp - '2014-01-01'::timestamp))::date,
       32817, 'CKD', 46271022
FROM person_risk_factors prf
WHERE random() < LEAST(0.85, 0.03 + GREATEST(0, prf.pm25_value - 10) * 0.001 + GREATEST(0, 60 - prf.ses_index) * 0.0030);

-- ============================================================================
-- SOCIOECONOMIC DETERMINANTS (SDOH Observations)
-- ============================================================================
-- County-level poverty, education, housing cost burden, employment, and
-- neighborhood disadvantage, all derived directly from the same county
-- ses_index that drives comorbidity frequency above - so these observations
-- and the conditions they correlate with in downstream analysis are
-- consistent with one another rather than independently randomized.

-- Poverty Rate (concept 2051503454 - Poverty)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051503454, '2016-07-01'::date, 32817,
       GREATEST(1.0, LEAST(45.0, 45.0 - prf.ses_index * 0.4 + (random() - 0.5) * 10.0)),
       8554, 'POVERTY_RATE', 2051503454, 'percent'
FROM person_risk_factors prf;

-- Education Level, years (concept 2051502048 - Education_Level)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051502048, '2016-07-01'::date, 32817,
       GREATEST(8.0, LEAST(20.0, 9.0 + prf.ses_index * 0.11 + (random() - 0.5) * 3.0)),
       8505, 'EDUCATION_YEARS', 2051502048, 'years'
FROM person_risk_factors prf;

-- Housing Cost Burden (concept 2051503305 - Housing_Cost)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051503305, '2016-07-01'::date, 32817,
       GREATEST(10.0, LEAST(65.0, 55.0 - prf.ses_index * 0.35 + (random() - 0.5) * 10.0)),
       8554, 'HOUSING_COST_PCT', 2051503305, 'percent'
FROM person_risk_factors prf;

-- Employment Status (concept 2051501588 - Employment_Status)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, value_as_string,
                                observation_source_value, observation_source_concept_id)
SELECT prf.person_id, 2051501588, '2016-07-01'::date, 32817,
       CASE WHEN random() < GREATEST(0.02, LEAST(0.40, 0.35 - prf.ses_index * 0.003)) THEN 0 ELSE 1 END,
       CASE WHEN random() < GREATEST(0.02, LEAST(0.40, 0.35 - prf.ses_index * 0.003)) THEN 'Unemployed' ELSE 'Employed' END,
       'EMPLOYMENT', 2051501588
FROM person_risk_factors prf;

-- Neighborhood Concentrated Disadvantage (concept 2051502386)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051502386, '2016-07-01'::date, 32817,
       GREATEST(0.0, LEAST(1.0, 1.0 - prf.ses_index / 100.0 + (random() - 0.5) * 0.2)),
       'NEIGHBORHOOD_DISADVANTAGE', 2051502386, 'index'
FROM person_risk_factors prf;

-- Food Insecurity Rate (concept 2051504000)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051504000, '2016-07-01'::date, 32817,
       GREATEST(1.0, LEAST(40.0, 35.0 - prf.ses_index * 0.35 + (random() - 0.5) * 8.0)),
       8554, 'FOOD_INSECURITY_RATE', 2051504000, 'percent'
FROM person_risk_factors prf;

-- Primary Care Physician Access (concept 2051504001) - physicians per 10,000 residents
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051504001, '2016-07-01'::date, 32817,
       GREATEST(2.0, LEAST(25.0, 3.0 + prf.ses_index * 0.20 + (random() - 0.5) * 4.0)),
       'PCP_ACCESS_RATIO', 2051504001, 'per_10000'
FROM person_risk_factors prf;

-- Social Isolation Index (concept 2051504002)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051504002, '2016-07-01'::date, 32817,
       GREATEST(0.0, LEAST(1.0, 0.9 - prf.ses_index / 100.0 + (random() - 0.5) * 0.2)),
       'SOCIAL_ISOLATION_INDEX', 2051504002, 'index'
FROM person_risk_factors prf;

-- Uninsured Rate (concept 2051504003)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051504003, '2016-07-01'::date, 32817,
       GREATEST(1.0, LEAST(30.0, 25.0 - prf.ses_index * 0.22 + (random() - 0.5) * 6.0)),
       8554, 'UNINSURED_RATE', 2051504003, 'percent'
FROM person_risk_factors prf;

-- Broadband Internet Access (concept 2051504004)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051504004, '2016-07-01'::date, 32817,
       GREATEST(30.0, LEAST(99.0, 55.0 + prf.ses_index * 0.42 + (random() - 0.5) * 8.0)),
       8554, 'BROADBAND_ACCESS_PCT', 2051504004, 'percent'
FROM person_risk_factors prf;

-- Violent Crime Rate (concept 2051504005) - per 1,000 residents
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2051504005, '2016-07-01'::date, 32817,
       GREATEST(0.5, LEAST(25.0, 22.0 - prf.ses_index * 0.20 + (random() - 0.5) * 6.0)),
       'VIOLENT_CRIME_RATE', 2051504005, 'per_1000'
FROM person_risk_factors prf;

-- Air Quality Index Category (concept 2051504006) - derived from PM2.5, mirrors urban density
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, value_as_string,
                                observation_source_value, observation_source_concept_id)
SELECT prf.person_id, 2051504006, '2016-07-01'::date, 32817,
       ROUND(LEAST(300.0, prf.pm25_value * 4.2)::numeric, 1),
       CASE
           WHEN prf.pm25_value * 4.2 >= 150 THEN 'Unhealthy'
           WHEN prf.pm25_value * 4.2 >= 100 THEN 'Unhealthy for Sensitive Groups'
           WHEN prf.pm25_value * 4.2 >= 50  THEN 'Moderate'
           ELSE 'Good'
       END,
       'AQI_CATEGORY', 2051504006
FROM person_risk_factors prf;

-- ============================================================================
-- RESPIRATORY DRUGS
-- ============================================================================
-- Asthma medications for patients with asthma

-- Albuterol (Inhaler) - 1154343
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1154343,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 90)::integer,
       32817, 3, 1, 90, '2 puffs every 4-6 hours as needed', 4186831,
       'ALBUTEROL', 1154343, 'Inhalation', 'puffs'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009; -- Asthma patients only

-- Fluticasone (Inhaled Corticosteroid) - 1115008
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1115008,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 180)::integer,
       32817, 5, 1, 180, '2 puffs twice daily', 4186831,
       'FLUTICASONE', 1115008, 'Inhalation', 'puffs'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.7; -- 70% of asthma patients

-- Montelukast (Singulair) - 1547504
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1547504,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '10mg once daily at bedtime', 4132161,
       'MONTELUKAST', 1547504, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.5; -- 50% of asthma patients

-- Tiotropium Bromide (Long-Acting Bronchodilator) - 986417 - COPD patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 986417,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '1 capsule inhaled once daily', 4186831,
       'TIOTROPIUM', 986417, 'Inhalation', 'mcg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 255573
AND random() < 0.8; -- 80% of COPD patients

-- Guaifenesin (Expectorant) - 1301025 - Chronic Bronchitis patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1301025,
       co.condition_start_date + floor(random() * 14)::integer,
       co.condition_start_date + floor(random() * 14 + 14)::integer,
       32817, 1, 14, 14, '400mg every 4 hours as needed', 4132161,
       'GUAIFENESIN', 1301025, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 258780
AND random() < 0.4; -- 40% of bronchitis patients

-- Cetirizine (Antihistamine) - 985708 - Allergic Rhinitis patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 985708,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '10mg once daily', 4132161,
       'CETIRIZINE', 985708, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 4170143
AND random() < 0.6; -- 60% of rhinitis patients

-- Azithromycin (Macrolide Antibiotic) - 1734104 - Pneumonia patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1734104,
       co.condition_start_date,
       co.condition_start_date + 5,
       32817, 0, 5, 5, '500mg day 1, then 250mg daily days 2-5', 4132161,
       'AZITHROMYCIN', 1734104, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 255848
AND random() < 0.9; -- 90% of pneumonia patients

-- ============================================================================
-- CARDIOMETABOLIC DRUGS
-- ============================================================================

-- Lisinopril (ACE inhibitor) - 1308216 - Hypertension patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1308216,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '10mg once daily', 4132161,
       'LISINOPRIL', 1308216, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 320128
AND random() < 0.7; -- 70% of hypertension patients

-- Metformin - 1503297 - Type 2 Diabetes patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1503297,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 60, 365, '500mg twice daily', 4132161,
       'METFORMIN', 1503297, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 201826
AND random() < 0.75; -- 75% of T2DM patients

-- Atorvastatin - 1545958 - Hyperlipidemia patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1545958,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '20mg once daily at bedtime', 4132161,
       'ATORVASTATIN', 1545958, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 432867
AND random() < 0.65; -- 65% of hyperlipidemia patients

-- Aspirin (Antiplatelet) - 1112807 - CAD and MI patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1112807,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 90, 365, '81mg once daily', 4132161,
       'ASPIRIN', 1112807, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317576, 4329847) -- CAD, MI
AND random() < 0.85;

-- Clopidogrel (Antiplatelet) - 1322184 - CAD and Stroke patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1322184,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '75mg once daily', 4132161,
       'CLOPIDOGREL', 1322184, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317576, 381316) -- CAD, Stroke
AND random() < 0.5;

-- Furosemide (Loop Diuretic) - 956874 - CHF patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 956874,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '40mg once daily', 4132161,
       'FUROSEMIDE', 956874, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835
AND random() < 0.75; -- 75% of CHF patients

-- Carvedilol (Beta Blocker) - 933724 - CHF patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 933724,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 60, 365, '3.125mg twice daily', 4132161,
       'CARVEDILOL', 933724, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835
AND random() < 0.65; -- 65% of CHF patients

-- Warfarin (Anticoagulant) - 1310149 - Stroke patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1310149,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '5mg once daily, adjust to INR', 4132161,
       'WARFARIN', 1310149, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 381316
AND random() < 0.3; -- 30% of stroke patients

-- ============================================================================
-- RESPIRATORY PROCEDURES
-- ============================================================================
-- Pulmonary Function Test (Spirometry) - 40757101

INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 40757101,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, 1, 'SPIROMETRY', 40757101
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.8; -- 80% of asthma patients get spirometry

-- Chest X-ray - 2211348 - COPD and Pneumonia patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 2211348,
       co.condition_start_date + floor(random() * 14)::integer,
       32817, 1, 'CHEST_XRAY', 2211348
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (255573, 255848) -- COPD, Pneumonia
AND random() < 0.7;

-- ============================================================================
-- CARDIOMETABOLIC PROCEDURES
-- ============================================================================

-- Electrocardiogram (ECG) - 40756884 - CAD and MI patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 40756884,
       co.condition_start_date + floor(random() * 30)::integer,
       32817, 1, 'ECG', 40756884
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317576, 4329847) -- CAD, MI
AND random() < 0.85;

-- Echocardiogram - 4142900 - CHF patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4142900,
       co.condition_start_date + floor(random() * 30)::integer,
       32817, 1, 'ECHOCARDIOGRAM', 4142900
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835
AND random() < 0.75; -- 75% of CHF patients

-- Coronary Angiography - 4234728 - MI patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4234728,
       co.condition_start_date + floor(random() * 5)::integer,
       32817, 1, 'CORONARY_ANGIOGRAPHY', 4234728
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 4329847 -- MI
AND random() < 0.6;

-- Cardiac Stress Test - 4239536 - CAD patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4239536,
       co.condition_start_date + floor(random() * 60)::integer,
       32817, 1, 'CARDIAC_STRESS_TEST', 4239536
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317576 -- CAD
AND random() < 0.5;

-- Hemodialysis - 4032243 - CKD patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4032243,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, 1, 'HEMODIALYSIS', 4032243
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 46271022 -- CKD
AND random() < 0.25; -- 25% of CKD patients (advanced/ESRD subset)

-- ============================================================================
-- RESPIRATORY & CARDIOMETABOLIC MEASUREMENTS
-- ============================================================================

-- Peak Expiratory Flow Rate (PEFR) - 3034006, lower for asthma/COPD
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3034006,
       co.condition_start_date + floor(random() * 365)::integer,
       32817,
       CASE
           WHEN co.condition_concept_id = 317009
           THEN (200.0 + random() * 200.0)  -- Asthma: 200-400 L/min (reduced)
           ELSE (400.0 + random() * 200.0)  -- Normal: 400-600 L/min
       END,
       8698, 'PEFR', 3034006, 'L/min'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317009, 255573)  -- Asthma and COPD
AND random() < 0.6;

-- Systolic Blood Pressure - 3004249, elevated for hypertension patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3004249,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (135.0 + random() * 35.0), -- 135-170 mmHg
       8876, 'SBP', 3004249, 'mmHg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 320128
AND random() < 0.9;

-- Diastolic Blood Pressure - 3012888, elevated for hypertension patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3012888,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (85.0 + random() * 20.0), -- 85-105 mmHg
       8876, 'DBP', 3012888, 'mmHg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 320128
AND random() < 0.9;

-- Hemoglobin A1c - 3004410, elevated for T2DM patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3004410,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (6.8 + random() * 3.2), -- 6.8-10.0 %
       8554, 'HBA1C', 3004410, 'percent'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 201826
AND random() < 0.85;

-- LDL Cholesterol - 3028437, elevated for hyperlipidemia patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3028437,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (130.0 + random() * 90.0), -- 130-220 mg/dL
       8840, 'LDL', 3028437, 'mg/dL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 432867
AND random() < 0.85;

-- Body Mass Index - 3038553, elevated for obesity patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3038553,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (30.0 + random() * 15.0), -- 30-45 kg/m2
       9531, 'BMI', 3038553, 'kg/m2'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 433736
AND random() < 0.9;

-- Oxygen Saturation (SpO2) - 40762499, reduced for COPD/Pneumonia patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 40762499,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (86.0 + random() * 10.0), -- 86-96 %
       8554, 'SPO2', 40762499, 'percent'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (255573, 255848) -- COPD, Pneumonia
AND random() < 0.7;

-- Eosinophil Count - 3010813, elevated for Asthma/Allergic Rhinitis patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3010813,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (300.0 + random() * 400.0), -- 300-700 cells/uL
       8784, 'EOSINOPHIL_COUNT', 3010813, 'cells/uL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317009, 4170143) -- Asthma, Allergic Rhinitis
AND random() < 0.55;

-- Serum Creatinine - 3016723, elevated for CKD patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3016723,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (1.5 + random() * 3.0), -- 1.5-4.5 mg/dL
       8840, 'CREATININE', 3016723, 'mg/dL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 46271022 -- CKD
AND random() < 0.9;

-- Estimated GFR - 3013705, reduced for CKD patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3013705,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (10.0 + random() * 50.0), -- 10-60 mL/min/1.73m2
       8794, 'EGFR', 3013705, 'mL/min/1.73m2'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 46271022 -- CKD
AND random() < 0.9;

-- Troponin I - 3033891, elevated for MI patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3033891,
       co.condition_start_date + floor(random() * 3)::integer,
       32817, (0.5 + random() * 9.5), -- 0.5-10.0 ng/mL
       8842, 'TROPONIN', 3033891, 'ng/mL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 4329847 -- MI
AND random() < 0.95;

-- B-type Natriuretic Peptide (BNP) - 3011960, elevated for CHF patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3011960,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (400.0 + random() * 1600.0), -- 400-2000 pg/mL
       8842, 'BNP', 3011960, 'pg/mL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835 -- CHF
AND random() < 0.8;

-- Left Ventricular Ejection Fraction - 3011923, reduced for CHF patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3011923,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (15.0 + random() * 30.0), -- 15-45 %
       8554, 'EJECTION_FRACTION', 3011923, 'percent'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835 -- CHF
AND random() < 0.75;

-- Waist Circumference - 3003397, elevated for Obesity patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3003397,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (100.0 + random() * 40.0), -- 100-140 cm
       8582, 'WAIST_CIRCUMFERENCE', 3003397, 'cm'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 433736 -- Obesity
AND random() < 0.85;

-- Triglycerides - 3022192, elevated for Hyperlipidemia patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3022192,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (175.0 + random() * 225.0), -- 175-400 mg/dL
       8840, 'TRIGLYCERIDES', 3022192, 'mg/dL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 432867 -- Hyperlipidemia
AND random() < 0.85;

-- White Blood Cell Count - 3000905, elevated for Pneumonia patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3000905,
       co.condition_start_date + floor(random() * 5)::integer,
       32817, (11.0 + random() * 9.0), -- 11-20 x10^3/uL
       8848, 'WBC_COUNT', 3000905, 'x10^3/uL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 255848 -- Pneumonia
AND random() < 0.85;

-- ============================================================================
-- OBSERVATION PERIODS
-- ============================================================================
-- Everyone has observation period from 2014-2019

INSERT INTO omopgis.observation_period(person_id,
                                       observation_period_start_date,
                                       observation_period_end_date,
                                       period_type_concept_id)
SELECT person_id,
       '2014-01-01'::date,
       '2019-12-31'::date,
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
        'Synthetic dataset with 10,000 patients sampled across ~3,100 US counties/county-equivalents, demonstrating respiratory (asthma, COPD, chronic bronchitis, allergic rhinitis, pneumonia) and cardiometabolic (hypertension, coronary artery disease, congestive heart failure, myocardial infarction, stroke, type 2 diabetes, obesity, hyperlipidemia, chronic kidney disease) comorbidities correlated with environmental exposures (PM2.5, PM10, Ozone - driven by county urban density) and county-level socioeconomic determinants (poverty, education, housing, employment, neighborhood disadvantage - driving comorbidity frequency). Designed for OHDSI patient-level prediction pipelines and for joining against real gridded/county-level PM2.5 datasets of differing spatial and temporal granularity.',
        'https://github.com/OHDSI/CommonDataModel',
        'Synthetic Data Generator v2.0',
        '2026-09-03'::date,
        '2026-09-03'::date,
        '5.4',
        756265,
        'GIS v1.0');
