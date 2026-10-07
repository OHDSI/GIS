-- VERIFY: invariants the finished build must satisfy. Raises an exception (and
-- so fails the build script) on the first violation.

CREATE INDEX IF NOT EXISTS ix_wee_person ON working.external_exposure (person_id, exposure_start_date);
ANALYZE working.external_exposure;

DO $$
DECLARE
    n bigint;
    npers integer := (SELECT value::integer FROM demo.generator_params WHERE param = 'n_persons');
BEGIN
    -- persons: all adults on 2014-01-01
    SELECT count(*) INTO n FROM omopgis.person;
    IF n <> npers THEN RAISE EXCEPTION 'expected % persons, found %', npers, n; END IF;
    SELECT count(*) INTO n FROM omopgis.person WHERE 2014 - year_of_birth < 18;
    IF n > 0 THEN RAISE EXCEPTION '% persons are younger than 18 in 2014', n; END IF;

    -- location history: contiguous, non-overlapping, covers 2014-2019, integer person domain
    SELECT count(*) INTO n FROM omopgis.location_history WHERE domain_id <> 1147314;
    IF n > 0 THEN RAISE EXCEPTION '% location_history rows have a non-Person domain_id', n; END IF;
    SELECT count(*) INTO n FROM omopgis.location_history a JOIN omopgis.location_history b
        ON a.entity_id = b.entity_id AND a.location_id < b.location_id
       AND (a.start_date <= b.end_date AND b.start_date <= a.end_date OR a.end_date + 1 <> b.start_date AND b.end_date + 1 <> a.start_date);
    IF n > 0 THEN RAISE EXCEPTION '% overlapping or gapped residence intervals', n; END IF;
    SELECT count(*) INTO n FROM (SELECT entity_id FROM omopgis.location_history GROUP BY 1
                                 HAVING min(start_date) <> '2014-01-01' OR max(end_date) <> '2019-12-31') x;
    IF n > 0 THEN RAISE EXCEPTION '% persons whose residences do not span 2014-01-01..2019-12-31', n; END IF;

    -- every stage-1 point lies inside the real county polygon of its county_ref_id
    SELECT count(*) INTO n
    FROM omopgis.location l
    JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id
    JOIN public.us_2023_county_tl t ON t.geoid = c.county_fips
    WHERE NOT ST_Within(ST_Transform(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326), 4269), t.geom);
    IF n > 0 THEN RAISE EXCEPTION '% locations fall outside their county polygon', n; END IF;

    -- gaiaDB exposure: every person, every month, once, inside a residence interval, ug/m3 range
    SELECT count(*) INTO n FROM omopgis.person p
    LEFT JOIN (SELECT person_id, count(*) AS c FROM working.external_exposure
               WHERE exposure_concept_id = 2052499839 GROUP BY person_id) x ON x.person_id = p.person_id
    WHERE COALESCE(x.c, 0) < 72;
    IF n > 0 THEN RAISE EXCEPTION '% persons have fewer than 72 monthly PM2.5 rows', n; END IF;
    SELECT count(*) INTO n FROM working.external_exposure ee JOIN working.external_exposure e2
        ON e2.person_id = ee.person_id AND e2.exposure_source_value = ee.exposure_source_value
       AND e2.external_exposure_id > ee.external_exposure_id
       AND e2.exposure_start_date <= ee.exposure_end_date AND ee.exposure_start_date <= e2.exposure_end_date;
    IF n > 0 THEN RAISE EXCEPTION '% overlapping exposure rows within a person', n; END IF;
    SELECT count(*) INTO n FROM working.external_exposure ee
    WHERE ee.person_id = 0 OR ee.value_as_number IS NULL OR ee.value_as_number <= 0 OR ee.value_as_number > 200;
    IF n > 0 THEN RAISE EXCEPTION '% exposure rows are unassigned, NULL or implausible', n; END IF;

    -- the published exposure table must be empty; fixtures must exist
    SELECT count(*) INTO n FROM omopgis.external_exposure;
    IF n > 0 THEN RAISE EXCEPTION 'omopgis.external_exposure must be empty in the published dataset (has % rows)', n; END IF;
    SELECT count(*) INTO n FROM demo.fixture_person;
    IF n <> 7 THEN RAISE EXCEPTION 'expected 7 fixture persons, found %', n; END IF;
    SELECT count(*) INTO n FROM demo.rejected_exposure_row;
    IF n <> 4 THEN RAISE EXCEPTION 'expected 4 rejected staging rows, found %', n; END IF;

    -- clinical sanity
    SELECT count(*) INTO n FROM omopgis.condition_occurrence;
    IF n < 10000 THEN RAISE EXCEPTION 'suspiciously few conditions: %', n; END IF;

    RAISE NOTICE 'verify: all invariants hold';
END $$;


