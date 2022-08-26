library(rjson)
library(dplyr)
library(sf)
library(DatabaseConnector)
library(rpostgis)
library(plyr)



connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",  # options: oracle, postgressql, redshift, sql server, pdw, netezza, bigquery, sqlite
  server = "", # name of the server
  port = 5433,
  user="postgres", # username to access server
  password = "" #password for that user
  
)


# TODO: Build example execution below 