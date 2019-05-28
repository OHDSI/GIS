IF OBJECT_ID('@gis_schema.location_attribute', 'U') IS NULL

CREATE TABLE @gis_schema.[location_attribute](
	[location_attribute_id] [int] IDENTITY(1,1) NOT NULL,
	[location_id] [int] NOT NULL,
	[attribute_concept_id] [int] NULL,
	[attribute_source_value] [varchar](255) NULL,
	[value_as_number] [int] NULL,
	[value_as_concept_id] [int] NULL,
	[value_source_value] [varchar](255) NULL,
	[unit_concept_id] [int] NULL,
	[unit_source_value] [varchar](255) NULL,
	[qualifier_concept_id] [int] NULL,
	[qualifier_source_value] [varchar](255) NULL,
	[data_source_id] [int] NULL
);
