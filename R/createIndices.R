#' Create and populate backbone.geom_index and backbone.attr_index from registered sources in backbone.data_source
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return Two tables (backbone.geom_index and backbone.attr_index) in PostGIS
#'
#' @examples
#' \dontrun{
#' createIndices(connectionDetails = connectionDetails)
#' }
#'
#' @export
#'

createIndices  <-  function(connectionDetails) {
  dataSourceTable <- getDataSourceTable(connectionDetails = connectionDetails)
  uuids <- dataSourceTable$data_source_uuid
  geomIndexTable <- getGeomIndexTable(connectionDetails = connectionDetails)
  attrIndexTable <- getAttrIndexTable(connectionDetails = connectionDetails)

  for (id in uuids) {

    # getDataSource record from local table
    record <- dplyr::filter(dataSourceTable, data_source_uuid == id)

    # IF record type geom AND not in gidsid then create geom index record
    if (record$geom_type != "" & !is.na(record$geom_type) & !id %in% geomIndexTable$data_source_id) {
      geomIndexTable <- appendGeomIndexRecord(geomIndexTable = geomIndexTable,
                                              dataSourceRecord = record)
    }
    # IF attr AND not in aidsid check dependency
    if (record$has_attributes == 1 & !id %in% attrIndexTable$data_source_id) {
      ## IF geom dependency AND dependency not in gidsid then create geom index record AND insert into db
      if (!is.na(record$geom_dependency_uuid) &
          !record$geom_dependency_uuid %in% geomIndexTable$data_source_id &
          record$geom_dependency_uuid != record$data_source_uuid) {
        geomDependencyDataSourceRecord <- dplyr::filter(dataSourceTable,
                                                        data_source_uuid == record$geom_dependency_uuid)
        geomIndexTable <- appendGeomIndexRecord(geomIndexTable = geomIndexTable,
                                                dataSourceRecord = geomDependencyDataSourceRecord)
      }
      attrIndexTable <- appendAttrIndexRecord(attrIndexTable = attrIndexTable,
                                              geomIndexTable = geomIndexTable,
                                              dataSourceRecord = record)
    }
  }

  # LOAD index tables
  importAttrIndexTable(connectionDetails = connectionDetails,
                       attrIndexTable = attrIndexTable)
  importGeomIndexTable(connectionDetails = connectionDetails,
                       geomIndexTable = geomIndexTable)
}


#' Append a geom_index record to the geomIndexTable object
#'
#' @param geomIndexTable (data.frame) the existing geomIndexTable
#' @param dataSourceRecord (data.frame) A full record (entire row) from the backbone.data_source table
#'
#' @return (data.frame) updated geomIndexTable
#'

appendGeomIndexRecord <- function(geomIndexTable, dataSourceRecord) {
  if (nrow(geomIndexTable) == 0) {
    geom_index_id <- 1
  } else {
    geom_index_id <- max(geomIndexTable$geom_index_id) + 1
  }
  indexRecord <- dplyr::tibble(
    geom_index_id = geom_index_id,
    data_type_id = NULL,
    data_type_name = dataSourceRecord$geom_type,
    geom_type_concept_id = NULL,
    geom_type_source_value = dataSourceRecord$boundary_type,
    database_schema = createSchemaString(dataSourceRecord),
    table_name = createNameString(name = dataSourceRecord$dataset_name),
    table_desc = paste(dataSourceRecord$org_id, dataSourceRecord$org_set_id, dataSourceRecord$dataset_name),
    data_source_id = dataSourceRecord$data_source_uuid)
  dplyr::bind_rows(geomIndexTable, indexRecord)
}


#' Append a attr_index record to the attrIndexTable object
#'
#' @param attrIndexTable (data.frame) the existing attrIndexTable
#' @param geomIndexTable (data.frame) the existing geomIndexTable
#' @param dataSourceRecord (data.frame) A full record (entire row) from the backbone.data_source table
#'
#' @return (data.frame) updated attrIndexTable
#'

appendAttrIndexRecord <- function(attrIndexTable, geomIndexTable, dataSourceRecord) {
  if (nrow(attrIndexTable) == 0) {
    attr_index_id <- 1
  } else {
    attr_index_id <- max(attrIndexTable$attr_index_id) + 1
  }
  indexRecord <- dplyr::tibble(
    attr_index_id = attr_index_id,
    attr_of_geom_index_id = getAttrOfGeomIndexId(geomIndexTable = geomIndexTable,
                                                 dataSourceUuid = dataSourceRecord$geom_dependency_uuid),
    database_schema = createSchemaString(dataSourceRecord),
    table_name = createNameString(name = dataSourceRecord$dataset_name),
    data_source_id = dataSourceRecord$data_source_uuid)
  dplyr::bind_rows(attrIndexTable, indexRecord)
}


#' Get foreign key for attr_of_geom_index_id
#'
#' @param geomIndexTable (data.frame) the existing geomIndexTable
#' @param dataSourceUuid (UUID) The UUID for the data source that is registered in the backbone.data_source table
#'
#' @return (integer) Identifier for the corresponding backbone.geom_index entry
#'

getAttrOfGeomIndexId <- function(geomIndexTable, dataSourceUuid) {
  geomIndexTable[geomIndexTable$data_source_id == dataSourceUuid,]$geom_index_id
}
