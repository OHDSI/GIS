CREATE TABLE geo_index (
  geo_index_id int PRIMARY KEY,
  data_type_id int,
  data_type_name nvarchar(255),
  geo_type_concept_id int,
  geo_type_source_value nvarchar(255),
  schema nvarchar(255),
  table_name nvarchar(255),
  desc nvarchar(255),
  data_source_id int
)
GO

CREATE TABLE attribute_index (
  attribute_index_id int PRIMARY KEY,
  attribute_type_concept_id int,
  attribute_type_source_value nvarchar(255),
  attribute_of_geo_id int,
  schema nvarchar(255),
  table_name nvarchar(255),
  desc nvarchar(255),
  data_source_id int
)
GO

CREATE TABLE example_geo_table (
  geo_record_id int PRIMARY KEY,
  name nvarchar(255),
  area_concept_id int,
  area_source_concept_id int,
  area_source_value nvarchar(255),
  geom_wgs84 nvarchar(255),
  geom_local nvarchar(255)
)
GO

CREATE TABLE example_attr_table (
  attribute_record_id int PRIMARY KEY,
  geo_record_id int,
  attribute_concept_id int,
  attribute_start_date datetime,
  attribute_end_date datetime,
  value_as_number float,
  value_as_string nvarchar(255),
  value_as_concept_id int,
  unit_concept_id int,
  unit_source_value nvarchar(255),
  operator_concept_id int,
  operator_source_value nvarchar(255),
  qualifier_concept_id int,
  qualifier_source_value nvarchar(255),
  attribute_source_concept_id int,
  attribute_source_value nvarchar,
  value_source_value nvarchar(255)
)
GO

ALTER TABLE attribute_index ADD FOREIGN KEY (attribute_of_geo_id) REFERENCES geo_index (geo_index_id)
GO

ALTER TABLE example_attr_table ADD FOREIGN KEY (geo_record_id) REFERENCES example_geo_table (geo_record_id)
GO
