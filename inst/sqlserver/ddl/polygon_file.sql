IF OBJECT_ID('@gis_schema.polygon_file', 'U') IS NULL

CREATE TABLE @gis_schema.[polygon_file](
	[polygon_file_id] [int] IDENTITY(1,1) NOT NULL,
	[area_type_id] [int] NULL,
	[alt_path] [varchar](100) NULL,
	[layer] [varchar](100) NULL,
	[file_id_col] [varchar](50) NULL,
	[source_file_name] [varchar](100) NULL,
	[file_format] [varchar] (100) NULL,
	[data_source_id] [varchar] (40) NOT NULL
);
