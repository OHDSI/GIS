#TODO the purpose of this function is to call all functions involved in geocoding
# addresses from an OMOP CDM and inserting into gaiaDB

loadAddresses <- function(gaiaConnectionDetails, cdmConnectionDetails, cdmDatabaseSchema) {
  
  # Ingest the location table from OMOP CDM and return a transformed location table
  
  transformedLocation <- getLocationAddresses(connectionDetails = cdmConnectionDetails,
                                              cdmDatabaseSchema = cdmDatabaseSchema)
  
  # Split transformedLocation into two tables: the already-geocoded rows (contains
  # lat and lon columns and values in the CDM) and those that need to be geocoded
  
  splitResult <- splitAddresses(addressTable = transformedLocation)
  
  alreadyGeocodedLocation <- splitResult$geocoded
  
  notGeocodedLocation <- splitResult$ungeocoded
  
  # Geocode addresses
  
  # TODO if (nrow(notGeocodedLocation) > 0) { } / if (!is.null(notGeocodedLocation)) { }
  
  geocodedLocation <- geocodeAddresses(addressTable = notGeocodedLocation)
  
  # Rebuild fully geocoded table
  
  fullyGeocodedLocation <- geocodedLocation
  if (!is.null(alreadyGeocodedLocation)) {
    names(alreadyGeocodedLocation) <- tolower(names(alreadyGeocodedLocation))
    alreadyGeocodedLocation <- dplyr::mutate(alreadyGeocodedLocation, lat = latitude, lon = longitude)
    alreadyGeocodedLocation <- dplyr::select(alreadyGeocodedLocation, names(fullyGeocodedLocation))
    alreadyGeocodedLocation <- sf::st_as_sf(boundGeocodedTable, coords = c("lon", "lat"), crs = 4326)
    fullyGeocodedLocation <- rbind(fullyGeocodedLocation, alreadyGeocodedLocation)
  }
  
  # Import geocoded location table to gaiaDB
  
  importLocationTable(gaiaConnectionDetails = gaiaConnectionDetails,
                      location = fullyGeocodedLocation)
  
  # Index omop.geom_omop_location
  
  createGeomOmopLocationIndex(connectionDetails = gaiaConnectionDetails)
  
}