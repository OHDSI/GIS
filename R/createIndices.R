# CREATE GEOM AND ATTR INDICES FROM DATA SOURCES
#TODO is uuids is null, run get_uids and create_indices for all
createIndices <-  function(connectionDetails, uuids) {
  conn <- DatabaseConnector::connect(connectionDetails)
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
        geomDependency <- createGeomIndexRecord(getDataSourceRecord(conn, record$geom_dependency_uuid))
        # insert into db
      }
      # create attr index record
      # TODO does this need to assign a variable?
      attrRecord <- createAttrIndexRecord(conn, record)
      DatabaseConnector::disconnect(conn)
    }
  })
}

# CREATE GEOM_INDEX RECORD
createGeomIndexRecord <- function(conn, rec) {

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

# CREATE ATTR_INDEX RECORD
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


# TODO get_uuids serves one purpose: a helper to create_indices for when you
# want to index every entry in the datascoure table. Instead consider:
# TODO delete get_uuids
# TODO allow create_indices to take argument "all" to uuids (or bool arg)
# to signify all uuids should be indexed

get_uuids <- function() {
  conn <- connect(connectionDetails)
  data_source <- DatabaseConnector::dbReadTable(conn, "backbone.data_source")
  disconnect(conn)
  return(data_source$data_source_uuid)
}
