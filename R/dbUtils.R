# General -----------------------------------------------------------------

#' Get the Variable Source Summary table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) A table of variable source records and a boolean column for if they are loaded.
#'
#' @examples
#' \dontrun{
#' variableSourceSummaryTable <- getVariableSourceSummaryTable(connectionDetails)
#' }
#'
#' @export
#'

getVariableSourceSummaryTable <- function(connectionDetails) {
  attrIndex <- getAttrIndexTable(connectionDetails = connectionDetails)
  variableSource <- getVariableSourceTable(connectionDetails = connectionDetails)
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  loadedAttrXs <- DatabaseConnector::querySql(
    conn,
    sql = "with existing as(
            select concat(table_schema, table_name) existing_tbl
            from information_schema.tables
            where table_type='BASE TABLE'
          )
          select concat(database_schema, '.attr_', table_name) as full_table_name
          from backbone.attr_index
          where concat(database_schema, 'attr_', table_name) in (
            select existing_tbl from existing
          )")
  loadedVariableSourceRecordIds <- DatabaseConnector::querySql(
    conn,
    sql = paste0("SELECT variable_source_record_id FROM ",
                 (paste(loadedAttrXs$FULL_TABLE_NAME,
                        collapse=" UNION SELECT variable_source_record_id FROM "))))
  getVariableSourceSummaryQuery <- paste0(
    "select vs.variable_source_id, ds.data_source_uuid as data_source_id, ",
    "vs.variable_name, vs.variable_desc, ds.org_id, ds.org_set_id, ds.documentation_url, ",
    "ds.dataset_name, ds.dataset_version, ds.boundary_type, vs.geom_dependency_uuid, ",
    "ds2.dataset_name as geom_dependency_name, ds2.geom_type ",
    "from backbone.variable_source vs ",
    "join backbone.data_source ds ",
    "on vs.data_source_uuid=ds.data_source_uuid ",
    "join backbone.data_source ds2 ",
    "on vs.geom_dependency_uuid = ds2.data_source_uuid")
  summaryTable <- DatabaseConnector::querySql(conn, getVariableSourceSummaryQuery)
  ids <- loadedVariableSourceRecordIds$VARIABLE_SOURCE_RECORD_ID
  summaryTable <- dplyr::mutate(summaryTable,
                                isLoaded = ifelse(
                                  VARIABLE_SOURCE_ID %in% ids,
                                  TRUE, FALSE))
}


#' Get the name of a variable_source's geom dependency
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param variableSourceId (integer) Identifier of a record in the variable_source table
#'
#' @return (character) The schema and table name for the source geom dependency 
#'
#' @examples
#' \dontrun{
#' geomName <- getGeomNameFromVariableSourceId(connectionDetails, 101)
#' }
#'
#' @export
#'

getGeomNameFromVariableSourceId <- function(connectionDetails, variableSourceId) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbGetQuery(conn, paste0(
    "select concat(database_schema, '.geom_', table_name)
    from backbone.geom_index gi
    inner join backbone.variable_source vs
    on vs.geom_dependency_uuid = gi.data_source_id 
    and vs.variable_source_id = ", variableSourceId)
  )[[1]]  
}


#' Get the name of a variable_source's attr dependency
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (character) The schema and table name for the source attr dependency 
#'
#' @examples
#' \dontrun{
#' attrName <- getAttrNameFromVariableSourceId(connectionDetails, 101)
#' }
#'
#' @export
#'

getAttrNameFromVariableSourceId <- function(connectionDetails, variableSourceId) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbGetQuery(conn, paste0(
    "select concat(database_schema, '.attr_', table_name)
    from backbone.attr_index ai
    where data_source_id in (
    	select data_source_uuid
    	from backbone.variable_source vs
    	where variable_source_id = ", variableSourceId,"
    ) LIMIT 1"
  )
  )[[1]]  
}


#' Initialize gaiaDB
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param overwrite (boolean) Potential loss of data, proceed with caution! Drop the backbone schema and reinitialize? You will lose any custom data or variable sources that you have added if you overwrite the backbone schema.
#' 
#' @return (database schema) The gaiaDB backbone schema is added to the database in connectionDetails
#'
#' @examples
#' \dontrun{
#'  connectionDetails <- DatabaseConnector::createConnectionDetails(
#'    dbms = "postgresql",
#'    server = "", # name of the server
#'    port = 5432,
#'    user="postgres", # username to access server
#'    password = "mysecretpassword")
#'
#'  initializeDatabase(connectionDetails)
#' }
#'
#' @export
#'

