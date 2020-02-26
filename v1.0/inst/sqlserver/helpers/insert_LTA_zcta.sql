DELETE FROM @gis_schema.LOCATION_TO_AREA
WHERE relationship_id = 'zcta match';

INSERT INTO @gis_schema.LOCATION_TO_AREA
SELECT DISTINCT location_id, 45, area_id, 'zcta match'
FROM @gis_schema.tmp_l2a l2a
INNER JOIN @gis_schema.AREA ar
ON ar.area_type_id = 45
AND l2a.zip = ar.area_source_value
;

DROP TABLE @gis_schema.tmp_l2a;
