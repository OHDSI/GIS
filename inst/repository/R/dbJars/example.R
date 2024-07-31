# install.packages("devtools")
# install.packages("roxygen2")
library(devtools)
library(roxygen2)
library(DatabaseConnector)
setwd("d:/Sync/gitRepos/projects/ohdsi-gis/")
load_all(".")
# devtools::install_github("OHDSI/GIS")
library(gaiaCore)

# must download driver first, see: https://ohdsi.github.io/DatabaseConnectorJars/
Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = "d:/Sync/gitRepos/GIS/dbJars")

# set database connection
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = "localhost/gaiaDB",
  port = 5433,
  user="postgres",
  password = "mysecretpassword") 

# initialize DB connection
gaiaCore::initializeDatabase(connectionDetails) 

# create index tables
gaiaCore::createIndices(connectionDetails) 

conn <- DatabaseConnector::connect(connectionDetails)
on.exit(DatabaseConnector::disconnect(conn))
backboneExists <- DatabaseConnector::querySql(conn, sql = "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'backbone';")
backboneExists

gaiaCore::loadVariable(connectionDetails,33)

dataSourceTable <- gaiaCore::getDataSourceTable(connectionDetails = connectionDetails)
print(names(dataSourceTable))
uuids <- dataSourceTable$DATA_SOURCE_UUID
print(uuids)

conn <-  DatabaseConnector::connect(connectionDetails)
on.exit(DatabaseConnector::disconnect(conn))
attrIndex <- DatabaseConnector::dbReadTable(conn, "backbone.attr_index", check.names = FALSE)
print(names(attrIndex))
names(attrIndex) <- tolower(names(attrIndex))
print(names(attrIndex))
