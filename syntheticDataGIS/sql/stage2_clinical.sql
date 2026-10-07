-- Stage 2: fixtures, clinical data and SDOH drawn from the exposure gaiaDB derived
-- in working.external_exposure. omopgis.external_exposure stays empty on purpose.

SELECT setseed(0.20261006);

DO $$
DECLARE n bigint; expected bigint;
BEGIN
    SELECT count(*) INTO n FROM working.external_exposure WHERE exposure_concept_id = 2052499839;
    SELECT count(*) INTO expected FROM omopgis.location_history lh;
    IF n = 0 THEN
        RAISE EXCEPTION 'working.external_exposure has no pm25_mean_pred rows - run the gaiaDB spatial join first';
    END IF;
    RAISE NOTICE 'gaiaDB exposure rows (pm25_mean_pred): % for % residence intervals', n, expected;
    SELECT count(*) INTO n FROM working.external_exposure WHERE exposure_concept_id = 2052497744;
    IF n <> expected THEN
        RAISE EXCEPTION 'expected % ses_index rows (one per residence interval), found % - run the gaiaDB SES join first', expected, n;
    END IF;
END $$;

-- Fixtures (see demo.fixture_person) and answer key (demo.expected_result)

-- Bad staging rows for the exposure QA drill; never part of the clean exposure
CREATE TABLE demo.rejected_exposure_row
(
    LIKE omopgis.external_exposure INCLUDING DEFAULTS,
    reject_reason  varchar(40) NOT NULL,
    fixture_tag    varchar(40) NOT NULL
);

-- DUPLICATE_SOURCE_ROW: exact copy of the person's 2017-03 PM2.5 row
INSERT INTO demo.rejected_exposure_row
SELECT ee.external_exposure_id, ee.location_id, ee.person_id, ee.exposure_concept_id,
       ee.exposure_start_date, ee.exposure_start_datetime, ee.exposure_end_date, ee.exposure_end_datetime,
       ee.exposure_type_concept_id, ee.exposure_relationship_concept_id, ee.exposure_source_concept_id,
       ee.exposure_source_value, ee.exposure_relationship_source_value,
       ee.dose_unit_source_value, ee.quantity, ee.modifier_source_value, ee.operator_concept_id,
       ee.value_as_number, ee.value_as_concept_id, ee.unit_concept_id,
       'DUPLICATE_SOURCE_ROW', fp.fixture_tag
FROM demo.fixture_person fp
JOIN working.external_exposure ee ON ee.person_id = fp.person_id
WHERE fp.fixture_tag = 'DUPLICATE_SOURCE_ROW'
  AND ee.exposure_concept_id = 2052499839 AND ee.exposure_start_date = '2017-03-01';

-- UNIT_MISMATCH: 2017-04 row delivered in mg/m3 (value / 1000, unit unmapped)
INSERT INTO demo.rejected_exposure_row
SELECT ee.external_exposure_id, ee.location_id, ee.person_id, ee.exposure_concept_id,
       ee.exposure_start_date, ee.exposure_start_datetime, ee.exposure_end_date, ee.exposure_end_datetime,
       ee.exposure_type_concept_id, ee.exposure_relationship_concept_id, ee.exposure_source_concept_id,
       ee.exposure_source_value, ee.exposure_relationship_source_value,
       'mg/m3', ee.quantity, ee.modifier_source_value, ee.operator_concept_id,
       ee.value_as_number / 1000.0, ee.value_as_concept_id, 0,
       'UNIT_MISMATCH', fp.fixture_tag
FROM demo.fixture_person fp
JOIN working.external_exposure ee ON ee.person_id = fp.person_id
WHERE fp.fixture_tag = 'UNIT_MISMATCH'
  AND ee.exposure_concept_id = 2052499839 AND ee.exposure_start_date = '2017-04-01';

