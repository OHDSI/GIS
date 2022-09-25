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
