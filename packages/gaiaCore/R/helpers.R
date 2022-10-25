#' Create the schema and sanitize source values
#'
#' @param rec (data.frame) A full record (entire row) from the backbone.data_source table
#'
#' @return (character) Sanitized schema string
#'

createSchemaString <- function(rec) {
  paste0(rec$org_id, "_", rec$org_set_id) %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}


#' Sanitize and create table name from source values
#'
#' @param name (character) Table name source value
#'
#' @return (character) Sanitized table name string
#'

createNameString <- function(name) {
  name %>%
    tolower() %>%
    stringr::str_replace_all("\\W", "_") %>%
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}


#' Join a column of geom_X record identifiers to a staged attr_X table
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param stagedResult (data.frame) A table standardized in the attr_template or geom_template mold
#' @param geomIndexId (integer) Identifier of a record in the backbone.geom_index table. Usually sourced from the \code{attr_of_geom_index_id} entry of an attr_index record
#'
#' @return (data.frame) An updated \code{stagedResult} table with \code{geom_record_id}s corresponding to a geom_X table appended
#'

assignGeomIdToAttr <- function(connectionDetails, stagedResult, geomIndexId){
  geomIdMap <- getGeomIdMap(connectionDetails = connectionDetails,
                            geomIndexId = geomIndexId)

  tmp <- merge(x = stagedResult, y= geomIdMap, by.x = "geom_join_column", by.y = "geom_source_value")

  tmp <- dplyr::select(tmp, -"geom_join_column")

  return(tmp)

}