initializeDatabase <- function(connectionDetails, overwrite = FALSE, testing = FALSE) {
  conn <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  backboneExists <- DatabaseConnector::querySql(conn, sql = "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'backbone';")
  if (nrow(backboneExists) > 0) {
    if (isTRUE(overwrite)) {
      message("WARNING: Preparing to drop the backbone schema.\nYou will lose any custom data sources and/or variable sources\nthat you have added if you overwrite the backbone schema.\n\nTo proceed, enter 2. Any other option will abort.")
      if (menu(c('No, abort.','Yes, I am certain I want to drop schema and potentially lose data', 'Do not drop schema, abort')) == 2) {
        message('Dropping backbone schema:')
        DatabaseConnector::executeSql(conn, sql = "DROP SCHEMA backbone CASCADE")
      } else {
        message('gaiaDB reinitialize aborted.')
        return()
      }
    } else {
      message("Backbone schema already exists.\nIf you wish to overwrite schema, set overwrite to TRUE\nWarning: you will lose any custom data or variable sources\nthat you have added if you overwrite the backbone schema.")
      return()
    }
  }
  DatabaseConnector::executeSql(conn, sql = "CREATE SCHEMA IF NOT EXISTS backbone AUTHORIZATION postgres;")
  # TODO the sequences file is not autogenerated. Add it to the create/writeDdl script?
  DatabaseConnector::executeSql(conn, sql = readr::read_file(system.file("ddl", "001", "gaiadb_001_sequences.sql", package="gaiaCore")))
  DatabaseConnector::executeSql(conn, sql = readr::read_file(system.file("ddl", "001", "gaiadb_001_ddl.sql", package="gaiaCore")))
  # DatabaseConnector::executeSql(conn, sql = readr::read_file(system.file("sql", "backbone_ddl.sql", package="gaiaCore")))
  message("backbone schema created.")
  if (!testing) {
    dataSource <- readr::read_csv(system.file(file.path("csv", paste0("data_source.csv")), package = 'gaiaCore'))
    variableSource <- readr::read_csv(system.file(file.path("csv", paste0("variable_source.csv")), package = 'gaiaCore'))
  } else {
    dataSource <- readr::read_csv(system.file(file.path("csv", paste0("test_data_source.csv")), package = 'gaiaCore'))
    variableSource <- readr::read_csv(system.file(file.path("csv", paste0("test_variable_source.csv")), package = 'gaiaCore'))
  }
  DatabaseConnector::dbWriteTable(conn, "backbone.data_source", dataSource, row.names = FALSE, append = TRUE)
  DatabaseConnector::dbWriteTable(conn, "backbone.variable_source", variableSource, row.names = FALSE, append = TRUE)
  message("Source metadata added to database.")
  createIndices(connectionDetails)
}


#' Check if a table exists in a database
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param databaseSchema (character) schema that contains the table to be checked
#' @param tableName (character) name of the table to be checked
#'
#' @return (boolean) A logical value indicating whether the table exists
#'
#' @export
#'

checkTableExists <- function(connectionDetails, databaseSchema, tableName) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  tableExists <- DatabaseConnector::existsTable(conn, databaseSchema, tableName)
}


#' Check if a variable exists in an attr_X table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param databaseSchema (character) schema that contains the table containing the variable to be checked
#' @param tableName (character) name of the table containing the variable to be checked
#' @param variableName (character) name of the variable to be checked
#'
#' @return (boolean) A logical value indicating whether the variable exists
#'
#' @export
#'

checkVariableExists <- function(connectionDetails, databaseSchema, tableName, variableName) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))

  if (!checkTableExists(connectionDetails = connectionDetails,
                        databaseSchema = databaseSchema,
                        tableName = paste0("attr_", tableName))) {
    return(FALSE)
  }
  attrTableString <- paste0(databaseSchema, ".\"attr_", tableName, "\"")
  variableExistsQuery <- paste0("select count(*) from ", attrTableString,
                                " where attr_source_value = '", variableName,"'")
  variableExistsResult <- DatabaseConnector::querySql(conn, variableExistsQuery)
  variableExists <- variableExistsResult > 0
  variableExists[1]
}

