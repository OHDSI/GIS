IF OBJECT_ID('@gis_schema.location', 'U') IS NULL

CREATE TABLE @gis_schema.[location](
	[location_id] [int] IDENTITY(1,1) NOT NULL,
	[address_1] [varchar](255) NULL,
	[address_2] [varchar](255) NULL,
	[city] [varchar](50) NULL,
	[state] [varchar](50) NULL,
	[zip] [varchar](9) NULL,
	[county] [varchar](50) NULL,
	[latitude] [float] NULL,
	[longitude] [float] NULL,
	[epsg] [varchar](50) NULL,
	[location_type_concept_id] [int] NULL,
	[location_source_value] [varchar](100) NULL,
	[data_source_id] [int] NULL,

);
