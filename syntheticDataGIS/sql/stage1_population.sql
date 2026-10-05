-- Stage 1b: persons, residences and location history (run by build_tutorial_dataset.sh)
-- Exports LOCATION.csv / LOCATION_HISTORY.csv for gaiaDB; creates no exposure or clinical data.

SELECT setseed(0.20261005);

-- Row-order-independent uniform draw in (0,1), so rebuilds from a fresh gaiaDB ingest are identical
CREATE FUNCTION demo.hash_u(k text) RETURNS double precision
LANGUAGE sql IMMUTABLE AS
$$ SELECT ((('x' || substr(md5(k), 1, 8))::bit(32)::bigint) + 0.5) / 4294967296.0 $$;

-- Generator parameters and answer key
CREATE TABLE demo.generator_params
(
    param  varchar(40) PRIMARY KEY,
    value  numeric     NOT NULL,
    notes  text        NULL
);

INSERT INTO demo.generator_params(param, value, notes) VALUES
    ('n_persons',                 10000, 'Number of synthetic persons'),
    ('min_age_2014',                 18, 'Minimum age on 2014-01-01 (adults only)'),
    ('max_age_2014',                 90, 'Maximum age on 2014-01-01'),
    ('mover_fraction',             0.10, 'Share of persons with one residential move between 2015-03-01 and 2018-10-31'),
    ('ses_pm25_correlation',      -0.30, 'Target correlation between county mean PM2.5 and county SES (higher PM2.5, lower SES): makes SES a confounder'),
    ('county_frailty_sd',          0.15, 'SD of the shared county-level random effect on log-odds of every condition (unmeasured county confounding / spatial clustering)'),
    ('pm25_ref_ugm3',               8.0, 'Reference PM2.5 (ug/m3) at which a condition has its reference prevalence'),
    ('ses_ref',                    50.0, 'Reference county SES index'),
    ('ses_sd',                     15.0, 'SD used to scale SES in the risk model (effects are per SD of SES)'),
    ('age_ref',                    54.0, 'Reference age (years, at 2016-01-01) for the risk model');

-- logit P(condition) = logit(prevalence_ref) + beta_pm25 * (PM2.5 - pm25_ref) + beta_ses * (SES - ses_ref) / ses_sd
--                      + beta_age * (age - age_ref) / 10 + beta_female * [female] + county_frailty
-- PM2.5 and SES are day-weighted over a person's residences.
-- The PM2.5 coefficients are deliberately larger than epidemiologic estimates: real county PM2.5 varies little
-- across 10,000 persons (SD ~1.4 ug/m3), so realistic effects would not be recoverable. Not real-world effect sizes.
CREATE TABLE demo.generator_truth
(
    outcome_name          varchar(30) PRIMARY KEY,
    condition_concept_id  integer     NOT NULL,
    category              varchar(20) NOT NULL,
    prevalence_ref        numeric     NOT NULL,
    beta_pm25_per_ugm3    numeric     NOT NULL,  -- log-odds per 1 ug/m3 of period-mean PM2.5
    beta_ses_per_sd       numeric     NOT NULL,  -- log-odds per 1 SD (15 pts) of SES index
    beta_age_per_decade   numeric     NOT NULL,
    beta_female           numeric     NOT NULL,
    is_pm25_null_outcome  boolean     NOT NULL,  -- true = no simulated PM2.5 effect (usable as a negative-control outcome)
    notes                 text        NULL
);

INSERT INTO demo.generator_truth
    (outcome_name, condition_concept_id, category, prevalence_ref, beta_pm25_per_ugm3, beta_ses_per_sd,
     beta_age_per_decade, beta_female, is_pm25_null_outcome, notes) VALUES
    ('ASTHMA',         317009,   'Respiratory',     0.095, 0.080, -0.15,  0.00,  0.25, false, NULL),
    ('COPD',           255573,   'Respiratory',     0.070, 0.150, -0.20,  0.45,  0.00, false, 'Headline outcome for the tutorial'),
    ('BRONCHITIS',     258780,   'Respiratory',     0.055, 0.100, -0.25,  0.20,  0.10, false, NULL),
    ('PNEUMONIA',      255848,   'Respiratory',     0.060, 0.100, -0.30,  0.30, -0.10, false, NULL),
    ('RHINITIS',       4170143,  'Respiratory',     0.130, 0.000, -0.05, -0.10,  0.10, true,  'Simulated null; real-world literature on PM2.5 and rhinitis may differ'),
    ('HYPERTENSION',   320128,   'Cardiometabolic', 0.180, 0.000, -0.20,  0.50, -0.05, true,  'Simulated null; real-world literature may differ'),
    ('CAD',            317576,   'Cardiometabolic', 0.070, 0.060, -0.35,  0.60, -0.45, false, NULL),
    ('CHF',            319835,   'Cardiometabolic', 0.060, 0.070, -0.45,  0.65, -0.20, false, NULL),
    ('MI',             4329847,  'Cardiometabolic', 0.050, 0.080, -0.40,  0.50, -0.50, false, NULL),
    ('STROKE',         381316,   'Cardiometabolic', 0.050, 0.050, -0.40,  0.55, -0.10, false, NULL),
    ('T2DM',           201826,   'Cardiometabolic', 0.120, 0.000, -0.40,  0.30, -0.10, true,  'Suggested negative-control outcome'),
    ('OBESITY',        433736,   'Cardiometabolic', 0.160, 0.000, -0.25, -0.05,  0.10, true,  'Simulated null; real-world literature may differ'),
    ('HYPERLIPIDEMIA', 432867,   'Cardiometabolic', 0.170, 0.000, -0.20,  0.25, -0.05, true,  'Suggested negative-control outcome'),
    ('CKD',            46271022, 'Cardiometabolic', 0.080, 0.000, -0.50,  0.50,  0.05, true,  'Simulated null; real-world literature may differ');

