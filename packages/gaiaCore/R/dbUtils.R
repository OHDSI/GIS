# General -----------------------------------------------------------------

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
  attrTableString <- paste0(databaseSchema, ".\"attr_", tableName, "\"")
  variableExistsQuery <- paste0("select count(*) from ", attrTableString,
                                " where attr_source_value = '", variableName,"'")
  variableExistsResult <- DatabaseConnector::querySql(conn, variableExistsQuery)
  variableExists <- variableExistsResult > 0
  variableExists[1]
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
  DatabaseConnector::dbReadTable(conn, "backbone.data_source")
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
  DatabaseConnector::dbReadTable(conn, "backbone.variable_source")
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
  DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
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
  DatabaseConnector::dbReadTable(conn, "backbone.attr_index")
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

getAttrIndexRecord <- function(connectionDetails, dataSourceUuid) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", dataSourceUuid))
}


# Create Indices ----------------------------------------------------------

createGeomIndexRecord <- function(connectionDetails, dataSourceRecord) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  indexRecord <- dplyr::tibble(
    data_type_id = "NULL",
    data_type_name = dataSourceRecord$geom_type,
    geom_type_concept_id = "NULL",
    geom_type_source_value = dataSourceRecord$boundary_type,
    database_schema = createSchemaString(dataSourceRecord),
    table_name = createNameString(name = dataSourceRecord$dataset_name),
    table_desc = paste(dataSourceRecord$org_id, dataSourceRecord$org_set_id, dataSourceRecord$dataset_name),
    data_source_id = dataSourceRecord$data_source_uuid)
  insertLogic <- paste0("INSERT INTO backbone.geom_index ",
                        "(data_type_id, data_type_name, geom_type_concept_id, ",
                        "geom_type_source_value, database_schema, table_name, table_desc, ",
                        "data_source_id) VALUES ('",
                        paste(indexRecord %>% dplyr::slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                        "');") %>%
    stringr::str_replace_all("'NULL'", "NULL")
  DatabaseConnector::executeSql(conn, insertLogic)
}


#' Create a single record in the backbone.attr_index table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param dataSourceRecord (data.frame) A full record (entire row) from the backbone.data_source table
#'
#' @return A new record in the backbone.attr_index table
#'
#' @examples
#' \dontrun{
#'
#' record <- getDataSourceRecord(connectionDetails = connectionDetails, dataSourceUuid = 9999)
#'
#' createAttrIndexRecord(connectionDetails = connectionDetails, dataSourceRecord = record)
#' }
#'

createAttrIndexRecord <- function(connectionDetails, dataSourceRecord) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  indexRecord <- dplyr::tibble(
    attr_of_geom_index_id = getAttrOfGeomIndexId(connectionDetails = connectionDetails,
                                                 dataSourceUuid = dataSourceRecord$geom_dependency_uuid),
    database_schema = createSchemaString(dataSourceRecord),
    table_name = createNameString(name = dataSourceRecord$dataset_name),
    data_source_id = dataSourceRecord$data_source_uuid)
  insertLogic <- paste0("INSERT INTO backbone.attr_index ",
                        "(attr_of_geom_index_id, database_schema, table_name, data_source_id) ",
                        "VALUES ('",
                        paste(indexRecord %>% dplyr::slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                        "');") %>%
    stringr::str_replace_all("'NULL'", "NULL")
  DatabaseConnector::executeSql(conn, insertLogic)
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
  DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                            ".\"geom_", name, "\" (like backbone.geom_template);"))
  DatabaseConnector::dbExecute(conn, paste0("create sequence ", schema, ".geom_", name, "_geom_record_id_seq;"))
  DatabaseConnector::dbExecute(conn, paste0("ALTER TABLE ONLY ", schema, ".\"geom_", name,
                                            "\" ALTER COLUMN geom_record_id SET DEFAULT ",
                                            "nextval('", schema, ".geom_", name, "_geom_record_id_seq'::regclass);"))
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
                     geom = "geom_local_value",
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
  DatabaseConnector::dbReadTable(conn, "backbone.geom_template")
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
  DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                            ".\"attr_", name, "\" (like backbone.attr_template);"))
  DatabaseConnector::dbExecute(conn, paste0("create sequence ", schema, ".attr_", name, "_attr_record_id_seq;"))
  DatabaseConnector::dbExecute(conn, paste0("ALTER TABLE ONLY ", schema, ".\"attr_", name,
                                            "\" ALTER COLUMN attr_record_id SET DEFAULT ",
                                            "nextval('", schema, ".attr_", name, "_attr_record_id_seq'::regclass);"))
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
  DatabaseConnector::dbReadTable(conn, "backbone.attr_template")
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