-- every concept id used by the clinical tables exists in the mini vocabulary, is standard, and sits in the right domain
DO $$
DECLARE r record; n bigint;
BEGIN
    FOR r IN SELECT * FROM (VALUES
        ('condition_occurrence','condition_concept_id','Condition'),
        ('condition_occurrence','condition_source_concept_id','Condition'),
        ('drug_exposure','drug_concept_id','Drug'),
        ('drug_exposure','drug_source_concept_id','Drug'),
        ('drug_exposure','route_concept_id','Route'),
        ('procedure_occurrence','procedure_concept_id','Procedure,Measurement'),
        ('measurement','measurement_concept_id','Measurement'),
        ('measurement','unit_concept_id','Unit'),
        ('observation','observation_concept_id',NULL),
        ('observation','unit_concept_id','Unit'),
        ('person','gender_concept_id','Gender'),
        ('episode','episode_concept_id','Episode'),
        ('episode','episode_object_concept_id','Condition'),
        ('location_history','relationship_type_concept_id',NULL),
        ('location_history','domain_id',NULL),
        ('condition_occurrence','condition_type_concept_id','Type Concept'),
        ('drug_exposure','drug_type_concept_id','Type Concept'),
        ('procedure_occurrence','procedure_type_concept_id','Type Concept'),
        ('measurement','measurement_type_concept_id','Type Concept'),
        ('observation','observation_type_concept_id','Type Concept'),
        ('observation_period','period_type_concept_id','Type Concept')
    ) AS t(tbl, col, dom) LOOP
        EXECUTE format($q$SELECT count(*) FROM (SELECT DISTINCT %I AS id FROM omopgis.%I WHERE %I IS NOT NULL AND %I <> 0) x
                          LEFT JOIN omopgis.concept c ON c.concept_id = x.id
                          WHERE c.concept_id IS NULL OR c.standard_concept IS DISTINCT FROM 'S'
                             OR (%L IS NOT NULL AND c.domain_id <> ALL (string_to_array(%L, ',')))$q$,
                       r.col, r.tbl, r.col, r.col, r.dom, r.dom) INTO n;
        IF n > 0 THEN RAISE EXCEPTION '%.% has % concept ids missing from the vocabulary, non-standard, or in the wrong domain', r.tbl, r.col, n; END IF;
    END LOOP;
    SELECT count(*) INTO n FROM (SELECT DISTINCT exposure_concept_id AS id FROM working.external_exposure
                                 UNION SELECT DISTINCT exposure_relationship_concept_id FROM working.external_exposure
                                 UNION SELECT DISTINCT exposure_type_concept_id FROM working.external_exposure) x
        LEFT JOIN omopgis.concept c ON c.concept_id = x.id WHERE c.concept_id IS NULL;
    IF n > 0 THEN RAISE EXCEPTION '% exposure concept ids are missing from the vocabulary', n; END IF;
    -- exposure_type_concept_id is the data-source type (Air Quality Database), not a geometry type
    SELECT count(*) INTO n FROM working.external_exposure ee
        LEFT JOIN omopgis.concept c ON c.concept_id = ee.exposure_type_concept_id
        WHERE c.concept_class_id IS DISTINCT FROM 'Exposure Type Concept'
           OR ee.exposure_type_concept_id <> CASE ee.exposure_concept_id WHEN 2052499839 THEN 2052499878 WHEN 2052497744 THEN 2052497765 END;
    IF n > 0 THEN RAISE EXCEPTION '% exposure rows lack the expected exposure type concept (Air Quality Database / SDOH Database)', n; END IF;
    -- exposure_source_value is the variable_source_id of the joined variable, and the source concept is the exposure concept
    SELECT count(*) INTO n FROM working.external_exposure ee
        WHERE ee.exposure_source_value IS DISTINCT FROM
              (SELECT variable_source_id::text FROM backbone.attr_index
               WHERE variable_name = CASE ee.exposure_concept_id WHEN 2052499839 THEN 'pm25_mean_pred' WHEN 2052497744 THEN 'ses_index' END)
           OR ee.exposure_source_concept_id IS DISTINCT FROM ee.exposure_concept_id
           OR ee.exposure_relationship_source_value IS DISTINCT FROM 'ST_Within'
           OR ee.exposure_concept_id NOT IN (2052499839, 2052497744);
    IF n > 0 THEN RAISE EXCEPTION '% exposure rows have unexpected source value / source concept / relationship source value', n; END IF;
    -- the SES exposure is the county SES index of each residence, one row per residence interval, through the index
    SELECT count(*) INTO n FROM omopgis.location_history lh
        JOIN omopgis.location l ON l.location_id = lh.location_id
        JOIN omopgis.county_reference c ON c.county_ref_id = l.county_ref_id
        LEFT JOIN working.external_exposure ee ON ee.exposure_concept_id = 2052497744
             AND ee.location_id = lh.location_id AND ee.person_id = lh.entity_id
             AND ee.exposure_start_date = lh.start_date AND ee.exposure_end_date = lh.end_date
        WHERE ee.value_as_number IS NULL OR abs(ee.value_as_number - c.ses_index) > 0.0001;
    IF n > 0 THEN RAISE EXCEPTION '% residence intervals lack a matching ses_index exposure row', n; END IF;
    SELECT count(*) INTO n FROM demo.generator_truth t LEFT JOIN omopgis.concept c ON c.concept_id = t.condition_concept_id
        WHERE c.concept_id IS NULL;
    IF n > 0 THEN RAISE EXCEPTION '% generator_truth concepts are missing', n; END IF;
    RAISE NOTICE 'verify: concept ids are consistent with the mini vocabulary';
END $$;

-- Informational summary (not assertions)
SELECT 'persons' AS what, count(*)::text AS value FROM omopgis.person
UNION ALL SELECT 'movers', count(*)::text FROM (SELECT entity_id FROM omopgis.location_history GROUP BY 1 HAVING count(*) = 2) x
UNION ALL SELECT 'counties used', count(DISTINCT county_ref_id)::text FROM omopgis.location
UNION ALL SELECT 'gaiaDB pm25 rows', count(*)::text FROM working.external_exposure WHERE exposure_concept_id = 2052499839
UNION ALL SELECT 'gaiaDB ses rows', count(*)::text FROM working.external_exposure WHERE exposure_concept_id = 2052497744
UNION ALL SELECT 'conditions', count(*)::text FROM omopgis.condition_occurrence
UNION ALL SELECT 'corr(county PM2.5, county SES)', round(corr(pm25_baseline_mean, ses_index)::numeric, 3)::text FROM omopgis.county_reference;
