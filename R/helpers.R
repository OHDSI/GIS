
# CREATE THE SCHEMA STRING
create_schema_string <- function(rec) {
  paste0(rec$org_id, "_", rec$org_set_id) %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}

create_name_string <- function(name) {
  name %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}

# GET FOREIGN KEY FOR ATTR_OF_GEOM_INDEX_ID
get_foreign_key_gid <- function(conn, uuid) {
  geom_index <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
  geom_index[geom_index$data_source_id == uuid,]$geom_index_id
}

# GET DATA SOURCE RECORD
get_data_source_record <- function(conn, ds_uuid){
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.data_source WHERE data_source_uuid = ", ds_uuid))
}


get_geom_template <- function(conn){
  DatabaseConnector::dbReadTable(conn, "backbone.geom_template")
}

get_geom_index_by_ds_uuid <- function(conn, ds_uuid){
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE data_source_id = ", ds_uuid))
}

get_attr_template <- function(conn){
  DatabaseConnector::dbReadTable(conn, "backbone.attr_template")
}