-- NON_OVERLAPPING_INTERVAL: a January 2020 row, after the residence/observation period
INSERT INTO demo.rejected_exposure_row
SELECT ee.external_exposure_id, ee.location_id, ee.person_id, ee.exposure_concept_id,
       '2020-01-01'::date, ee.exposure_start_datetime, '2020-01-31'::date, ee.exposure_end_datetime,
       ee.exposure_type_concept_id, ee.exposure_relationship_concept_id, ee.exposure_source_concept_id,
       ee.exposure_source_value, ee.exposure_relationship_source_value,
       ee.dose_unit_source_value, ee.quantity, ee.modifier_source_value, ee.operator_concept_id,
       ee.value_as_number, ee.value_as_concept_id, ee.unit_concept_id,
       'NON_OVERLAPPING_INTERVAL', fp.fixture_tag
FROM demo.fixture_person fp
JOIN working.external_exposure ee ON ee.person_id = fp.person_id
WHERE fp.fixture_tag = 'NON_OVERLAPPING_INTERVAL'
  AND ee.exposure_concept_id = 2052499839 AND ee.exposure_start_date = '2019-12-01';

-- MISSING_EXPOSURE_VALUE: source row with a NULL value; month removed from the clean table
INSERT INTO demo.rejected_exposure_row
SELECT ee.external_exposure_id, ee.location_id, ee.person_id, ee.exposure_concept_id,
       ee.exposure_start_date, ee.exposure_start_datetime, ee.exposure_end_date, ee.exposure_end_datetime,
       ee.exposure_type_concept_id, ee.exposure_relationship_concept_id, ee.exposure_source_concept_id,
       ee.exposure_source_value, ee.exposure_relationship_source_value,
       ee.dose_unit_source_value, ee.quantity, ee.modifier_source_value, ee.operator_concept_id,
       NULL, ee.value_as_concept_id, ee.unit_concept_id,
       'MISSING_VALUE', fp.fixture_tag
FROM demo.fixture_person fp
JOIN working.external_exposure ee ON ee.person_id = fp.person_id
WHERE fp.fixture_tag = 'MISSING_EXPOSURE_VALUE'
  AND ee.exposure_concept_id = 2052499839 AND ee.exposure_start_date = '2017-05-01';

-- gaiaDB assigns external_exposure_id in join order, which is not stable across
-- rebuilds: renumber the staging rows deterministically.
UPDATE demo.rejected_exposure_row r
SET external_exposure_id = x.rn
FROM (SELECT ctid AS row_id, row_number() OVER (ORDER BY person_id, exposure_start_date, reject_reason) AS rn
      FROM demo.rejected_exposure_row) x
WHERE r.ctid = x.row_id;

-- Pregnancy episodes: Disease Episode (32533) whose object is the Pregnancy condition (4299535)
INSERT INTO omopgis.episode(episode_id, person_id, episode_concept_id, episode_start_date, episode_end_date,
                            episode_number, episode_object_concept_id, episode_type_concept_id,
                            episode_source_value, episode_source_concept_id)
SELECT row_number() OVER (ORDER BY fp.fixture_tag DESC),
       fp.person_id,
       32533,
       CASE fp.fixture_tag WHEN 'PREGNANCY_STATIC' THEN '2016-03-18'::date ELSE '2016-05-20'::date END,
       CASE fp.fixture_tag WHEN 'PREGNANCY_STATIC' THEN '2016-12-09'::date ELSE '2017-02-10'::date END,
       1,
       4299535,
       32817,
       fp.fixture_tag,
       NULL
FROM demo.fixture_person fp
WHERE fp.fixture_tag IN ('PREGNANCY_STATIC', 'PREGNANCY_MOVER');

CREATE TABLE demo.expected_result
(
    fixture_tag  varchar(40)  NOT NULL,
    person_id    integer      NULL,
    metric       varchar(60)  NOT NULL,
    value        numeric      NULL,
    unit         varchar(20)  NULL,
    notes        text         NULL
);