# Get Current Load --------------------------------------------------------

#' Get list of unique variable IDs in attr_X
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param databaseSchema (character) schema that contains an attr_X table
#' @param tableName (character) name of an attr_X table
#'
#' @return (vector) a character vector of all loaded variable source IDs
#'

getUniqueVariablesInAttrX <- function(connectionDetails, databaseSchema, tableName) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  uniqueVarQuery <- paste0("select distinct variable_source_record_id from ",
                           databaseSchema,".", tableName)
  uniqueVarResult <- DatabaseConnector::querySql(conn, uniqueVarQuery)
  uniqueVarResult$VARIABLE_SOURCE_RECORD_ID
}


#' Get a summary table of select variable source records by ID
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param loadedVariables (vector) a character vector of all loaded variable source IDs
#'
#' @return (data.frame) A table of select variable source records
#'

getVariableSourceSummaryTable <- function(connectionDetails, variableSourceIds) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  getVariableSourceSummaryQuery <- paste0(
    "select vs.variable_source_id, vs.variable_name, vs.variable_desc, ",
    "ds.dataset_name, ds.dataset_version, ds.boundary_type, ",
    "ds2.dataset_name as \"geom dependency\", ds2.geom_type ",
    "from backbone.variable_source vs ",
    "join backbone.data_source ds ",
    "on vs.data_source_uuid=ds.data_source_uuid ",
    "join backbone.data_source ds2 ",
    "on ds.geom_dependency_uuid = ds2.data_source_uuid ",
    "where variable_source_id in (", paste(variableSourceIds, collapse = ","), ")")
  DatabaseConnector::querySql(conn, getVariableSourceSummaryQuery)
}


# Import Shapefile ---------------------------------------------------------

#' Handle the joining of geometry and attribute, as well as the simple or iterative import of a shapefile
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param attrTableString (character) Name of the attr_X table in databaseSchema.tableName format
#' @param geomTableString (character) Name of the geom_X table in databaseSchema.tableName format
#' @param variableName (character) Name of the variable to be imported
#'
#' @return (sf, data.frame) An sf object consisting of a single attribute and geometry; the result of joining attr_X and geom_X from the PostGIS
#'

handleShapefileImportJob <- function(connectionDetails, attrTableString, geomTableString, variableName) {
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  numberRecordsQuery <- paste0("select count(*) from ", attrTableString,
                               " join ", geomTableString,
                               " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                               " where ", attrTableString, ".attr_source_value = '", variableName,"'")

  queryCountResult <- DatabaseConnector::querySql(conn, numberRecordsQuery)
  rowCount <- queryCountResult$COUNT


  baseQuery <- paste0("select * from ", attrTableString,
                      " join ", geomTableString,
                      " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                      " where ", attrTableString, ".attr_source_value = '", variableName,"'")
  if (rowCount <= 1001) {
    shapefile <- sf::st_read(dsn = conn, query = baseQuery)
    return(shapefile)
  } else {
    shapefileBaseQuery <- paste0(baseQuery, " limit 1")
    shapefileBase <- sf::st_read(dsn = conn, query = shapefileBaseQuery)
    for (i in 0:(rowCount%/%1000)) {
      print(i)
      iterativeQuery <- paste0(baseQuery, " limit 1000 offset ", i * 1000 + 1)
      shapefileBase <- rbind(shapefileBase, sf::st_read(dsn = conn, query = iterativeQuery))
    }
    return(shapefileBase)
  }

}
