library(rjson)
library(dplyr)
library(sf)
library(DatabaseConnector)
library(rpostgis)
library(plyr)
library(tibble)



connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",  # options: oracle, postgressql, redshift, sql server, pdw, netezza, bigquery, sqlite
  server = "", # name of the server
  port = 5433,
  user="postgres", # username to access server
  password = "") #password for that user

# Run the backbone_ddl.sql file

conn <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::executeSql(conn, sql = readr::read_file('inst/backbone_ddl.sql'))

# Import data_source and feature_index contents from CSV
data_source_df <- read.csv('inst/data_source.csv')
feature_index_df <- read.csv('inst/feature_index.csv')
DatabaseConnector::dbWriteTable(conn, "backbone.data_source", data_source_df, row.names = FALSE, append = TRUE)
DatabaseConnector::dbWriteTable(conn, "backbone.feature_index", feature_index_df, row.names = FALSE, append = TRUE)


# Populate the geom_index and attr_index
create_indices(get_uuids())

imported_sf <- import_sf(connectionDetails, feature_index_id = 157)
disconnect(conn)