-- Mean PM2.5 in pregnancy: day-weighted (correct) vs naive mean of overlapping rows
INSERT INTO demo.expected_result(fixture_tag, person_id, metric, value, unit, notes)
WITH ep AS (
    SELECT e.person_id, e.episode_source_value AS tag, e.episode_start_date AS s, e.episode_end_date AS e
    FROM omopgis.episode e
),
daily AS (
    SELECT ep.tag, ep.person_id, (ep.s + g) AS d, ee.value_as_number
    FROM ep
    CROSS JOIN LATERAL generate_series(0, ep.e - ep.s) g
    JOIN working.external_exposure ee
         ON ee.person_id = ep.person_id AND ee.exposure_concept_id = 2052499839
        AND (ep.s + g) BETWEEN ee.exposure_start_date AND ee.exposure_end_date
),
naive AS (
    SELECT ep.tag, ep.person_id, count(*) AS n_rows, avg(ee.value_as_number) AS naive_mean
    FROM ep
    JOIN working.external_exposure ee
         ON ee.person_id = ep.person_id AND ee.exposure_concept_id = 2052499839
        AND ee.exposure_start_date <= ep.e AND ee.exposure_end_date >= ep.s
    GROUP BY ep.tag, ep.person_id
)
SELECT tag, person_id, 'mean_pm25_during_pregnancy_day_weighted', round(avg(value_as_number)::numeric, 4), 'ug/m3',
       'Correct answer: each day of the episode weighted by the exposure row covering it' FROM daily GROUP BY tag, person_id
UNION ALL
SELECT tag, person_id, 'mean_pm25_during_pregnancy_naive_row_mean', round(naive_mean::numeric, 4), 'ug/m3',
       'WRONG: unweighted mean of every overlapping row (partial months count as full months)' FROM naive
UNION ALL
SELECT tag, person_id, 'n_overlapping_exposure_rows', n_rows, 'rows', 'Includes the partially overlapping first/last month rows' FROM naive
UNION ALL
SELECT tag, person_id, 'pregnancy_days', (e - s + 1), 'days', NULL FROM ep;

-- Row-count expectations for the exposure-ingestion checks
INSERT INTO demo.expected_result(fixture_tag, person_id, metric, value, unit, notes)
SELECT 'GLOBAL', NULL::integer, 'n_persons', count(*), 'persons', NULL FROM omopgis.person
UNION ALL
SELECT 'GLOBAL', NULL, 'n_movers', count(*), 'persons', 'Persons with two location_history rows'
FROM (SELECT entity_id FROM omopgis.location_history GROUP BY entity_id HAVING count(*) = 2) x
UNION ALL
SELECT 'GLOBAL', NULL, 'n_pm25_monthly_rows', count(*), 'rows',
       '72 per non-mover; 73 per mover (the move month is split into two partial rows) unless the move date is the 1st of a month'
FROM working.external_exposure WHERE exposure_concept_id = 2052499839
UNION ALL
SELECT 'GLOBAL', NULL, 'n_ses_rows', count(*), 'rows', 'One row per residence interval (the SES index is static over 2014-2019)'
FROM working.external_exposure WHERE exposure_concept_id = 2052497744
UNION ALL
SELECT fixture_tag, person_id, 'n_pm25_monthly_rows', count(*), 'rows',
       '72 rows for a non-mover; 73 for a mover (unless the move falls on the 1st of a month)'
FROM demo.fixture_person fp
JOIN working.external_exposure ee USING (person_id)
WHERE ee.exposure_concept_id = 2052499839
GROUP BY fixture_tag, person_id
UNION ALL
SELECT fixture_tag, person_id, 'n_rejected_rows', count(*), 'rows', reject_reason
FROM demo.rejected_exposure_row GROUP BY fixture_tag, person_id, reject_reason;

