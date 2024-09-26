#' Create an exposure_occurrence (exposure) table from a variable source id
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @param variableSourceId (integer) The variable source id of the variable to create an exposure table for
#' 
#' @param locationImport (data.frame) A data frame with columns location_id and geometry. Represents the geocoded locations
#' 
#' @return (data.frame) An OMOP CDM exposure_occurrence table for the specified variable source id and locations
#'
#' @examples
#' \dontrun{
#' # Create exposure_occurrence table for a given variable 
#' variableSourceId <- 1 # Percentile Percentage of persons below poverty estimate 
#' locationImport <- data.frame(location)
#' exposure_occurrence <- createExposure(connectionDetails, variableSourceId, locationImport)
#' }
#'
#' @details 
#' This function creates an exposure_occurrence table for a given variable source id and geocoded locations.
#' The exposure_occurrence table is created by joining the variable table to the geom table and then joining
#' the geom table to the geocoded locations. The exposure_occurrence table is then created by selecting the
#' relevant columns from the variable table and the geocoded locations.
#' 
#' The locationImport data frame should have columns location_id and geometry. The location_id column should
#' be an integer representing the location_id of the geocoded location. The geometry column should be a binary
#' representation of the geometry of the geocoded location:
#' ```
#' locationImport <- read.csv('geocoded_location_snippet.csv', sep="|", header=FALSE)
#' locationImport <- dplyr::rename(locationImport, location_id=1, lat=11, lon=12)
#' locationImport <- dplyr::mutate(locationImport, 
#'     location_id=as.integer(location_id),
#'     lat=as.numeric(lat),
#'     lon=as.numeric(gsub("[\\n]", "", lon)))
#' locationImport <- dplyr::filter(locationImport, !is.na(lat) & !is.na(lon))
#' locationImport <- locationImport_sf <- sf::st_as_sf(locationImport, coords=c('lon', 'lat'), crs=4326) 
#' locationImport <- dplyr::select(locationImport, location_id, geometry)   
#' locationImport <- data.frame(locationImport)
#' locationImport$geometry <-
#'     sf::st_as_binary(locationImport$geometry, EWKB = TRUE, hex = TRUE)
#' 
#' #> head(locationImport)
#' #=>   location_id                                           geometry
#' #=> 1           1 0101000020e610000072230d5ff6c351c000023164d0284540
#' #=> 2           2 0101000020e61000007222df852d8a52c0978b9d95594e4440
#' #=> 3           3 0101000020e610000076319xaa4ae351c0ba0a73cc43124540
#' #=> 4           4 0101000020e61000001d90fdfc97bc51c08a05bea2dbdd4440
#' ```
#' @export
#'

