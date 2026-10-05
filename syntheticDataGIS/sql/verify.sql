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
               WHERE exposure_source_value = 'pm25_mean_pred' GROUP BY person_id) x ON x.person_id = p.person_id
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

-- Informational summary (not assertions)
SELECT 'persons' AS what, count(*)::text AS value FROM omopgis.person
UNION ALL SELECT 'movers', count(*)::text FROM (SELECT entity_id FROM omopgis.location_history GROUP BY 1 HAVING count(*) = 2) x
UNION ALL SELECT 'counties used', count(DISTINCT county_ref_id)::text FROM omopgis.location
UNION ALL SELECT 'gaiaDB pm25 rows', count(*)::text FROM working.external_exposure WHERE exposure_source_value = 'pm25_mean_pred'
UNION ALL SELECT 'conditions', count(*)::text FROM omopgis.condition_occurrence
UNION ALL SELECT 'corr(county PM2.5, county SES)', round(corr(pm25_baseline_mean, ses_index)::numeric, 3)::text FROM omopgis.county_reference;