-- Person risk factors: day-weighted PM2.5 and SES (both derived by gaiaDB) across residences, age, sex, county frailty

CREATE TEMP TABLE county_frailty AS
SELECT county_ref_id,
       (SELECT value FROM demo.generator_params WHERE param = 'county_frailty_sd')
         * sqrt(-2 * ln(demo.hash_u(county_ref_id || ':fr1'))) * cos(2 * pi() * demo.hash_u(county_ref_id || ':fr2')) AS u
FROM omopgis.county_reference;

CREATE TEMP TABLE person_pm25 AS
SELECT ee.person_id,
       sum(ee.value_as_number * (ee.exposure_end_date - ee.exposure_start_date + 1))
         / sum(ee.exposure_end_date - ee.exposure_start_date + 1) AS pm25_value
FROM working.external_exposure ee
WHERE ee.exposure_concept_id = 2052499839 AND ee.person_id > 0
GROUP BY ee.person_id;

CREATE TEMP TABLE person_ses_gaia AS
SELECT ee.person_id,
       sum(ee.value_as_number::numeric * (ee.exposure_end_date - ee.exposure_start_date + 1))
         / sum(ee.exposure_end_date - ee.exposure_start_date + 1) AS ses_index
FROM working.external_exposure ee
WHERE ee.exposure_concept_id = 2052497744 AND ee.person_id > 0
GROUP BY ee.person_id;

CREATE TEMP TABLE person_ses AS
SELECT lh.entity_id AS person_id,
       g.ses_index,
       sum(f.u * (lh.end_date - lh.start_date + 1)) / sum(lh.end_date - lh.start_date + 1) AS frailty,
       (array_agg(c.urban_density_category ORDER BY lh.start_date))[1] AS urban_density_category,
       (array_agg(c.county_ref_id ORDER BY lh.start_date))[1] AS county_ref_id
FROM omopgis.location_history lh
JOIN omopgis.location l ON l.location_id = lh.location_id
JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id
JOIN county_frailty f ON f.county_ref_id = c.county_ref_id
JOIN person_ses_gaia g ON g.person_id = lh.entity_id
GROUP BY lh.entity_id, g.ses_index;

CREATE TEMP TABLE person_risk_factors AS
SELECT p.person_id,
       pm.pm25_value,
       s.ses_index,
       s.urban_density_category,
       s.county_ref_id,   -- county of the FIRST residence
       s.frailty,
       2016 - p.year_of_birth AS age_2016,
       (p.gender_concept_id = 8532) AS is_female
FROM omopgis.person p
JOIN person_pm25 pm ON pm.person_id = p.person_id
JOIN person_ses s   ON s.person_id = p.person_id
ORDER BY p.person_id;   -- downstream random() draws scan this table: keep its order fixed

-- Conditions: logistic model from demo.generator_truth; onset date is uniform over 2014-2019

INSERT INTO omopgis.condition_occurrence(person_id, condition_concept_id, condition_start_date,
                                         condition_type_concept_id, condition_source_value, condition_source_concept_id)
SELECT d.person_id, d.condition_concept_id,
       ('2014-01-01'::date + floor(demo.hash_u(d.person_id || ':' || d.outcome_name || ':date') * 2191)::integer),
       32817, d.outcome_name, d.condition_concept_id
FROM (
    SELECT prf.person_id, t.outcome_name, t.condition_concept_id,
           1.0 / (1.0 + exp(-(
                 ln(t.prevalence_ref / (1.0 - t.prevalence_ref))
               + t.beta_pm25_per_ugm3  * (prf.pm25_value - (SELECT value FROM demo.generator_params WHERE param = 'pm25_ref_ugm3'))
               + t.beta_ses_per_sd     * (prf.ses_index   - (SELECT value FROM demo.generator_params WHERE param = 'ses_ref'))
                                       / (SELECT value FROM demo.generator_params WHERE param = 'ses_sd')
               + t.beta_age_per_decade * (prf.age_2016    - (SELECT value FROM demo.generator_params WHERE param = 'age_ref')) / 10.0
               + t.beta_female * (CASE WHEN prf.is_female THEN 1 ELSE 0 END)
               + prf.frailty))) AS p
    FROM person_risk_factors prf
    CROSS JOIN demo.generator_truth t
) d
WHERE demo.hash_u(d.person_id || ':' || d.outcome_name || ':occur') < d.p
ORDER BY d.person_id, d.outcome_name;   -- fixed insertion order => stable condition_occurrence_id

