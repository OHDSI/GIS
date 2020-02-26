IF OBJECT_ID('@gis_schema.location_to_area', 'U') IS NULL

CREATE TABLE @gis_schema.[location_to_area](
	[location_id] [varchar](255) NULL,
	[area_type_id] [varchar](255) NULL,
	[area_id] [varchar](255) NULL,
	[relationship_id] [varchar](100) NULL
);
