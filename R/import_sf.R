import_sf <- function(connectionDetails, feature_index_id) {

  conn <-  DatabaseConnector::connect(connectionDetails)

  feature_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.feature_index WHERE feature_index_id = ", feature_index_id))
  ds_rec <- get_data_source_record(conn, feature_df$data_source_uuid)
  attr_index_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", feature_df$data_source_uuid,";"))
  geom_index_df <- get_geom_index_by_ds_uuid(conn, ds_rec$geom_dependency_uuid)
  attr_table_string <- paste0(attr_index_df$table_schema, ".\"attr_", attr_index_df$table_name, "\"")
  geom_table_string <- paste0(geom_index_df$table_schema, ".\"geom_", geom_index_df$table_name, "\"")
  feature <- feature_df$feature_name

  table_exists <- DatabaseConnector::existsTable(conn,
                                                 attr_index_df$table_schema,
                                                 paste0("attr_", attr_index_df$table_name))

  if (!table_exists) {
    message("Loading attr table dependency")
    load_feature(conn, feature_index_id)
  }

  feature_exists_query <- paste0("select count(*) from ", attr_table_string,
                                 " where attr_source_value = '", feature,"'")

  feature_exists_result <- DatabaseConnector::querySql(conn, feature_exists_query)

  if (!feature_exists_result > 0) {
    message("Loading attr table dependency")
    load_feature(conn, feature_index_id)
  }

  base_query <- paste0("select * from ", attr_table_string,
                       " join ", geom_table_string,
                       " on ", attr_table_string, ".geom_record_id=", geom_table_string, ".geom_record_id",
                       " where ", attr_table_string, ".attr_source_value = '", feature,"'")

  num_records_query <- paste0("select count(*) from ", attr_table_string,
                              " join ", geom_table_string,
                              " on ", attr_table_string, ".geom_record_id=", geom_table_string, ".geom_record_id",
                              " where ", attr_table_string, ".attr_source_value = '", feature,"'")

  query_count_result <- DatabaseConnector::querySql(conn, num_records_query)
  row_count <- query_count_result$COUNT

  if (row_count <= 1001) {
    x <- sf::st_read(dsn = conn, query = base_query)
  } else {
    sf_base_query <- paste0(base_query, " limit 1")
    sf_base <- sf::st_read(dsn = conn, query = sf_base_query)
    for (i in 0:(row_count%/%1000)) {
      print(i)
      iter_query <- paste0(base_query, " limit 1000 offset ", i * 1000 + 1)
      sf_base <- rbind(sf_base, sf::st_read(dsn = conn, query = iter_query))
    }
  }
  disconnect(conn)

  return(sf_base)
}