-- SDOH observations, all derived from the county SES index (as joined to the person by gaiaDB)

-- Poverty Rate (concept 2052499459 - Poverty)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052499459, '2016-07-01'::date, 32817,
       GREATEST(1.0, LEAST(45.0, 45.0 - prf.ses_index * 0.4 + (random() - 0.5) * 10.0)),
       8554, 'POVERTY_RATE', 2052499459, 'percent'
FROM person_risk_factors prf;

-- Education Level, years (concept 2052497092 - Education_Level)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052497092, '2016-07-01'::date, 32817,
       GREATEST(8.0, LEAST(20.0, 9.0 + prf.ses_index * 0.11 + (random() - 0.5) * 3.0)),
       9448, 'EDUCATION_YEARS', 2052497092, 'years'
FROM person_risk_factors prf;

-- Housing Cost Burden (concept 2052498464 - Housing_Cost)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052498464, '2016-07-01'::date, 32817,
       GREATEST(10.0, LEAST(65.0, 55.0 - prf.ses_index * 0.35 + (random() - 0.5) * 10.0)),
       8554, 'HOUSING_COST_PCT', 2052498464, 'percent'
FROM person_risk_factors prf;

-- Employment Status (concept 2052499478): 1 = employed, 0 = unemployed; number and label from one draw
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, value_as_string,
                                observation_source_value, observation_source_concept_id)
SELECT d.person_id, 2052499478, '2016-07-01'::date, 32817,
       CASE WHEN d.unemployed THEN 0 ELSE 1 END,
       CASE WHEN d.unemployed THEN 'Unemployed' ELSE 'Employed' END,
       'EMPLOYMENT', 2052499478
FROM (SELECT prf.person_id,
             random() < GREATEST(0.02, LEAST(0.40, 0.35 - prf.ses_index * 0.003)) AS unemployed
      FROM person_risk_factors prf) d;

-- Neighborhood Concentrated Disadvantage (concept 2052498758)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052498758, '2016-07-01'::date, 32817,
       GREATEST(0.0, LEAST(1.0, 1.0 - prf.ses_index / 100.0 + (random() - 0.5) * 0.2)),
       'NEIGHBORHOOD_DISADVANTAGE', 2052498758, 'index'
FROM person_risk_factors prf;

-- Food Insecurity Rate (concept 2052498073)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052498073, '2016-07-01'::date, 32817,
       GREATEST(1.0, LEAST(40.0, 35.0 - prf.ses_index * 0.35 + (random() - 0.5) * 8.0)),
       8554, 'FOOD_INSECURITY_RATE', 2052498073, 'percent'
FROM person_risk_factors prf;

-- Primary Care Physician Access (concept 2052497364) - physicians per 1,000 residents
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052497364, '2016-07-01'::date, 32817,
       GREATEST(0.2, LEAST(2.5, 0.3 + prf.ses_index * 0.020 + (random() - 0.5) * 0.4)),
       'PCP_ACCESS_RATIO', 2052497364, 'per_1000'
FROM person_risk_factors prf;

-- Social Isolation Index (concept 2052497761)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052497761, '2016-07-01'::date, 32817,
       GREATEST(0.0, LEAST(1.0, 0.9 - prf.ses_index / 100.0 + (random() - 0.5) * 0.2)),
       'SOCIAL_ISOLATION_INDEX', 2052497761, 'index'
