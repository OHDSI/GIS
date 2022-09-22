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
  conn <- DatabaseConnector::connect(connectionDetails)

  if (is.null(uuids)) {
    data_source <- DatabaseConnector::dbReadTable(conn, "backbone.data_source")
    uuids <- data_source$data_source_uuid
  }

  lapply(uuids, function(id) {
    record <- getDataSourceRecord(conn, id)

    #GET GEOM AND ATTR INDEX (SCHEMA SPECIFIC)
    geomIndex <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
    geomIndexDataSourceIds <- geomIndex$data_source_id

    attrIndex <- DatabaseConnector::dbReadTable(conn, "backbone.attr_index")
    attrIndexDataSourceIds <- attrIndex$data_source_id

    # IF record type geom AND not in gidsid then create geom index record
    if (record$geom_type != "" & !id %in% geomIndexDataSourceIds) {
      # TODO does this need to assign a variable?
      geomRecord <- createGeomIndexRecord(conn, record)
    }
    # IF attr AND not in aidsid check dependency
    if (record$has_attributes == 1 & !id %in% attrIndexDataSourceIds) {

      ## IF geom dependency AND dependency not in gidsid then create geom index record AND insert into db
      if (!is.na(record$geom_dependency_uuid) & !record$geom_dependency_uuid %in% geomIndexDataSourceIds) {
        # TODO does this need to assign a variable?
        # TODO this NEEDS to receive conn as first arg or else won't work!!! Add it ASAP
        geomDependency <- createGeomIndexRecord(getDataSourceRecord(conn, record$geom_dependency_uuid))
        # insert into db
      }
      # create attr index record
      # TODO does this need to assign a variable?
      attrRecord <- createAttrIndexRecord(conn, record)
    }
  })
  DatabaseConnector::disconnect(conn)
}


#' Create a single record in the backbone.geom_index table
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param rec (data.frame) A full record (entire row) from the backbone.data_source table
#'
#' @return A new record in the backbone.geom_index table
#'
#' @examples
#' \dontrun{
#'
#' record <- getDataSourceRecord(conn = conn, dataSourceUuid = 1)
#'
#' createGeomIndexRecord(conn = conn, rec = record)
#' }
#'

createGeomIndexRecord <- function(conn, rec) {
  # TODO change

  indexRecord <- dplyr::tibble(
    data_type_id = "NULL",
    data_type_name = rec$geom_type,
    geom_type_concept_id = "NULL",
    geom_type_source_value = rec$boundary_type,
    table_schema = createSchemaString(rec),
    table_name = rec$dataset_name,
    table_desc = paste(rec$org_id, rec$org_set_id, rec$dataset_name),
    data_source_id = rec$data_source_uuid)

  insertLogic <- paste0("INSERT INTO backbone.geom_index ",
                         "(data_type_id, data_type_name, geom_type_concept_id, ",
                         "geom_type_source_value, table_schema, table_name, table_desc, ",
                         "data_source_id) VALUES ('",
                         paste(indexRecord %>% dplyr::slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                         "');") %>%
    stringr::str_replace_all("'NULL'", "NULL")

  DatabaseConnector::executeSql(conn, insertLogic)
}


#' Create a single record in the backbone.attr_index table
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param rec (data.frame) A full record (entire row) from the backbone.data_source table
#'
#' @return A new record in the backbone.attr_index table
#'
#' @examples
#' \dontrun{
#'
#' record <- getDataSourceRecord(conn = conn, dataSourceUuid = 9999)
#'
#' createAttrIndexRecord(conn = conn, rec = record)
#' }
#'

createAttrIndexRecord <- function(conn, rec) {
  indexRecord <- dplyr::tibble(
    attr_of_geom_index_id = getForeignKeyGid(conn, rec$geom_dependency_uuid),
    table_schema = createSchemaString(rec),
    table_name = rec$dataset_name,
    data_source_id = rec$data_source_uuid)

  insertLogic <- paste0("INSERT INTO backbone.attr_index ",
                         "(attr_of_geom_index_id, table_schema, table_name, data_source_id) ",
                         "VALUES ('",
                         paste(indexRecord %>% dplyr::slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                         "');") %>%
    stringr::str_replace_all("'NULL'", "NULL")

  DatabaseConnector::executeSql(conn, insertLogic)
}