createExposure <- function(connectionDetails, variableSourceId, locationImport) {

# TODO verify locationImport

# Check that specified variable (and geom) are both loaded to staging ---------------

  geomFullTableName <- getGeomNameFromVariableSourceId(connectionDetails = connectionDetails,
                                                       variableSourceId = variableSourceId)
  attrFullTableName <- getAttrNameFromVariableSourceId(connectionDetails = connectionDetails,
                                                   variableSourceId = variableSourceId)
  

  attrSchema <- strsplit(attrFullTableName, split="\\.")[[1]][[1]]
  attrTableName <- strsplit(attrFullTableName, split="\\.")[[1]][[2]]
  
  # TODO the following is a deconstruction of checkVariableExists.
  # Refactor checkVariableExists to handle this case and not break the existing use case
  
  
  if (!checkTableExists(connectionDetails = connectionDetails,
                        databaseSchema = attrSchema,
                        tableName = attrTableName)) {
    loadVariable(connectionDetails, variableSourceId)
  }
  
  variableExistsQuery <- paste0("select count(*) from ", attrFullTableName, " where variable_source_record_id = '", variableSourceId,"'")
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  variableExistsResult <- DatabaseConnector::querySql(conn, variableExistsQuery)
  if (!variableExistsResult > 0){
    loadVariable(connectionDetails, variableSourceId)
  }
  
# Join all variable to geom, join all to geocoded addresses (create exp_occ in mem) --------------------------------------------

  # TODO this could be a function in dbUtils

  #TODO add temporal join condition:
  # <<<
  # join omop.geom_omop_location gol 
  # on public.st_within(gol.geometry, geo.geom_wgs84)"
  # and (gol.valid_start_date < att.attr_end_date
  #      or gol.valid_end_date >att.attr_start_date)
  # >>>
  
  # TODO better exposure_*_date logic:
  # After temporal join condition is added
  # <<<
  # CASE WHEN att.attr_start_date >= gol.valid_start_date THEN att.attr_start_date
  #      ELSE gol.valid_start_date END AS exposure_start_date
  # CASE WHEN att.attr_end_date <= gol.valid_end_date THEN att.attr_end_date
  #      ELSE gol.valid_end_date END AS exposure_end_date
  # >>>
  
  # TODO how to get exposure_type_concept_id
  
  # create table geom omop location
  DatabaseConnector::executeSql(conn, "CREATE SCHEMA IF NOT EXISTS omop;")
  DatabaseConnector::executeSql(conn, "DROP TABLE IF EXISTS omop.geom_omop_location")
  DatabaseConnector::executeSql(conn, "CREATE TABLE IF NOT EXISTS omop.geom_omop_location ( 
    location_id integer,
    geometry public.geometry
  )")
  
  serv <- strsplit(connectionDetails$server(), "/")[[1]]

  postgisConnection <- RPostgreSQL::dbConnect("PostgreSQL",
                                              host = serv[1], dbname = serv[2],
                                              user = connectionDetails$user(),
                                              password = connectionDetails$password(),
                                              port = connectionDetails$port())
  on.exit(RPostgreSQL::dbDisconnect(postgisConnection))
  rpostgis::pgInsert(postgisConnection,
                     name = c("omop", "geom_omop_location"),
                     geom = "geometry",
                     data.obj = locationImport)

  exposureOccurrence <- DatabaseConnector::dbGetQuery(conn, paste0(
    "select 
    gol.location_id
      , CAST(NULL AS INTEGER) AS person_id
      , CASE WHEN att.attr_concept_id IS NOT NULL THEN att.attr_concept_id ELSE 0 END AS exposure_concept_id
      , att.attr_start_date AS exposure_start_date
      , att.attr_start_date AS exposure_start_datetime
      , att.attr_end_date AS exposure_end_date
      , att.attr_end_date AS exposure_end_datetime
      , 0 AS exposure_type_concept_id
      , 0 AS exposure_relationship_concept_id
      , att.attr_source_concept_id AS exposure_source_concept_id
      , att.attr_source_value AS exposure_source_value
      , CAST(NULL AS VARCHAR(50)) AS exposure_relationship_source_value
      , CAST(NULL AS VARCHAR(50)) AS dose_unit_source_value
      , CAST(NULL AS INTEGER) AS quantity
      , CAST(NULL AS VARCHAR(50)) AS modifier_source_value
      , CAST(NULL AS INTEGER) AS operator_concept_id
      , att.value_as_number AS value_as_number
      , att.value_as_concept_id AS value_as_concept_id
      , att.unit_concept_id AS unit_concept_id
    from ", getAttrNameFromVariableSourceId(connectionDetails, variableSourceId) ," att
    inner join ", getGeomNameFromVariableSourceId(connectionDetails, variableSourceId)," geo
    on att.geom_record_id = geo.geom_record_id 
    and att.variable_source_record_id = ", variableSourceId, "
    join omop.geom_omop_location gol 
    on public.st_within(gol.geometry, geo.geom_wgs84)"
  ))  
  
  DatabaseConnector::disconnect(conn)
  
  # Create exposure_occurrence_id column ------------------------------------

  exposure_occurrence_id <- seq.int(nrow(exposureOccurrence))
  exposureOccurrence <- cbind(exposure_occurrence_id, exposureOccurrence)
  exposureOccurrence
}