# Source Admin ------------------------------------------------------------

#' Append a well-formatted data_source record to the backbone.data_source table in PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param dataSource (data.frame) A well-formatted data source record. Typically created using gaiaSourceCreator RShiny.
#'
#' @return A new record in the backbone.data_source table in PostGIS
#'

addDataSource <- function(connectionDetails, dataSource){
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::insertTable(conn,
                                 databaseSchema = "backbone",
                                 tableName = "data_source",
                                 data = dataSource,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE
  )

}


# Get Backbone Tables -----------------------------------------------------

#' Get the entire backbone.data_source table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) The entire backbone.data_source table
#'
#' @export
#'

getDataSourceTable <- function(connectionDetails) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  dataSource <- DatabaseConnector::dbReadTable(conn, "backbone.data_source")
  names(dataSource) <- tolower(names(dataSource))
  dataSource
}


#' Get the backbone.variable_source table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) The entire backbone.variable_source table
#'
#' @export
#'

getVariableSourceTable <- function(connectionDetails) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  variableSource <- DatabaseConnector::dbReadTable(conn, "backbone.variable_source")
  names(variableSource) <- tolower(names(variableSource))
  variableSource
}


#' Get the backbone.geom_index table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) The entire backbone.geom_index table
#'
#' @export
#'

getGeomIndexTable <- function(connectionDetails) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  geomIndex <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
  names(geomIndex) <- tolower(names(geomIndex))
  geomIndex
}


#' Get the backbone.attr_index table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) The entire backbone.attr_index table
#'
#' @export
#'

getAttrIndexTable <- function(connectionDetails) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  attrIndex <- DatabaseConnector::dbReadTable(conn, "backbone.attr_index")
  names(attrIndex) <- tolower(names(attrIndex))
  attrIndex
}


# Get Backbone Records ----------------------------------------------------

#' Get a single record from the backbone.data_source table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param dataSourceUuid (UUID) The UUID for the data source that is registered in the backbone.data_source table
#'
#' @return (data.frame) A full record (entire row) from the backbone.data_source table
#'

getDataSourceRecord <- function(connectionDetails, dataSourceUuid){
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.data_source WHERE data_source_uuid = ", dataSourceUuid))
}


#' Get a single record from the backbone.variable_source table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param variableSourceId (integer) The identifier for the data source that is registered in the backbone.variable_source table
#'
#' @return (data.frame) A full record (entire row) from the backbone.variable_source table
#'
#' @export
#'

getVariableSourceRecord <- function(connectionDetails, variableSourceId) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))
}


#' Get a record from the backbone.geom_index table from it's corresponding UUID in backbone.data_source table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param dataSourceUuid (UUID) The UUID for the data source that is registered in the backbone.data_source table
#'
#' @return (data.frame) A full record (entire row) from the backbone.geom_index table
#'

getGeomIndexRecord <- function(connectionDetails, dataSourceUuid){
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE data_source_id = ", dataSourceUuid))
}


#' Get a single record from the backbone.attr_index table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param dataSourceUuid (UUID) The UUID for the data source that is registered in the backbone.attr_index table
#'
#' @return (data.frame) A full record (entire row) from the backbone.attr_index table
#'
#' @export
#'

getAttrIndexRecord <- function(connectionDetails, variableSourceId) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE variable_source_id = ", variableSourceId))
}


# Create Indices ----------------------------------------------------------


#' Import the attr_index table to PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param attrIndexTable (data.frame) The entire backbone.attr_index table
#'
#' @return A populated backbone.attr_index table in PostGIS
#'

importAttrIndexTable <- function(connectionDetails, attrIndexTable) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::insertTable(conn,
                                 databaseSchema = "backbone",
                                 tableName = "attr_index",
                                 data = attrIndexTable,
                                 dropTableIfExists = TRUE,
                                 createTable = FALSE)
}


#' Import the geom_index table to PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param geomIndexTable (data.frame) The entire backbone.geom_index table
#'
#' @return A populated backbone.geom_index table in PostGIS
#'

