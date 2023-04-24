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
