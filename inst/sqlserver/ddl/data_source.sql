IF OBJECT_ID('@gis_schema.data_source', 'U') IS NULL

CREATE TABLE @gis_schema.[data_source](
	[data_source_id] [varchar](40) NOT NULL,
	[data_source_name] [varchar](255) NULL,
	[data_source_description] [varchar](255) NULL,
	[data_source_type_id] [int] NULL,
	[data_source_type_name] [varchar](255) NULL,
	[document_url] [varchar](255) NULL,
	[source_version] [float] NULL,
	[collection_start_date] [varchar](255) NULL,
	[collection_end_date] [varchar](255) NULL,
	[timeframe_concept_id] [int] NULL,
	[timeframe_name] [varchar](255) NULL,
	[timeframe_value] [int] NULL,
	[last_updated_date] [varchar](255) NULL
);
