#' List OMOP CDM versions supported by this package
#'
#' Returns the list of OMOP Common Data Model versions for which the package provides DDL and constraint support.
#'
#' @return A character vector of supported CDM versions (e.g., "5.3", "5.4").
#' @export
listSupportedVersions <- function() {
  c("5.3", "5.4")
}

#' List SQL dialects supported by this package
#'
#' Returns the SQL dialects supported via SqlRender, which this package can use to generate dialect-specific DDL.
#'
#' @return A character vector of supported SQL dialects.
#' @export
listSupportedDialects <- function() {
  SqlRender::listSupportedDialects()$dialect
}