FROM person_risk_factors prf;

-- Uninsured Rate (concept 2052498200)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052498200, '2016-07-01'::date, 32817,
       GREATEST(1.0, LEAST(30.0, 25.0 - prf.ses_index * 0.22 + (random() - 0.5) * 6.0)),
       8554, 'UNINSURED_RATE', 2052498200, 'percent'
FROM person_risk_factors prf;

-- Broadband Internet Access (concept 2052498483)
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, unit_concept_id,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052498483, '2016-07-01'::date, 32817,
       GREATEST(30.0, LEAST(99.0, 55.0 + prf.ses_index * 0.42 + (random() - 0.5) * 8.0)),
       8554, 'BROADBAND_ACCESS_PCT', 2052498483, 'percent'
FROM person_risk_factors prf;

-- Violent Crime Rate (concept 2052497310) - per 100,000 residents
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number,
                                observation_source_value, observation_source_concept_id, unit_source_value)
SELECT prf.person_id, 2052497310, '2016-07-01'::date, 32817,
       GREATEST(50.0, LEAST(2500.0, 2200.0 - prf.ses_index * 20.0 + (random() - 0.5) * 600.0)),
       'VIOLENT_CRIME_RATE', 2052497310, 'per_100000'
FROM person_risk_factors prf;

-- Air Quality Index Category (concept 2052499437) - derived from PM2.5, mirrors urban density
INSERT INTO omopgis.observation(person_id, observation_concept_id, observation_date,
                                observation_type_concept_id, value_as_number, value_as_string,
                                observation_source_value, observation_source_concept_id)
SELECT prf.person_id, 2052499437, '2016-07-01'::date, 32817,
       ROUND(LEAST(300.0, prf.pm25_value * 4.2)::numeric, 1),
       CASE
           WHEN prf.pm25_value * 4.2 >= 150 THEN 'Unhealthy'
           WHEN prf.pm25_value * 4.2 >= 100 THEN 'Unhealthy for Sensitive Groups'
           WHEN prf.pm25_value * 4.2 >= 50  THEN 'Moderate'
           ELSE 'Good'
       END,
       'AQI_CATEGORY', 2052499437
FROM person_risk_factors prf;

-- RESPIRATORY DRUGS
-- Asthma medications for patients with asthma

-- Albuterol (Inhaler) - 1154343
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1154343,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 90)::integer,
       32817, 3, 1, 90, '2 puffs every 4-6 hours as needed', 40486069,
       'ALBUTEROL', 1154343, 'Inhalation', 'puffs'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009; -- Asthma patients only

-- Fluticasone (Inhaled Corticosteroid) - 1149380
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1149380,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 180)::integer,
       32817, 5, 1, 180, '2 puffs twice daily', 40486069,
       'FLUTICASONE', 1149380, 'Inhalation', 'puffs'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.7; -- 70% of asthma patients

-- Montelukast (Singulair) - 1154161
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1154161,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '10mg once daily at bedtime', 4132161,
       'MONTELUKAST', 1154161, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.5; -- 50% of asthma patients

-- Tiotropium Bromide (Long-Acting Bronchodilator) - 1106776 - COPD patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1106776,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '1 capsule inhaled once daily', 40486069,
       'TIOTROPIUM', 1106776, 'Inhalation', 'mcg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 255573
AND random() < 0.8; -- 80% of COPD patients

-- Guaifenesin (Expectorant) - 1163944 - Chronic Bronchitis patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1163944,
       co.condition_start_date + floor(random() * 14)::integer,
       co.condition_start_date + floor(random() * 14 + 14)::integer,
       32817, 1, 14, 14, '400mg every 4 hours as needed', 4132161,
       'GUAIFENESIN', 1163944, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 255841
AND random() < 0.4; -- 40% of bronchitis patients

