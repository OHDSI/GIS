IF OBJECT_ID('@gis_schema.area', 'U') IS NULL

CREATE TABLE @gis_schema.[area](
	[area_id] [int] IDENTITY(1,1) NOT NULL,
	[area_concept_id] [int] NULL,
	[area_name] [varchar](255) NULL,
	[area_type_id] [int] NULL,
	[area_source_concept_id] [int] NULL,
	[area_source_value] [varchar](200) NULL,
	[polygon_file_id] [int] NULL,
	[polygon_id] [varchar](200) NULL,
	[data_source_id] [varchar](40) NULL
);