importGeomIndexTable <- function(connectionDetails, geomIndexTable) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::insertTable(conn,
                                 databaseSchema = "backbone",
                                 tableName = "geom_index",
                                 data = geomIndexTable,
                                 dropTableIfExists = TRUE,
                                 createTable = FALSE)
}

# Load Geometry -----------------------------------------------------------

#' Create an empty instance of the geom_template in a given schema in PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param schema (character) The name of the schema in PostGIS where the empty geom_X should be created
#' @param name (character) The suffix for the table name to be created; will be appended to "geom_"
#'
#' @return An empty table (geom_X) in PostGIS
#'
#' @examples
#' \dontrun{
#'
#' variableSourceId <- 157
#'
#' variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))
#'
#' dataSourceRecord <- getDataSourceRecord(conn, variableTable$data_source_uuid)
#'
#' geomIndex <- getGeomIndexByDataSourceUuid(conn, dataSourceRecord$geom_dependency_uuid)
#'
#' createGeomInstanceTable(conn = conn, schema =  geomIndex$database_schema, name = geomIndex$table_name)
#' }
#'

createGeomInstanceTable <- function(connectionDetails, schema, name) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS ", schema, ";"))
  if(!checkTableExists(connectionDetails, schema, paste0("geom_", name))) {
    DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                              ".\"geom_", name, "\" (like backbone.geom_template);"))
    DatabaseConnector::executeSql(conn, paste0("ALTER TABLE ", schema, ".\"geom_", name, "\" ",
                          "ALTER COLUMN geom_record_id ADD GENERATED BY DEFAULT AS IDENTITY;"))
  }
}


#' Connect to the Postgis database and insert a geometry table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param staged (data.frame) A well-formatted geometry table. Created by appending staging data table to an geom_template
#' @param geomIndex (data.frame) A full record (entire row) from the backbone.geom_index table corresponding to the registered geometry of interest
#'
#' @return A table (geom_X) in PostGIS
#'

insertPostgisGeometry <- function(connectionDetails, staged, geomIndex) {
  # TODO could this be simpler if rewritten as sf::st_write? Did I already try that?
  serv <- strsplit(connectionDetails$server(), "/")[[1]]

  postgisConnection <- RPostgreSQL::dbConnect("PostgreSQL",
                                              host = serv[1], dbname = serv[2],
                                              user = connectionDetails$user(),
                                              password = connectionDetails$password(),
                                              port = connectionDetails$port())
  on.exit(RPostgreSQL::dbDisconnect(postgisConnection))
  rpostgis::pgInsert(postgisConnection,
                     name = c(geomIndex$database_schema, paste0("geom_", geomIndex$table_name)),
                     geom = "geom_wgs84",
                     data.obj = staged)

}


#' Get the geom_template table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) An empty geom_template table
#'

getGeomTemplate <- function(connectionDetails){
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  geomTemplate <- DatabaseConnector::dbReadTable(conn, "backbone.geom_template")
  names(geomTemplate) <- tolower(names(geomTemplate))
  geomTemplate
}


#' Set the SRID on the geom_wgs84 column in PostGIS gaiaDB
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param staged (data.frame) A well-formatted geometry table. Created by appending staging data table to an geom_template
#' @param geomIndex (data.frame) A full record (entire row) from the backbone.geom_index table corresponding to the registered geometry of interest
#'
#' @return SRID set to 4326 the geom_wgs84 column in the given table in gaiaDB

setSridWgs84 <- function(connectionDetails, geometryType, geomIndex) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::executeSql(conn, sql = paste0(
    "ALTER TABLE ", geomIndex$database_schema, ".geom_",
    geomIndex$table_name, " ALTER COLUMN geom_wgs84 TYPE public.geometry(",
    geometryType,", 4326) USING public.ST_SetSRID(geom_wgs84, 4326);")
  )
}
#' Create indexes on a geom_* table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param schema (character) The name of the schema
#' @param name (character) The geometry table name
#'
#' @return Indexes on two geometry columns (geom_local_value, geom_wgs84)
#' 

createGeomTableIndexes <- function(connectionDetails, schema, name) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::executeSql(conn,
                                sql = paste0("CREATE INDEX geom_idx_", name, "_local ON ", schema,".geom_", name, " USING gist(geom_local_value);"))
  DatabaseConnector::executeSql(conn,
                                sql = paste0("CREATE INDEX geom_idx_", name,  "_wgs84 ON ", schema,".geom_", name, " USING gist(geom_wgs84);"))
  
}

