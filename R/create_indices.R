# CREATE GEOM AND ATTR INDICES FROM DATA SOURCES
#TODO is uuids is null, run get_uids and create_indices for all
create_indices <-  function(connectionDetails, uuids) {
  conn <- DatabaseConnector::connect(connectionDetails)
  lapply(uuids, function(id) {
    record <- get_data_source_record(conn, id)

    #GET GEOM AND ATTR INDEX (SCHEMA SPECIFIC)
    geom_index <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
    geom_index_data_source_ids <- geom_index$data_source_id

    attr_index <- DatabaseConnector::dbReadTable(conn, "backbone.attr_index")
    attr_index_data_source_ids <- attr_index$data_source_id

    # IF record type geom AND not in gidsid then create geom index record
    if (record$geom_type != "" & !id %in% geom_index_data_source_ids) {
      gi_record <- create_geom_index_record(conn, record)
    }
    # IF attr AND not in aidsid check dependency
    if (record$has_attributes == 1 & !id %in% attr_index_data_source_ids) {

      ## IF geom dependency AND dependency not in gidsid then create geom index record AND insert into db
      if (!is.na(record$geom_dependency_uuid) & !record$geom_dependency_uuid %in% geom_index_data_source_ids) {
        gi_dependency <- create_geom_index_record(get_data_source_record(conn, record$geom_dependency_uuid))
        # insert into db
      }
      # create attr index record
      attr_record <- create_attr_index_record(conn, record)
      disconnect(conn)
    }
  })
}

# CREATE GEOM_INDEX RECORD
create_geom_index_record <- function(conn, rec) {

  index_record <- tibble::tibble(
    data_type_id = "NULL",
    data_type_name = rec$geom_type,
    geom_type_concept_id = "NULL",
    geom_type_source_value = rec$boundary_type,
    table_schema = create_schema_string(rec),
    table_name = rec$dataset_name,
    table_desc = paste(rec$org_id, rec$org_set_id, rec$dataset_name),
    data_source_id = rec$data_source_uuid)

  insert_logic <- paste0("INSERT INTO backbone.geom_index ",
                         "(data_type_id, data_type_name, geom_type_concept_id, ",
                         "geom_type_source_value, table_schema, table_name, table_desc, ",
                         "data_source_id) VALUES ('",
                         paste(index_record %>% slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                         "');") %>%
    stringr::str_replace_all("'NULL'", "NULL")

  DatabaseConnector::executeSql(conn, insert_logic)
}

# CREATE ATTR_INDEX RECORD
create_attr_index_record <- function(conn, rec) {
  index_record <- tibble::tibble(
    attr_of_geom_index_id = get_foreign_key_gid(conn, rec$geom_dependency_uuid),
    table_schema = create_schema_string(rec),
    table_name = rec$dataset_name,
    data_source_id = rec$data_source_uuid)

  insert_logic <- paste0("INSERT INTO backbone.attr_index ",
                         "(attr_of_geom_index_id, table_schema, table_name, data_source_id) ",
                         "VALUES ('",
                         paste(index_record %>% dplyr::slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                         "');") %>%
    stringr::str_replace_all("'NULL'", "NULL")

  DatabaseConnector::executeSql(conn, insert_logic)
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
