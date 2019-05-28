IF OBJECT_ID('@gis_schema.geo_concept', 'U') IS NULL


CREATE TABLE @gis_schema.[geo_concept](
	[concept_id] [int] NOT NULL,
	[concept_name] [varchar](255) NOT NULL,
	[domain_id] [varchar](20) NOT NULL,
	[vocabulary_id] [varchar](20) NOT NULL,
	[concept_class_id] [varchar](20) NOT NULL,
	[standard_concept] [varchar](1) NULL,
	[concept_code] [varchar](50) NOT NULL,
	[valid_start_date] [date] NOT NULL,
	[valid_end_date] [date] NOT NULL,
	[invalid_reason] [varchar](55) NULL
);

