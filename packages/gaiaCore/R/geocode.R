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
  geocodedTable <- readr::read_csv(paste0(tempdir(), '\\add_geocoder_3.3.0_score_threshold_0.5.csv'))
  file.remove(paste0(tempdir(), '\\add.csv'))
  file.remove(paste0(tempdir(), '\\add_geocoder_3.3.0_score_threshold_0.5.csv'))  
  geocodedTable
}









