#' Get Cohort Addresses
#'
#' @param connectionDetails (list) For connecting to an OMOP server. An object of class connectionDetails as created by the createConnectionDetails function
#' @param cdmDatabseSchema (character) Schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohort (data.frame) A table that includes a columns named "SUBJECT_ID" that contains a list of OMOP person_ids. Ideally, an OHDSI cohort table
#'
#' @return (data.frame) An augmented Cohort table with patient addresses attached
#'
#' @examples
#' \dontrun
#' {
#' getCohortAddresses(connectionDetails = connectionDetails,
#'                    cdmDatabaseSchema = myDatabase.dbo,
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
	  , CONCAT(l.address_1, ' ', l.address_2, ' ', l.city, ' ', l.state, ' ', LEFT(l.zip, 5)) AS address  
    FROM ", cdmDatabaseSchema, ".person p
    LEFT JOIN ", cdmDatabaseSchema, ".location l
    ON p.location_id = l.location_id
    WHERE person_id in (", paste(personIds, collapse = ", "),")")
  conn <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  personAddresses <- DatabaseConnector::querySql(connection = conn, sql = addressQuery)
  cohortWithAddresses <- cohort %>%
    dplyr::left_join(personAddresses, by = c("SUBJECT_ID"="PERSON_ID")) %>% 
    dplyr::rename("address"="ADDRESS")
  cohortWithAddresses
}


#' Geocode a table with addresses
#'
#' @param addressTable (data.frame) A table with a column of addresses prepared 
#'                                  for the Degauss geocoder. Addresses must be
#'                                  formatted such as "123 Main Street Boston MA 02108"
#'                                  See https://degauss.org/using_degauss.html#Geocoding
#'                                  for more detailed information on input address
#'                                  formatting
#'
#' @return (data.frame) The original input table with columns lat and lon
#'                      instead of the address column
#' 
#' @examples
#' dontrun
#' {
#'   geocodeAddresses(addressTable = cohortWithAddresses)
#' }
#'
#' @export
#' 
geocodeAddresses <- function(addressTable) {
  # TODO decision must be made on:
  # TODO  - which add'l columns should be returned (matched_*, score, precision)
  # TODO  - If there should be a minimum cutoff score
  readr::write_csv(addressTable, paste0(tempdir(), '\\add.csv'))
  system(paste0('docker run --rm -v ', tempdir(), ':/tmp ghcr.io/degauss-org/geocoder:3.3.0 add.csv'))
  rawGeocodedTable <- readr::read_csv(paste0(tempdir(), '\\add_geocoder_3.3.0_score_threshold_0.5.csv'))
  file.remove(paste0(tempdir(), '\\add.csv'))
  file.remove(paste0(tempdir(), '\\add_geocoder_3.3.0_score_threshold_0.5.csv'))  
  geocodedTable <- sf::st_as_sf(rawGeocodedTable, coords = c("lon", "lat"), crs = 4326)
  geocodedTable %>%
    dplyr::select(COHORT_DEFINITION_ID,
                  SUBJECT_ID,
                  COHORT_START_DATE,
                  COHORT_END_DATE,
                  geometry)
}


#' Import a geocoded cohort table to gaiaDB
#'
#' @param gaiaConnectionDetails For connecting to gaiaDB. An object of class
#'                              connectionDetails as created by the
#'                              createConnectionDetails function
#' @param cohort (data.frame) An OHDSI cohort table with a POINT geometry column
#'                            named geometry 
#' @param overwrite (boolean) Overwrite existing tables in the cohort schema?
#'
#' @return A new cohort table in the gaiaDB cohort schema
#'
#' @examples
#' 
#' importCohortTable(gaiaConnectionDetails = gaiaConnectionDetails,
#'                   cohort = geocodedCohort,
#'                   overwrite = FALSE)
#' 
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






