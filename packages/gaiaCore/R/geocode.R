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
  # TODO suppress some or all of the Degauss messaging
  # TODO decision must be made on:
  # TODO  - which add'l columns should be returned (matched_*, score, precision)
  # TODO  - If there should be a minimum cutoff score
  # TODO allow user to specify minimum cutoff score?
  # TODO return list of location_ids/addresses that are NOT geocoded
  # TODO option to save locally?
  if (!any(stringr::str_detect(names(addressTable), 'address'))) {
    names(addressTable) <- tolower(names(addressTable))
  }
    # break addressTable into 100K row pieces
  chunksize = 100000
  n_chunks <- (nrow(addressTable) %/% chunksize) + 1
  if (n_chunks > 1) {
    message(paste0("Breaking table into ", n_chunks, " chunks..."))
  }
  tableParts <- lapply(1:n_chunks, function(i) {
    message(paste0("Geocoding chunk ", i, " of ", n_chunks))
    readr::write_csv(
      subset(addressTable[(chunksize * (i - 1)):(chunksize * i),], !is.na(address)),
      paste0(tempdir(), '\\add.csv'))
    system(paste0('docker run --rm -v ', tempdir(), ':/tmp ghcr.io/degauss-org/geocoder:3.3.0 add.csv'))
    rawGeocodedTablePart <- readr::read_csv(paste0(tempdir(), '\\add_geocoder_3.3.0_score_threshold_0.5.csv'))
    file.remove(paste0(tempdir(), '\\add.csv'))
    file.remove(paste0(tempdir(), '\\add_geocoder_3.3.0_score_threshold_0.5.csv'))
    successfulGeocodedTablePart <- subset(rawGeocodedTablePart, geocode_result == 'geocoded')
    successfulGeocodedTablePartSubset <- successfulGeocodedTablePart[, c(names(addressTable), "lat", "lon")]
  })
  boundGeocodedTable <- do.call(rbind, tableParts)
  finalGeocodedTable <- sf::st_as_sf(boundGeocodedTable, coords = c("lon", "lat"), crs = 4326)
  finalGeocodedTable
}

#' Split a table of addresses based on presence of coordinates
#'
#' @param addressTable (data.frame) A table of addresses. If there are not two columns
#'                                  named "LATITUDE" and "LONGITUDE", this function
#'                                  will just return this table as-is.
#'
#' @return (list) Two dataframes (geocoded and ungeocoded) inside of a list object.
#'                If there are not a LATITUDE and a LONGITUDE column, the original
#'                table of addresses is returned as the only item in the list.
#'
#' @examples
#' 
#' addressTable <- tibble::tibble(
#'   "LOCATION_ID" = 1:6,
#'   "ADDRESS" = c(
#'     "456 WOOD STREET  MALDEN MA 02148",                  
#'     "123 MAIN ST APT 111  BROOKLINE MA 02446",        
#'     "999 DUCK STREET WEYMOUTH MA 02188",
#'     "100 PRESIDENT STREET MILTON MA 02186",                
#'     "1 SOUTH AVE REVERE MA 02151",             
#'     "99 BEACH ROAD SOUTH DENNIS MA 02660"),
#'   "LATITUDE" = c(NA_real_, 22.2, NA_real_, NA_real_, 43.666, 75.6),
#'   "LONGITUDE" = c(33.3, NA_real_, NA_real_, NA_real_, 43.666, 75.6)
#'     )
#'     
#' results <- splitAddresses(addressTable)
#' 
#' results$ungeocoded # addresses and location_ids without prepopulated coordinates
#' results$geocoded # addresses and location_ids with prepopulated coordinates
#' 
#' @export
#' 

splitAddresses <- function(addressTable) {
  # TODO if table does not contain lat lon columns, do nothing
  if (!all(c("LATITUDE", "LONGITUDE") %in% names(addressTable))) {
    cat("No geocoded addresses")
    results <- list(ungeocoded = addressTable)
    return(results)
  }
  
  results <- list(
    geocoded = subset(addressTable, !is.na(LATITUDE) & !is.na(LONGITUDE)),
    ungeocoded = subset(addressTable, !(!is.na(LATITUDE) & !is.na(LONGITUDE)))
  )
  results
}
