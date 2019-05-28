SELECT *
FROM @gis_schema.polygon_file
WHERE polygon_file_id IN (SELECT distinct polygon_file_id FROM @gis_schema.area);
