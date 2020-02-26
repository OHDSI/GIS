SELECT TOP 1 *
FROM @gis_schema.polygon_file
WHERE layer = '@layer_name';
