#' Loads a variable from a registered source into PostGIS as attr_X
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param variableSourceId (integer) The identifier for the variable that is registered in the PostGIS variable_source table
#'
#' @return A table (attr_X) in PostGIS
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
#' tableExists <- DatabaseConnector::existsTable(conn,
#'                                               attrIndex$table_schema,
#'                                               paste0("attr_", attrIndex$table_name))
#'
#' if (!tableExists) {
#'   message("Loading attr table dependency")
#'   loadVariable(conn = conn, connectionDetails = connectionDetails, variableSourceId)
#' }
#' }
#'
#' @export
#'

loadVariable <- function(conn, connectionDetails, variableSourceId){

  # get variable
  variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))

  # get attr_index
  attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", variableTable$data_source_uuid,";"))

  # get data_source_record
  dataSourceRecord <- getDataSourceRecord(conn, variableTable$data_source_uuid)

  geomIndex <- getGeomIndexByDataSourceUuid(conn, dataSourceRecord$geom_dependency_uuid)

  # get stage data
  staged <- getStaged(dataSourceRecord)

  # for attr, remove geom
  if ("sf" %in% class(staged)) {
    staged <- sf::st_drop_geometry(staged)
  }

  ## format table for insert ----

  # create spec table
  specTable <- createSpecTable(variableTable$attr_spec)

  stagedResult <- standardizeStaged(staged, specTable)

  # prepare for insert

  # Load geom_dependency if necessary
  if (!DatabaseConnector::existsTable(conn, geomIndex$table_schema, paste0("geom_",geomIndex$table_name))) {
    message("Loading geom table dependency")
    loadGeomTable(conn, connectionDetails, dataSourceRecord$geom_dependency_uuid)
  }

  # get mapping values from geom table
  stagedResult <- assignGeomIdToAttr(conn, stagedResult, attrIndex$attr_of_geom_index_id)

  # stagedResult <- tmp
  # get attr template
  attrTemplate <- getAttrTemplate(conn)

  # append staging data to template format
  attrToIngest <- plyr::rbind.fill(attrTemplate, stagedResult)

  createAttrInstanceTable(conn, schema = attrIndex$table_schema, name = attrIndex$table_name)

  # import
  importAttrTable(conn, attrToIngest, attrIndex)

}

#' Import a well-formatted attribute table into an empty instance of attr_X in PostGIS
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param attribute (data.frame) A well-formatted attribute. Created by appending staging data table to an attr_template
#' @param attrIndex (data.frame) A full record (entire row) from the backbone.attr_index table corresponding to the registered attribute of interest
#'
#' @return A table (attr_X) in PostGIS
#'

importAttrTable <- function(conn, attribute, attrIndex){

  attribute <- dplyr::select(attribute, -"attr_record_id")

  DatabaseConnector::insertTable(conn,
                                 databaseSchema = paste0("\"",attrIndex$table_schema,"\""),
                                 tableName = paste0("\"attr_",attrIndex$table_name,"\""),
                                 data = attribute,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE
  )

}

#' Create an empty instance of the attr_template in a given schema in PostGIS
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
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
#' createAttrInstanceTable(conn, schema = attrIndex$table_schema, name = attrIndex$table_name)
#' }
#'

createAttrInstanceTable <- function(conn, schema, name) {
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS ", schema, ";"))
  DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                            ".\"attr_", name, "\" (",
                                            "attr_record_id serial4 NOT NULL, ",
                                            "geom_record_id int4 NULL, ",
                                            "attr_concept_id int4 NULL, ",
                                            "attr_start_date date NULL, ",
                                            "attr_end_date date NULL, ",
                                            "value_as_number float8 NULL, ",
                                            "value_as_string varchar NULL, ",
                                            "value_as_concept_id int4 NULL, ",
                                            "unit_concept_id int4 NULL, ",
                                            "unit_source_value varchar NULL, ",
                                            "qualifier_concept_id int4 NULL, ",
                                            "qualifier_source_value varchar NULL, ",
                                            "attr_source_concept_id int4 NULL, ",
                                            "attr_source_value varchar NULL, ",
                                            "value_source_value varchar NULL, ",
                                            "CONSTRAINT attr_record_", createNameString(name),
                                            "_pkey PRIMARY KEY (attr_record_id));"))
}


#' Create a mapping table between identifiers and values for a given geom_X
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param geomIndex (integer) Identifier of a record in the backbone.geom_index table. Usually sourced from the \code{attr_of_geom_index_id} entry of an attr_index record
#'
#' @return (data.frame) A mapping table between geom_record_id for a given geom_X and that record's source value
#'
#' @examples
#' \dontrun{
#' geomIdMap <- getGeomIdMap(conn = conn, geomIndex = 1)
#' }
#'

getGeomIdMap <- function(conn, geomIndex){
  #TODO change the argument geomIndex to geomIndexId, which is what it is
  geomIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE geom_index_id = ", geomIndex,";"))

sqlQuery <- paste0(
    "SELECT geom_record_id, geom_source_value FROM "
    , geomIndex$table_schema
    ,".\"geom_"
    , geomIndex$table_name
    ,'\";'
  )
  DatabaseConnector::dbGetQuery(conn, sqlQuery)
}

#' Join a column of geom_X record identifiers to a staged attr_X table
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param stagedResult (data.frame) A table standardized in the attr_template or geom_template mold
#' @param geomIndex (integer) Identifier of a record in the backbone.geom_index table. Usually sourced from the \code{attr_of_geom_index_id} entry of an attr_index record
#'
#' @return (data.frame) An updated \code{stagedResult} table with \code{geom_record_id}s corresponding to a geom_X table appended
#'

assignGeomIdToAttr <- function(conn, stagedResult, geomIndex){
  #TODO change the argument geomIndex to geomIndexId, which is what it is
  geomIdMap <- getGeomIdMap(conn, geomIndex)

  tmp <- merge(x = stagedResult, y= geomIdMap, by.x = "geom_join_column", by.y = "geom_source_value")

  tmp <- dplyr::select(tmp, -"geom_join_column")

  return(tmp)

}
