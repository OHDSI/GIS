#' Create and populate backbone.geom_index and backbone.attr_index from registered sources in backbone.data_source
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param uuids (list) A list of UUIDs for the data sources that are registered in the backbone.data_source table. If uuids = NULL, resorts to creating indices from the entire data_source catalog (default behavior)
#'
#' @return Two tables (backbone.geom_index and backbone.attr_index) in PostGIS
#'
#' @examples
#' \dontrun{
#' createIndices(connectionDetails = connectionDetails, uuids = NULL)
#' }
#'
#' @export
#'

createIndices <-  function(connectionDetails, uuids = NULL) {
  if (is.null(uuids)) {
    dataSourceTable <- getDataSourceTable(connectionDetails = connectionDetails)
    uuids <- dataSourceTable$data_source_uuid
  }

  lapply(uuids, function(id) {
    record <- getDataSourceRecord(connectionDetails = connectionDetails,
                                  dataSourceUuid = id)

    #GET GEOM AND ATTR INDEX (SCHEMA SPECIFIC)
    # TODO rename geomIndex to geomIndexTable
    geomIndex <- getGeomIndexTable(connectionDetails = connectionDetails)
    geomIndexDataSourceIds <- geomIndex$data_source_id

    # TODO rename as attrIndexTable
    attrIndex <- getAttrIndexTable(connectionDetails = connectionDetails)
    attrIndexDataSourceIds <- attrIndex$data_source_id

    # IF record type geom AND not in gidsid then create geom index record
    if (record$geom_type != "" & !id %in% geomIndexDataSourceIds) {
      createGeomIndexRecord(connectionDetails = connectionDetails,
                            dataSourceRecord = record)
    }
    # IF attr AND not in aidsid check dependency
    if (record$has_attributes == 1 & !id %in% attrIndexDataSourceIds) {

      ## IF geom dependency AND dependency not in gidsid then create geom index record AND insert into db
      if (!is.na(record$geom_dependency_uuid) & !record$geom_dependency_uuid %in% geomIndexDataSourceIds) {
        geomDependencyDataSourceRecord <- getDataSourceRecord(
          connectionDetails = connectionDetails,
          dataSourceUuid = record$geom_dependency_uuid)
        createGeomIndexRecord(connectionDetails = connectionDetails,
                              dataSourceRecord = geomDependencyDataSourceRecord)
        # insert into db
      }
      # create attr index record
      createAttrIndexRecord(connectionDetails = connectionDetails,
                            dataSourceRecord = record)
    }
  })
}
