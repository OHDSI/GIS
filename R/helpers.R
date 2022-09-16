
# CREATE THE SCHEMA STRING
createSchemaString <- function(rec) {
  paste0(rec$org_id, "_", rec$org_set_id) %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}

createNameString <- function(name) {
  name %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}

# GET FOREIGN KEY FOR ATTR_OF_GEOM_INDEX_ID
getForeignKeyGid <- function(conn, uuid) {
  geomIndex <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
  geomIndex[geomIndex$data_source_id == uuid,]$geom_index_id
}

# GET DATA SOURCE RECORD
getDataSourceRecord <- function(conn, dataSourceUuid){
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.data_source WHERE data_source_uuid = ", dataSourceUuid))
}


getGeomTemplate <- function(conn){
  DatabaseConnector::dbReadTable(conn, "backbone.geom_template")
}

getGeomIndexByDataSourceUuid <- function(conn, dataSourceUuid){
  DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE data_source_id = ", dataSourceUuid))
}

getAttrTemplate <- function(conn){
  DatabaseConnector::dbReadTable(conn, "backbone.attr_template")
}