-- Counties: in TIGER 2023, all 72 monthly CDC values for 2014-2019, and a 2019 population estimate.
-- Real: FIPS, name, centroid, area, population. Simulated: ses_index (correlated with county PM2.5).

CREATE TEMP TABLE state_fips(statefp text PRIMARY KEY, usps text) ;
INSERT INTO state_fips VALUES
('01','AL'),('02','AK'),('04','AZ'),('05','AR'),('06','CA'),('08','CO'),('09','CT'),('10','DE'),('11','DC'),
('12','FL'),('13','GA'),('15','HI'),('16','ID'),('17','IL'),('18','IN'),('19','IA'),('20','KS'),('21','KY'),
('22','LA'),('23','ME'),('24','MD'),('25','MA'),('26','MI'),('27','MN'),('28','MS'),('29','MO'),('30','MT'),
('31','NE'),('32','NV'),('33','NH'),('34','NJ'),('35','NM'),('36','NY'),('37','NC'),('38','ND'),('39','OH'),
('40','OK'),('41','OR'),('42','PA'),('44','RI'),('45','SC'),('46','SD'),('47','TN'),('48','TX'),('49','UT'),
('50','VT'),('51','VA'),('53','WA'),('54','WV'),('55','WI'),('56','WY');

INSERT INTO omopgis.county_reference(county_ref_id, county_name, state, county_fips,
                                     urban_density_category, pm25_baseline_mean,
                                     ses_index, centroid_lat, centroid_lon,
                                     land_area_sqmi, population_2019)
WITH pm AS (
    SELECT c.geoid,
           (SELECT count(*) FROM jsonb_object_keys(c.pm25_mean_pred))                    AS n_months,
           (SELECT avg(v.value::numeric) FROM jsonb_each_text(c.pm25_mean_pred) v)       AS pm25_mean_2014_2019
    FROM public.us_2014_2019_monthly_pm25_by_county_cdc c
    WHERE c.pm25_mean_pred IS NOT NULL
),
base AS (
    SELECT t.geoid, t.name, sf.usps, t.intptlat::numeric AS lat, t.intptlon::numeric AS lon,
           t.aland / 2589988.11 AS aland_sqmi, p.pop_2019, pm.pm25_mean_2014_2019
    FROM public.us_2023_county_tl t
    JOIN state_fips sf ON sf.statefp = t.statefp
    JOIN pm ON pm.geoid = t.geoid AND pm.n_months = 72
    JOIN public.ref_county_pop2019 p ON p.county_fips = t.geoid
    WHERE t.aland > 0 AND p.pop_2019 > 0
),
scored AS (
    SELECT b.*,
           (b.pm25_mean_2014_2019 - avg(b.pm25_mean_2014_2019) OVER ())
               / stddev_samp(b.pm25_mean_2014_2019) OVER () AS pm_z,
           sqrt(-2 * ln(demo.hash_u(b.geoid || ':ses1'))) * cos(2 * pi() * demo.hash_u(b.geoid || ':ses2')) AS eps   -- N(0,1), deterministic per county
    FROM base b
)
SELECT row_number() OVER (ORDER BY geoid),
       name,
       usps,
       geoid,
       CASE
           WHEN pop_2019 / aland_sqmi >= 1000 THEN 'Urban Core'
           WHEN pop_2019 / aland_sqmi >=  250 THEN 'Suburban'
           WHEN pop_2019 / aland_sqmi >=   50 THEN 'Small Town'
           ELSE 'Rural'
       END,
       ROUND(pm25_mean_2014_2019, 3),
       -- SES ~ N(50, 15), correlated with county PM2.5 at the configured rho
       ROUND(GREATEST(5, LEAST(95,
           50 + 15 * ((SELECT value FROM demo.generator_params WHERE param = 'ses_pm25_correlation') * pm_z
                      + sqrt(1 - power((SELECT value FROM demo.generator_params WHERE param = 'ses_pm25_correlation'), 2)) * eps)
       ))::numeric, 2),
       lat,
       lon,
       ROUND(aland_sqmi, 3),
       pop_2019
