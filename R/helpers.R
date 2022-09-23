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
  tableExists <- DatabaseConnector::existsTable(conn, schema, name)
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



#' Create the schema and sanitize source values
#'
#' @param rec (data.frame) A full record (entire row) from the backbone.data_source table
#'
#' @return (character) Sanitized schema string
#'

createSchemaString <- function(rec) {
  paste0(rec$org_id, "_", rec$org_set_id) %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}


#' Sanitize and create table name from source values
#'
#' @param name (character) Table name source value
#'
#' @return (character) Sanitized table name string
#'

createNameString <- function(name) {
  name %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}


#' Get foreign key for attr_of_geom_index_id
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param uuid (UUID) The UUID for the data source that is registered in the backbone.data_source table
#'
#' @return (integer) Identifier for the corresponding backbone.geom_index entry
#'

getForeignKeyGid <- function(conn, uuid) {
  #TODO change the argument name from uuid to dataSourceUuid to align with similar functions
  geomIndex <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
  geomIndex[geomIndex$data_source_id == uuid,]$geom_index_id
}


#' Get a single record from the backbone.data_source table
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param dataSourceUuid (UUID) The UUID for the data source that is registered in the backbone.data_source table
#'
#' @return (data.frame) A full record (entire row) from the backbone.data_source table
#'

getDataSourceRecord <- function(conn, dataSourceUuid){
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.data_source WHERE data_source_uuid = ", dataSourceUuid))
}


#' Get the geom_template table
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#'
#' @return (data.frame) An empty geom_template table
#'

getGeomTemplate <- function(conn){
  DatabaseConnector::dbReadTable(conn, "backbone.geom_template")
}


#' Get a record from the backbone.geom_index table from it's corresponding UUID in backbone.data_source table
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param dataSourceUuid (UUID) The UUID for the data source that is registered in the backbone.data_source table
#'
#' @return (data.frame) A full record (entire row) from the backbone.geom_index table
#'

getGeomIndexByDataSourceUuid <- function(conn, dataSourceUuid){
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE data_source_id = ", dataSourceUuid))
}


#' Get the attr_template table
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#'
#' @return (data.frame) An empty attr_template table
#'

getAttrTemplate <- function(conn){
  DatabaseConnector::dbReadTable(conn, "backbone.attr_template")
}
