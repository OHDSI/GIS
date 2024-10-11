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
#' if (!DatabaseConnector::existsTable(conn, geomIndex$database_schema, paste0("geom_",geomIndex$table_name))) {
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
  geomIndexRecord <- getGeomIndexRecord(connectionDetails = connectionDetails,
                                              dataSourceUuid = dataSourceRecord$data_source_uuid)

  if(checkTableExists(connectionDetails = connectionDetails,
                         databaseSchema = geomIndexRecord$database_schema,
                         tableName = paste0("geom_", geomIndexRecord$table_name))) {
    return(message(paste0("geom_",
                          geomIndexRecord$database_schema, ".",
                          geomIndexRecord$table_name,
                          " already exists in the database.")))
  }
  staged <- getStaged(dataSourceRecord, storageConfig = readStorageConfig())

  stagedResult <- standardizeStaged(staged = staged, spec = dataSourceRecord$geom_spec)

  geometryType <- ""
  if (!is.null(staged$geometry)) {
    geometryType <- as.character(unique(sf::st_geometry_type(staged$geometry)))
  } else {
    geometryType <- as.character(unique(sf::st_geometry_type(sf::st_as_sf(stagedResult)$geom_local_value)))
  }
  
  # Transform local geometry to epsg:4326
  if (!"geom_wgs84" %in% names(stagedResult)) {
    stagedResult <- sf::st_as_sf(stagedResult)
    if (is.na(sf::st_crs(stagedResult))){
        if (length(unique(stagedResult$geom_local_epsg)) == 0) {
          stop("Error: No local EPSG set. CRS cannot be set. Geometry cannot be loaded.")
        } else if (length(unique(stagedResult$geom_local_epsg)) == 1) {
          stagedResult <- sf::set_crs(stagedResult, unique(stagedResult$geom_local_epsg)[[1]])
        } else {
          epsg <- unique(stagedResult$geom_local_epsg)
          epsg_df <- lapply(epsg, function(x) {
            epsg_fragment <- dplyr::filter(stagedResult, geom_local_epsg==x)
            epsg_fragment <- sf::st_set_crs(epsg_fragment, x)
            epsg_fragment$geom_local_value <- sf::st_transform(epsg_fragment$geom_local_value, 4326)
            epsg_fragment
          })
          stagedResult <- dplyr::bind_rows(epsg_df, .id="column_label")
        }
    }
    stagedResult$geom_wgs84 <- sf::st_transform(stagedResult$geom_local_value, 4326)
  }
  
  # format for insert
  stagedResult <- data.frame(stagedResult)
  if (!"character" %in% class(stagedResult$geom_local_value)) {
    stagedResult$geom_local_value <- sf::st_as_binary(stagedResult$geom_local_value, EWKB = TRUE, hex = TRUE)
    stagedResult$geom_wgs84 <- sf::st_as_binary(stagedResult$geom_wgs84, EWKB = TRUE, hex = TRUE)
    
  }
  
  geomTemplate <- getGeomTemplate(connectionDetails = connectionDetails)
  names(geomTemplate) <- tolower(names(geomTemplate))
  names(stagedResult) <-  tolower(names(stagedResult))
  
  stagedResult <- dplyr::select(stagedResult,
                                names(geomTemplate)[names(geomTemplate) %in% names(stagedResult)])

  res <- plyr::rbind.fill(geomTemplate, stagedResult)

  if ("geom_record_id" %in% names(res)) {
  res <- dplyr::select(res,
                       -geom_record_id)
  }

  if ("geometry" %in% names(res)) {
    res <- dplyr::select(res,
                         -geometry)
  }

  res$geom_name <- iconv(res$geom_name, "latin1")
  
  createGeomInstanceTable(connectionDetails = connectionDetails,
                          schema =  geomIndexRecord$database_schema,
                          name = geomIndexRecord$table_name)

  # insert into geom table
  importGeomTable(connectionDetails = connectionDetails,
                  staged = res,
                  geomIndex = geomIndexRecord)
  
  # Set SRID on geom_wgs84 after table import
  setSridWgs84(connectionDetails = connectionDetails,
               geometryType = geometryType,
               geomIndex = geomIndexRecord)
  
  # Index the geometry column (geom_local_value, geom_wgs84)
  createGeomTableIndexes(connectionDetails = connectionDetails,
                         schema =  geomIndexRecord$database_schema,
                         name = geomIndexRecord$table_name)
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