FROM scored;

-- PEOPLE (10,000 adult patients)
-- Age on 2014-01-01 is uniform over [min_age_2014, max_age_2014] (adults only).

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
       (select 2014 - (a.min_age + floor(random() * (a.max_age - a.min_age + 1) * (i / i)))::integer
        FROM (SELECT (SELECT value FROM demo.generator_params WHERE param = 'min_age_2014') AS min_age,
                     (SELECT value FROM demo.generator_params WHERE param = 'max_age_2014') AS max_age) a),
       (select floor(random() * 11.99 * (i / i) + 1)),
       NULL,
       NULL,
       0,
       0,
       row_number() over (), -- Link to location_id (re-pointed to the current address below)
       NULL,
       NULL,
       (select CONCAT('FAKE PERSON: ', substr(md5(i::text), 0, 10))),
       NULL,
       NULL,
       NULL,
       NULL,
       NULL,
       NULL
FROM generate_series(1, (SELECT value::integer FROM demo.generator_params WHERE param = 'n_persons')) s(i);

UPDATE omopgis.PERSON
SET gender_source_value = 'M'
WHERE gender_concept_id = 8507;

UPDATE omopgis.PERSON
SET gender_source_value = 'F'
WHERE gender_concept_id = 8532;

-- Fixture persons: the lowest person_ids that fit, chosen before residences so they never move at random
CREATE TABLE demo.fixture_person
(
    fixture_tag  varchar(40) PRIMARY KEY,
    person_id    integer     NOT NULL,
    description  text        NOT NULL
);

INSERT INTO demo.fixture_person(fixture_tag, person_id, description)
WITH fem AS (
    SELECT person_id, row_number() OVER (ORDER BY person_id) AS rn
    FROM omopgis.person
    WHERE gender_concept_id = 8532 AND year_of_birth BETWEEN 1980 AND 1994
),
preg AS (
    SELECT person_id, rn FROM fem WHERE rn <= 2
),
others AS (
    SELECT person_id, row_number() OVER (ORDER BY person_id) AS rn
    FROM omopgis.person
    WHERE person_id NOT IN (SELECT person_id FROM preg)
)
SELECT 'PREGNANCY_STATIC', person_id,
       'Pregnancy episode 2016-03-18 to 2016-12-09 at a single residence; first and last months overlap the episode only partially'
FROM preg WHERE rn = 1
UNION ALL
SELECT 'PREGNANCY_MOVER', person_id,
       'Pregnancy episode 2016-05-20 to 2017-02-10; moves counties on 2016-08-15, so the episode spans two residences and two sets of monthly exposure rows'
FROM preg WHERE rn = 2
UNION ALL
SELECT t.tag, o.person_id, t.descr
FROM others o
JOIN (VALUES
    (1, 'DUPLICATE_SOURCE_ROW',       'Staging contains an exact duplicate of the 2017-03 PM2.5 row (demo.rejected_exposure_row); the pipeline output must hold that month once'),
    (2, 'UNIT_MISMATCH',              'Staging contains the 2017-04 PM2.5 row in mg/m3 instead of ug/m3 (demo.rejected_exposure_row); must be rejected or converted'),
    (3, 'NON_OVERLAPPING_INTERVAL',   'Staging contains a January 2020 PM2.5 row, outside the residence and observation interval (demo.rejected_exposure_row); must be rejected'),
    (4, 'MISSING_EXPOSURE_VALUE',     'Staging contains the 2017-05 PM2.5 row with a NULL value (demo.rejected_exposure_row); must be rejected, not loaded as zero'),
    (5, 'MISSING_SDOH_VALUE',         'The NEIGHBORHOOD_DISADVANTAGE observation is missing for this person')
) AS t(rn, tag, descr) ON t.rn = o.rn;

-- Locations: counties drawn with probability proportional to sqrt(2019 population); ~10% of persons move once.
-- (Per-person draws go through a materialized table: a random() subquery would be evaluated once.)
CREATE TEMP TABLE county_cum AS
SELECT county_ref_id,
       sum(w) OVER (ORDER BY county_ref_id) - w AS lo,
       sum(w) OVER (ORDER BY county_ref_id)     AS hi
FROM (SELECT county_ref_id, sqrt(population_2019) AS w FROM omopgis.county_reference) x;

