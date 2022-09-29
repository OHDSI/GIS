#' Create a standardized version of the staged data that was imported from source
#'
#' @param staged (data.frame) Table of attributes that was imported from a source by \code{getStaged} function
#' @param spec (JSON) The attr_spec from the backbone.variable_source table.
#'
#' @return (data.frame) A table standardized in the attr_template mold
#'
#' @examples
#'
#' \dontrun{
#' stagedResult <- standardizeStagedAttr(staged = staged, spec = variableTable$attr_spec)
#' }
#'
standardizeStagedAttr <- function(staged, attrSpec) {
  jsonSpec <- rjson::fromJSON(attrSpec)
  transformCommands <-jsonSpec$stage_transform
  for (cmd in transformCommands) {
    stagedResult <- staged <- eval(parse(text=cmd))
  }
  return(stagedResult)
}


#' Create a standardized version of the staged data that was imported from source
#'
#' @param staged (data.frame) Table of either attributes or geometries that was imported from a source by \code{getStaged} function
#' @param spec (JSON) The geom_spec from the backbone.data_source table.
#'
#' @return (data.frame) A table standardized in the geom_template mold
#'
#' @examples
#'
#' \dontrun{
#' stagedResult <- standardizeStagedGeom(staged = staged, spec = dataSourceRecord$geom_spec)
#' }
#'

standardizeStagedGeom <- function(staged, geomSpec) {
  jsonSpec <- rjson::fromJSON(geomSpec)
  specTable <- dplyr::tibble("t_name"=names(jsonSpec),
                "t_type"=unlist(lapply(t_name, function(x) jsonSpec[[x]]$type)),
                "t_value"=unlist(lapply(t_name, function(x) jsonSpec[[x]]$value)))

  if ('stage_transform' %in% specTable$t_name) {
    staged <- eval(parse(text=specTable[specTable$t_name == 'stage_transform',]$t_value))
    specTable <- specTable[!specTable$t_name == 'stage_transform',]
  }

  selectRules <- specTable[specTable$t_type == "select",]
  stagedResult <- staged[,selectRules$t_value] %>% as.data.frame()
  names(stagedResult) <- selectRules$t_name

  hardcodeRules <- specTable[specTable$t_type == "hardcode",]
  if (nrow(hardcodeRules) > 0){
    for(i in 1:nrow(hardcodeRules)){
      stagedResult[hardcodeRules$t_name[i]] <- hardcodeRules$t_value[i]
    }
  }

  rCodeRules <- specTable[specTable$t_type == "code",]
  if (nrow(rCodeRules) > 0){
    for(i in 1:nrow(rCodeRules)){
      stagedResult[rCodeRules$t_name[i]] <- eval(parse(text=rCodeRules$t_value[i]))
    }
  }

  return(stagedResult)
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