# Load Variable -----------------------------------------------------------

#' Import a well-formatted attribute table into an empty instance of attr_X in PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param attribute (data.frame) A well-formatted attribute. Created by appending staging data table to an attr_template
#' @param attrIndex (data.frame) A full record (entire row) from the backbone.attr_index table corresponding to the registered attribute of interest
#'
#' @return A table (attr_X) in PostGIS
#'

importAttrTable <- function(connectionDetails, attribute, attrIndex){
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  attribute <- dplyr::select(attribute, -"attr_record_id")
  DatabaseConnector::insertTable(conn,
                                 databaseSchema = paste0("\"",attrIndex$database_schema,"\""),
                                 tableName = paste0("\"attr_",attrIndex$table_name,"\""),
                                 data = attribute,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE
  )

}


#' Create an empty instance of the attr_template in a given schema in PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param schema (character) The name of the schema in PostGIS where the empty attr_X should be created
#' @param name (character) The suffix for the table name to be created; will be appended to "attr_"
#'
#' @return An empty table (attr_X) in PostGIS
#'
#' @examples
#' \dontrun{
#'
#' variableSourceId <- 157
#'
#' variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))
#'
#' attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", variableTable$data_source_uuid,";"))
#'
#' createAttrInstanceTable(conn, schema = attrIndex$database_schema, name = attrIndex$table_name)
#' }
#'

createAttrInstanceTable <- function(connectionDetails, schema, name) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS ", schema, ";"))
  if(!checkTableExists(connectionDetails, schema, paste0("attr_", name))) {
    DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                              ".\"attr_", name, "\" (like backbone.attr_template);"))
    DatabaseConnector::executeSql(conn, paste0("ALTER TABLE ", schema, ".\"attr_", name, "\" ",
                          "ALTER COLUMN attr_record_id ADD GENERATED BY DEFAULT AS IDENTITY;"))
  }
}


#' Get the attr_template table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) An empty attr_template table
#'

getAttrTemplate <- function(connectionDetails){
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  attrTemplate <- DatabaseConnector::dbReadTable(conn, "backbone.attr_template")
  names(attrTemplate) <- tolower(names(attrTemplate))
  attrTemplate
}


#' Create a mapping table between identifiers and values for a given geom_X
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param geomIndexId (integer) Identifier of a record in the backbone.geom_index table. Usually sourced from the \code{attr_of_geom_index_id} entry of an attr_index record
#'
#' @return (data.frame) A mapping table between geom_record_id for a given geom_X and that record's source value
#'
#' @examples
#' \dontrun{
#' geomIdMap <- getGeomIdMap(conn = conn, geomIndex = 1)
#' }
#'

getGeomIdMap <- function(connectionDetails, geomIndexId){
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  geomIndexRecord <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE geom_index_id = ", geomIndexId,";"))
  sqlQuery <- paste0(
    "SELECT geom_record_id, geom_source_value FROM "
    , geomIndexRecord$database_schema
    ,".\"geom_"
    , geomIndexRecord$table_name
    ,'\";'
  )
  DatabaseConnector::dbGetQuery(conn, sqlQuery)
}




# Geocode -----------------------------------------------------------------

