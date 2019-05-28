INSERT INTO @gis_schema.[area_attribute]
           ([area_id]
           ,[attribute_concept_id]
           ,[attribute_source_value]
           ,[value_as_number]
           ,[value_as_concept_id]
           ,[value_source_value]
           ,[unit_concept_id]
           ,[unit_source_value]
           ,[qualifier_concept_id]
           ,[qualifier_source_value]
           ,[data_source_id])
	SELECT area_id
			,gc.concept_id
			,ta.attribute_source_value
			,ta.attribute_value
			,0
			,ta.attribute_value
			,0
			,NULL
			,0
			,NULL
			,ta.data_source_id

	FROM @gis_schema.[tmp_attr] ta
	INNER JOIN @gis_schema.[area] area
	ON ta.geoid = area.area_source_value
	LEFT OUTER JOIN @gis_schema.geo_concept gc
	ON ta.attribute_source_value = gc.concept_code
	AND gc.vocabulary_id = '@source_vocabulary'
	;

DROP TABLE @gis_schema.tmp_attr;
