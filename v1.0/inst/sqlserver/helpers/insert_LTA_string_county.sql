DELETE FROM @gis_schema.LOCATION_TO_AREA
WHERE relationship_id = 'string match';

INSERT INTO @gis_schema.LOCATION_TO_AREA
SELECT DISTINCT location_id, 23, area_id, 'string match'
FROM @gis_schema.tmp_l2a l2a
INNER JOIN @gis_schema.GEO_CONCEPT gc
ON l2a.concept_id = gc.concept_id
INNER JOIN @gis_schema.AREA ar
ON gc.concept_id = ar.area_concept_id
;

DROP TABLE @gis_schema.tmp_l2a;