-- Cetirizine (Antihistamine) - 1149196 - Allergic Rhinitis patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1149196,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 30, 365, '10mg once daily', 4132161,
       'CETIRIZINE', 1149196, 'Oral', 'mg'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 257007
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

-- CARDIOMETABOLIC DRUGS

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

-- Carvedilol (Beta Blocker) - 1346823 - CHF patients
INSERT INTO omopgis.drug_exposure(person_id, drug_concept_id, drug_exposure_start_date,
                                  drug_exposure_end_date, drug_type_concept_id, refills, quantity,
                                  days_supply, sig, route_concept_id, drug_source_value,
                                  drug_source_concept_id, route_source_value, dose_unit_source_value)
SELECT co.person_id, 1346823,
       co.condition_start_date + floor(random() * 30)::integer,
       co.condition_start_date + floor(random() * 30 + 365)::integer,
       32817, 11, 60, 365, '3.125mg twice daily', 4132161,
       'CARVEDILOL', 1346823, 'Oral', 'mg'
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

-- RESPIRATORY PROCEDURES
-- Pulmonary Function Test (Spirometry) - 4133840

INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4133840,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, 1, 'SPIROMETRY', 4133840
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317009
AND random() < 0.8; -- 80% of asthma patients get spirometry

-- Chest X-ray - 4163872 - COPD and Pneumonia patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4163872,
       co.condition_start_date + floor(random() * 14)::integer,
       32817, 1, 'CHEST_XRAY', 4163872
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (255573, 255848) -- COPD, Pneumonia
AND random() < 0.7;

-- CARDIOMETABOLIC PROCEDURES

-- Electrocardiogram (ECG) - 4163951 - CAD and MI patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4163951,
       co.condition_start_date + floor(random() * 30)::integer,
       32817, 1, 'ECG', 4163951
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317576, 4329847) -- CAD, MI
AND random() < 0.85;

-- Echocardiogram - 4230911 - CHF patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4230911,
       co.condition_start_date + floor(random() * 30)::integer,
       32817, 1, 'ECHOCARDIOGRAM', 4230911
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835
AND random() < 0.75; -- 75% of CHF patients

-- Coronary Angiography - 4142645 - MI patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4142645,
       co.condition_start_date + floor(random() * 5)::integer,
       32817, 1, 'CORONARY_ANGIOGRAPHY', 4142645
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 4329847 -- MI
AND random() < 0.6;

-- Cardiac Stress Test - 4296597 - CAD patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4296597,
       co.condition_start_date + floor(random() * 60)::integer,
       32817, 1, 'CARDIAC_STRESS_TEST', 4296597
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 317576 -- CAD
AND random() < 0.5;

-- Hemodialysis - 4120120 - CKD patients
INSERT INTO omopgis.procedure_occurrence(person_id, procedure_concept_id, procedure_date,
                                        procedure_type_concept_id, quantity, procedure_source_value,
                                        procedure_source_concept_id)
SELECT co.person_id, 4120120,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, 1, 'HEMODIALYSIS', 4120120
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 46271022 -- CKD
AND random() < 0.25; -- 25% of CKD patients (advanced/ESRD subset)

-- RESPIRATORY & CARDIOMETABOLIC MEASUREMENTS

-- Peak Expiratory Flow Rate (PEFR) - 4087260, lower for asthma/COPD
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 4087260,
       co.condition_start_date + floor(random() * 365)::integer,
       32817,
       CASE
           WHEN co.condition_concept_id = 317009
           THEN (200.0 + random() * 200.0)  -- Asthma: 200-400 L/min (reduced)
           ELSE (400.0 + random() * 200.0)  -- Normal: 400-600 L/min
       END,
       8698, 'PEFR', 4087260, 'L/min'
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

-- Eosinophil Count - 3028615, elevated for Asthma/Allergic Rhinitis patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3028615,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (300.0 + random() * 400.0), -- 300-700 cells/uL
       8784, 'EOSINOPHIL_COUNT', 3028615, 'cells/uL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id IN (317009, 257007) -- Asthma, Allergic Rhinitis
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

