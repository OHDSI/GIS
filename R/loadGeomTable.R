#' Loads a geometry from a registered source into PostGIS as geom_X
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param dataSourceUuid (UUID) The UUID for the data source that is registered in the backbone.data_source table
#'
#' @return A table (geom_X) in PostGIS
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
#' if (!DatabaseConnector::existsTable(conn, geomIndex$table_schema, paste0("geom_",geomIndex$table_name))) {
#'   message("Loading geom table dependency")
#'   loadGeomTable(conn, connectionDetails, dataSourceRecord$geom_dependency_uuid)
#' }
#' }
#'
#' @export
#'

loadGeomTable <- function(conn, connectionDetails, dataSourceUuid) {

  dataSourceRecord <- getDataSourceRecord(conn, dataSourceUuid)

  staged <- getStaged(dataSourceRecord)

  specTable <- createSpecTable(dataSourceRecord$geom_spec)

  stagedResult <- standardizeStaged(staged, specTable)

  geomIndex <- getGeomIndexByDataSourceUuid(conn, dataSourceRecord$data_source_uuid)


  # format for insert
  if (!"character" %in% class(stagedResult$geom_local_value)) {
    stagedResult$geom_local_value <- sf::st_as_binary(stagedResult$geom_local_value, EWKB = TRUE, hex = TRUE)
  }

  geomTemplate <- getGeomTemplate(conn)

  res <- plyr::rbind.fill(geomTemplate, stagedResult)

  res <- res[-1]

  res$geom_name <- iconv(res$geom_name, "latin1")

  createGeomInstanceTable(conn, schema =  geomIndex$table_schema, name = geomIndex$table_name)

  # insert into geom table
  importGeomTable(connectionDetails, res, geomIndex)
}

#' Import a well-formatted geometry table into an empty instance of geom_X in PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param staged (data.frame) A well-formatted geometry table. Created by appending staging data table to an geom_template
#' @param geomIndex (data.frame) A full record (entire row) from the backbone.geom_index table corresponding to the registered geometry of interest
#'
#' @return A table (geom_X) in PostGIS
#'

importGeomTable <- function(connectionDetails, staged, geomIndex){

  dataSizeGb <- utils::object.size(staged) / 1000000000

  message(paste0("Expect ", ceiling(2*2**floor(log(dataSizeGb)/log(2))), " database inserts."))

  if(dataSizeGb > 1) {
    importGeomTable(connectionDetails, staged = staged[1:floor(nrow(staged)*.5),], geomIndex)
    importGeomTable(connectionDetails, staged = staged[floor(nrow(staged)*.5)+1:nrow(staged),], geomIndex)
  } else {

    # TODO could this be simpler if rewritten as sf::st_write? Did I already try that?
    serv <- strsplit(connectionDetails$server(), "/")[[1]]

    postgisConnection <- RPostgreSQL::dbConnect("PostgreSQL",
                                                host = serv[1], dbname = serv[2],
                                                user = connectionDetails$user(),
                                                password = connectionDetails$password(),
                                                port = connectionDetails$port()
    )


    rpostgis::pgInsert(postgisConnection,
                       name = c(geomIndex$table_schema, paste0("geom_", geomIndex$table_name)),
                       geom = "geom_local_value",
                       data.obj = staged)





    RPostgreSQL::dbDisconnect(postgisConnection)
  }

}

#' Create an empty instance of the geom_template in a given schema in PostGIS
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
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
#' createGeomInstanceTable(conn = conn, schema =  geomIndex$table_schema, name = geomIndex$table_name)
#' }
#'

createGeomInstanceTable <- function(conn, schema, name) {
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS ", schema, ";"))
  DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                            ".\"geom_", name, "\" (",
                                            "geom_record_id serial4 NOT NULL, ",
                                            "geom_name varchar NULL, ",
                                            "geom_source_coding varchar NULL, ",
                                            "geom_source_value varchar NULL, ",
                                            "geom_wgs84 ", "public.geometry NULL, ",
                                            "geom_local_epsg int4 NULL, ",
                                            "geom_local_value ", "public.geometry NULL, ",
                                            "CONSTRAINT geom_record_", createNameString(name),
                                            "_pkey PRIMARY KEY (geom_record_id));"))
}
