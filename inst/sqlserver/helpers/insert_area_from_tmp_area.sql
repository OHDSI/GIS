INSERT INTO @gis_schema.[area]
           ([area_concept_id]
           ,[area_name]
           ,[area_type_id]
           ,[area_source_concept_id]
           ,[area_source_value]
           ,[polygon_file_id]
           ,[polygon_id]
           ,[data_source_id])
	SELECT DISTINCT
			gc.concept_id
			,ta.area_name
			,ta.area_type_id
			,gc.concept_id
			,ta.area_source_value
			,ta.polygon_file_id
			,ta.polygon_id
			,ta.data_source_id


	FROM @gis_schema.[tmp_area] ta
	LEFT OUTER JOIN @gis_schema.[geo_concept] gc
	ON ta.area_source_value = gc.concept_code
	AND gc.vocabulary_id = '@source_vocabulary'
	;

DROP TABLE @gis_schema.tmp_area;
