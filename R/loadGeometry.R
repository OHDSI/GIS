#' Loads a geometry from a registered source into PostGIS as geom_X
#'
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

loadGeometry <- function(connectionDetails, dataSourceUuid) {

  dataSourceRecord <- getDataSourceRecord(connectionDetails = connectionDetails,
                                          dataSourceUuid = dataSourceUuid)

  staged <- getStaged(dataSourceRecord)

  stagedResult <- standardizeStagedGeom(staged = staged, geomSpec = dataSourceRecord$geom_spec)

  geomIndex <- getGeomIndexRecord(connectionDetails = connectionDetails,
                                  dataSourceUuid = dataSourceRecord$data_source_uuid)


  # format for insert
  if (!"character" %in% class(stagedResult$geom_local_value)) {
    stagedResult$geom_local_value <- sf::st_as_binary(stagedResult$geom_local_value, EWKB = TRUE, hex = TRUE)
  }

  geomTemplate <- getGeomTemplate(connectionDetails = connectionDetails)

  res <- plyr::rbind.fill(geomTemplate, stagedResult)

  res <- res[-1]

  res$geom_name <- iconv(res$geom_name, "latin1")

  createGeomInstanceTable(connectionDetails = connectionDetails,
                          schema =  geomIndex$table_schema,
                          name = geomIndex$table_name)

  # insert into geom table
  importGeomTable(connectionDetails = connectionDetails,
                  staged = res,
                  geomIndex = geomIndex)
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
    insertPostgisGeometry(connectionDetails = connectionDetails,
                          staged = staged,
                          geomIndex = geomIndex)
  }

}


