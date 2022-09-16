# STANDARDIZE STAGED DATA
standardizeStaged <- function(staged, specTable) {
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

# GET STAGING DATA
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
        return(utils::read.csv(file.path(tempdir(), rec$download_filename)))
      }

    }
  }
  options(timeout = baseTimeout)
}



# CREATE SPEC TABLE
createSpecTable <- function(jsonStringSpec) {
  jsonSpec <- rjson::fromJSON(jsonStringSpec)
  dplyr::tibble("t_name"=names(jsonSpec),
                 "t_type"=unlist(lapply(t_name, function(x) jsonSpec[[x]]$type)),
                 "t_value"=unlist(lapply(t_name, function(x) jsonSpec[[x]]$value)))
}
