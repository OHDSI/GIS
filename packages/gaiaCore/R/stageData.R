#' Create a standardized version of the staged data that was imported from source
#'
#' @param staged (data.frame) Table of attributes that was imported from a source by \code{getStaged} function
#' @param spec (JSON) The attr_spec from the backbone.variable_source table or the geom_spec from backbone.data_source.
#'
#' @return (data.frame) A table standardized in the attr_template or geom_template mold
#'
#' @examples
#'
#' \dontrun{
#' stagedResult <- standardizeStaged(staged = staged, spec = variableTable$attr_spec)
#' }
#'

standardizeStaged <- function(staged, spec) {
  jsonSpec <- rjson::fromJSON(spec)
  transformCommands <-jsonSpec$stage_transform
  for (cmd in transformCommands) {
    staged <- eval(parse(text=cmd))

  }
  return(staged)
}


#' Download and import data from a web-hosted source
#'
#' @param rec (data.frame) A full record (entire row) from the backbone.data_source table corresponding to the data source of interest. Usually created using \code{getDataSourceRecord} function
#'
#' @return (data.frame) An untransformed version of the source data
#'
#' @examples
#'
#' \dontrun{
#' staged <- getStaged(dataSourceRecord)
#' }
#'

getStaged <- function(rec) {
  # ONLY HANDLES FILES (NO API YET)
  # TODO there has to be a different way to change timeout without changing options
  baseTimeout <- getOption('timeout')
  options(timeout = 600)
  if (rec$download_method == "file") {
    if (rec$download_subtype == "zip") {
      tempzip <- paste0(tempfile(), ".zip")
      utils::download.file(rec$download_url, tempzip)
      utils::unzip(tempzip, exdir = tempdir())
      if (rec$download_data_standard == 'shp') {
        return(sf::st_read(file.path(tempdir(), rec$download_filename)))
      } else if (rec$download_data_standard == 'csv') {
        return(utils::read.csv(file = file.path(tempdir(), rec$download_filename),
                               check.names = FALSE))
      }

    }
  }
  options(timeout = baseTimeout)
}