CREATE TEMP TABLE person_draw AS
SELECT person_id,
       random() * (SELECT max(hi) FROM county_cum) AS r_home,
       random() * (SELECT max(hi) FROM county_cum) AS r_dest,
       random()                                    AS r_move,
       random()                                    AS r_date
FROM omopgis.person;

CREATE TEMP TABLE person_move AS
WITH home AS (
    SELECT d.person_id, c.county_ref_id AS county1
    FROM person_draw d JOIN county_cum c ON d.r_home >= c.lo AND d.r_home < c.hi
),
dest AS (
    SELECT d.person_id, c.county_ref_id AS county2_raw
    FROM person_draw d JOIN county_cum c ON d.r_dest >= c.lo AND d.r_dest < c.hi
)
SELECT h.person_id,
       h.county1,
       -- movers go to a different county than the one they left
       CASE WHEN de.county2_raw = h.county1
            THEN (de.county2_raw % (SELECT count(*) FROM omopgis.county_reference)) + 1
            ELSE de.county2_raw END AS county2,
       -- random movers exclude every fixture person; the PREGNANCY_MOVER fixture is forced to move
       (pd.r_move < (SELECT value FROM demo.generator_params WHERE param = 'mover_fraction')
            AND h.person_id NOT IN (SELECT person_id FROM demo.fixture_person))
         OR h.person_id IN (SELECT person_id FROM demo.fixture_person WHERE fixture_tag = 'PREGNANCY_MOVER') AS is_mover,
       CASE WHEN h.person_id IN (SELECT person_id FROM demo.fixture_person WHERE fixture_tag = 'PREGNANCY_MOVER')
            THEN '2016-08-15'::date
            ELSE '2015-03-01'::date + floor(pd.r_date * 1340)::integer   -- 2015-03-01 .. 2018-10-31
       END AS move_date
FROM home h
JOIN dest de ON de.person_id = h.person_id
JOIN person_draw pd ON pd.person_id = h.person_id;

-- location_id = person_id for the first residence, 10000 + person_id for the second.
-- Each point is drawn inside the real county polygon, so st_within recovers the county.
CREATE TEMP TABLE residence AS
SELECT r.location_id, r.county_ref_id,
       ST_Transform(ST_GeometryN(ST_GeneratePoints(t.geom, 1, r.location_id), 1), 4326) AS pt
FROM (
    SELECT person_id AS location_id, county1 AS county_ref_id FROM person_move
    UNION ALL
    SELECT 10000 + person_id, county2 FROM person_move WHERE is_mover
) r
JOIN omopgis.county_reference c ON c.county_ref_id = r.county_ref_id
JOIN public.us_2023_county_tl t ON t.geoid = c.county_fips;

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
SELECT r.location_id,
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
       CONCAT('TRACT-', LPAD(r.location_id::text, 6, '0')),
       NULL,
       NULL,
       ST_Y(r.pt),
       ST_X(r.pt),
       c.county_ref_id
FROM residence r
JOIN omopgis.county_reference c ON c.county_ref_id = r.county_ref_id
ORDER BY r.location_id;

-- Location history: relationship 32848 as in the gaiaDB example file (verify against the vocabulary);
-- domain_id 1147314 = Person, required for gaiaDB to assign person_id.
INSERT INTO omopgis.location_history(location_id,
                                     relationship_type_concept_id,
                                     domain_id,
                                     entity_id,
                                     start_date,
                                     end_date)
SELECT m.person_id,
       32848,   -- residence relationship (as used in the gaiaDB example LOCATION_HISTORY.csv)
       1147314, -- domain concept: Person
       m.person_id,
       '2014-01-01'::date,
       CASE WHEN m.is_mover THEN m.move_date - 1 ELSE '2019-12-31'::date END
FROM person_move m
UNION ALL
SELECT 10000 + m.person_id,
       32848,
       1147314,
       m.person_id,
       m.move_date,
       '2019-12-31'::date
FROM person_move m
WHERE m.is_mover;

-- person.location_id is the CURRENT address (the last residence)
UPDATE omopgis.person p
SET location_id = 10000 + p.person_id
FROM person_move m
WHERE m.person_id = p.person_id AND m.is_mover;

-- EXPORT for gaiaDB (server-side files; the build script loads them with
-- working.load_location_data)
COPY (SELECT location_id, address_1, address_2, city, state, zip, county, location_source_value,
             country_concept_id, country_source_value, latitude, longitude
      FROM omopgis.location ORDER BY location_id)
  TO '/tmp/LOCATION.csv' WITH (FORMAT csv, HEADER true);

COPY (SELECT location_id, relationship_type_concept_id, domain_id, entity_id, start_date, end_date
      FROM omopgis.location_history ORDER BY entity_id, start_date)
  TO '/tmp/LOCATION_HISTORY.csv' WITH (FORMAT csv, HEADER true);