-- Estimated GFR - 1619025, reduced for CKD patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 1619025,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (10.0 + random() * 50.0), -- 10-60 mL/min/1.73m2
       720870, 'EGFR', 1619025, 'mL/min/1.73m2'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 46271022 -- CKD
AND random() < 0.9;

-- Troponin I - 3019800, elevated for MI patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3019800,
       co.condition_start_date + floor(random() * 3)::integer,
       32817, (0.5 + random() * 9.5), -- 0.5-10.0 ng/mL
       8842, 'TROPONIN', 3019800, 'ng/mL'
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
       8845, 'BNP', 3011960, 'pg/mL'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835 -- CHF
AND random() < 0.8;

-- Left Ventricular Ejection Fraction - 3027172, reduced for CHF patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3027172,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (15.0 + random() * 30.0), -- 15-45 %
       8554, 'EJECTION_FRACTION', 3027172, 'percent'
FROM omopgis.condition_occurrence co
WHERE co.condition_concept_id = 319835 -- CHF
AND random() < 0.75;

-- Waist Circumference - 3016258, elevated for Obesity patients
INSERT INTO omopgis.measurement(person_id, measurement_concept_id, measurement_date,
                                measurement_type_concept_id, value_as_number, unit_concept_id,
                                measurement_source_value, measurement_source_concept_id, unit_source_value)
SELECT co.person_id, 3016258,
       co.condition_start_date + floor(random() * 365)::integer,
       32817, (100.0 + random() * 40.0), -- 100-140 cm
       8582, 'WAIST_CIRCUMFERENCE', 3016258, 'cm'
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

-- MISSING_SDOH_VALUE fixture: remove one SDOH observation for one person
DELETE FROM omopgis.observation o
USING demo.fixture_person fp
WHERE fp.fixture_tag = 'MISSING_SDOH_VALUE'
  AND o.person_id = fp.person_id
  AND o.observation_source_value = 'NEIGHBORHOOD_DISADVANTAGE';

INSERT INTO demo.expected_result(fixture_tag, person_id, metric, value, unit, notes)
SELECT 'MISSING_SDOH_VALUE', fp.person_id, 'n_sdoh_observations', count(o.person_id), 'rows',
       '11 of the 12 SDOH observations present (NEIGHBORHOOD_DISADVANTAGE missing)'
FROM demo.fixture_person fp
LEFT JOIN omopgis.observation o ON o.person_id = fp.person_id
WHERE fp.fixture_tag = 'MISSING_SDOH_VALUE'
GROUP BY fp.person_id;

-- OBSERVATION PERIODS
-- Everyone has observation period from 2014-2019

INSERT INTO omopgis.observation_period(person_id,
                                       observation_period_start_date,
                                       observation_period_end_date,
                                       period_type_concept_id)
SELECT person_id,
       '2014-01-01'::date,
       '2019-12-31'::date,
       32817
FROM omopgis.person
ORDER BY person_id;

-- CDM SOURCE METADATA

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
        'Synthetic dataset with 10,000 adult patients placed in ~3,000 real US counties (2014-2019), with real monthly CDC county-level PM2.5 linked through residence history (including residential moves), simulated county SES and SDOH indicators, and 14 respiratory/cardiometabolic conditions drawn from a documented logistic risk model (true effects in demo.generator_truth). Persons, residences and clinical events are entirely synthetic. Deterministic (setseed). Designed for OHDSI cohort, characterization, estimation and prediction demonstrations and the OHDSI GIS tutorial.',
        'https://github.com/OHDSI/CommonDataModel',
        'Synthetic Data Generator v3.0',
        '2026-10-05'::date,
        '2026-10-05'::date,
        '5.4',
        756265,
        'GIS v1.0');
