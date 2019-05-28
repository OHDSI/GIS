DELETE FROM @gis_schema.LOCATION_TO_AREA
WHERE relationship_id = 'point-in-polygon';

INSERT INTO @gis_schema.LOCATION_TO_AREA
SELECT DISTINCT location_id, area_type_id, area_id, 'point-in-polygon'
FROM @gis_schema.tmp_l2a l2a
INNER JOIN @gis_schema.AREA ar
ON l2a.polygon_file_id = ar.polygon_file_id
AND l2a.polygon_id = ar.polygon_id
;

DROP TABLE @gis_schema.tmp_l2a;