#' Get Location Table Addresses
#'
#' @param connectionDetails (list) For connecting to an OMOP server. An object of class connectionDetails as created by the createConnectionDetails function
#' @param cdmDatabseSchema (character) Schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
#'
#' @return (data.frame) A transformed Location table with addresses and any existing latitude and longitudes attached
#'
#' @examples
#' \dontrun{
#' getLocationAddresses(connectionDetails = connectionDetails,
#'                    cdmDatabaseSchema = myDatabase.dbo)
#' }
#' 
#' @export
#' 
getLocationAddresses <- function(connectionDetails, cdmDatabaseSchema){
  addressQuery <- paste0("SELECT l.location_id
	  , CONCAT(COALESCE(l.address_1, ''), ' ', COALESCE(l.address_2, ''), ' ', COALESCE(l.city, ''), ' ', COALESCE(l.state, ''), ' ', LEFT(COALESCE(l.zip, ''), 5)) AS address
	  , latitude
	  , longitude
    FROM ", cdmDatabaseSchema, ".location l")
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  locationAddresses <- tryCatch({
    DatabaseConnector::querySql(connection = conn, sql = addressQuery)
  }, error = function(err) {
    if(stringr::str_detect(conditionMessage(err), "longitude|latitude")) {
      message('\nLatitude/Longitude columns skipped.')
      addressQuery <- paste0("SELECT l.location_id
  	  , CONCAT(COALESCE(l.address_1, ''), ' ', COALESCE(l.address_2, ''), ' ', COALESCE(l.city, ''), ' ', COALESCE(l.state, ''), ' ', LEFT(COALESCE(l.zip, ''), 5)) AS address
      FROM ", cdmDatabaseSchema, ".location l")
      DatabaseConnector::querySql(connection = conn, sql = addressQuery)
    } else {
      cat(conditionMessage(err))
    }
  })
  locationAddresses
}

#' Import a geocoded cohort table to gaiaDB
#'
#' @param gaiaConnectionDetails (list) For connecting to gaiaDB. An object of class
#'                              connectionDetails as created by the
#'                              createConnectionDetails function
#' @param location (data.frame) A table with OMOP location_ids, an address
#'                              string, and POINT geometry column named geometry 
#' @param overwrite (boolean) Overwrite existing tables in the cohort schema?
#'
#' @return A new geom_omop_location table in the gaiaDB omop schema
#'
#' @examples
#' \dontrun{
#' importLocationTable(gaiaConnectionDetails = gaiaConnectionDetails,
#'                     location = geocodedLocation,
#'                     overwrite = FALSE)
#' }
#' 
#' @export
#' 

importLocationTable <- function(gaiaConnectionDetails, location, overwrite = FALSE) {
  conn <-  DatabaseConnector::connect(gaiaConnectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS omop;"))
  if(!checkTableExists(gaiaConnectionDetails, "omop", 'geom_omop_location')) {
    DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS
                                              omop.\"geom_omop_location\"
                                              (location_id INT,
                                              address VARCHAR(255),
                                              geometry public.GEOMETRY);"))
    DatabaseConnector::dbExecute(conn,
    paste0("ALTER TABLE omop.\"geom_omop_location\"
            ALTER COLUMN geometry TYPE public.geometry(POINT, 4326)
            USING public.ST_SetSRID(geometry,4326);"))
  } else {
    message('Table omop.geom_omop_location already exists.')
    return()
  }
  locationSpatial <- location %>% 
    dplyr::mutate(location_id = as.integer(location_id)) %>%
    sf::as_Spatial()
  serv <- strsplit(gaiaConnectionDetails$server(), "/")[[1]]
  postgisConnection <- RPostgreSQL::dbConnect("PostgreSQL",
                                              host = serv[1],
                                              dbname = serv[2],
                                              user = gaiaConnectionDetails$user(),
                                              password = gaiaConnectionDetails$password(),
                                              port = gaiaConnectionDetails$port())
  on.exit(RPostgreSQL::dbDisconnect(postgisConnection))
  rpostgis::pgInsert(postgisConnection,
                     name = c("omop", "geom_omop_location"),
                     geom = "geometry", 
                     data.obj = locationSpatial)
  RPostgreSQL::dbDisconnect(postgisConnection)

  
}


#' Get Cohort Addresses
#'
#' @param connectionDetails (list) For connecting to an OMOP server. An object of class connectionDetails as created by the createConnectionDetails function
#' @param cdmDatabseSchema (character) Schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohort (data.frame) A table that includes a columns named "SUBJECT_ID" that contains a list of OMOP person_ids. Ideally, an OHDSI cohort table
#'
#' @return (data.frame) An augmented Cohort table with patient addresses attached
#'
#' @examples
#' \dontrun{
#' getCohortAddresses(connectionDetails = connectionDetails,
#'                    cdmDatabaseSchema = "myDatabase.dbo",
#'                    cohort = cohort)
#' }
#' 
#' @export
#' 

getCohortAddresses <- function(connectionDetails, cdmDatabaseSchema, cohort){
  personIds <- cohort %>%
    dplyr::pull("SUBJECT_ID") %>%
    unique()
  addressQuery <- paste0("SELECT p.person_id
	  , CONCAT(l.address_1, ' ', l.address_2, ' ', l.city, ' ', l.state, ' ', LEFT(l.zip, 5)) AS address,
	  , latitude
	  , longitude
    FROM ", cdmDatabaseSchema, ".person p
    LEFT JOIN ", cdmDatabaseSchema, ".location l
    ON p.location_id = l.location_id
    WHERE person_id in (", paste(personIds, collapse = ", "),")")
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  personAddresses <- tryCatch({
    DatabaseConnector::querySql(connection = conn, sql = addressQuery)
  }, error = function(err) {
    if(stringr::str_detect(conditionMessage(err), "longitude|latitude")) {
      message('\nLatitude/Longitude columns skipped.')
      addressQuery <- paste0("SELECT l.location_id
  	  , CONCAT(l.address_1, ' ', l.address_2, ' ', l.city, ' ', l.state, ' ', LEFT(l.zip, 5)) AS address
      FROM ", cdmDatabaseSchema, ".location l")
      DatabaseConnector::querySql(connection = conn, sql = addressQuery)
    } else {
      cat(conditionMessage(err))
    }
  })
  cohortWithAddresses <- cohort %>%
    dplyr::left_join(personAddresses, by = c("SUBJECT_ID"="PERSON_ID"))
  cohortWithAddresses
}


#' Import a geocoded cohort table to gaiaDB
#'
#' @param gaiaConnectionDetails (list) For connecting to gaiaDB. An object of class
#'                              connectionDetails as created by the
#'                              createConnectionDetails function
#' @param cohort (data.frame) An OHDSI cohort table with a POINT geometry column
#'                            named geometry 
#' @param overwrite (boolean) Overwrite existing tables in the cohort schema?
#'
#' @return A new cohort table in the gaiaDB cohort schema
#'
#' @examples
#' \dontrun{
#' importCohortTable(gaiaConnectionDetails = gaiaConnectionDetails,
#'                   cohort = geocodedCohort,
#'                   overwrite = FALSE)
#' }
#' @export
#' 

importCohortTable <- function(gaiaConnectionDetails, cohort, overwrite = FALSE) {
  names(cohort) <- tolower(names(cohort))
  conn <-  DatabaseConnector::connect(gaiaConnectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS cohort;"))
  tables <- unique(cohort$cohort_definition_id)
  lapply(tables, function(cohortId) {
    if(!checkTableExists(gaiaConnectionDetails, "cohort", paste0('cohort_', cohortId))) {
      DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS
                                                cohort.\"cohort_", cohortId, "\"
                                                (cohort_definition_id INT,
                                                subject_id INT,
                                                cohort_start_date DATE,
                                                cohort_end_date DATE,
                                                geometry public.GEOMETRY);"))
      DatabaseConnector::dbExecute(conn, paste0("
        ALTER TABLE cohort.\"cohort_", cohortId, "\"
        ALTER COLUMN geometry TYPE public.geometry(POINT, 4326)
        USING public.ST_SetSRID(geometry,4326);"))
    } else {
      message(paste0('Table cohort.cohort_', cohortId, ' already exists.'))
      return()
    }
    filteredSpatialCohort <- cohort %>% 
      dplyr::filter(cohort_definition_id == cohortId) %>% 
      sf::as_Spatial()
    serv <- strsplit(gaiaConnectionDetails$server(), "/")[[1]]
    postgisConnection <- RPostgreSQL::dbConnect("PostgreSQL",
                                                host = serv[1],
                                                dbname = serv[2],
                                                user = gaiaConnectionDetails$user(),
                                                password = gaiaConnectionDetails$password(),
                                                port = gaiaConnectionDetails$port())
    on.exit(RPostgreSQL::dbDisconnect(postgisConnection))
    rpostgis::pgInsert(postgisConnection,
                       name = c("cohort", paste0('cohort_', cohortId)),
                       geom = "geometry", 
                       data.obj = filteredSpatialCohort)
    RPostgreSQL::dbDisconnect(postgisConnection)
  })
  
}

createGeomOmopLocationIdex <- function(connectionDetails) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::executeSql(conn,
                                sql = paste0("CREATE INDEX omop_location_idx ON omop.geom_omop_location USING gist (geometry);
"))
}
