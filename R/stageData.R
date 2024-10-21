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

getStaged <- function(rec, storageConfig = readStorageConfig()) {
  # ONLY HANDLES FILES (NO API YET)
  # TODO there has to be a different way to change timeout without changing options
  
  isPersisted <- storageConfig$offline_storage$persist_data
  storageDir <- file.path(storageConfig$offline_storage$directory, rec$dataset_name)
  gisTempDir <- file.path(tempdir(), 'gaia')
  
  if (!dir.exists(gisTempDir)) {
    dir.create(gisTempDir)
  }

  baseTimeout <- getOption('timeout')
  options(timeout = 600)
  on.exit(options(timeout = baseTimeout))
  
  if (rec$download_method == "local") {
    message("Loading locally hosted dataset...")
    if(!dir.exists(storageDir) || !file.exists(file.path(storageDir, rec$download_url))) {
      msg <- paste0("You are trying to load source data of type \"local\",\nbut no local dataset was found.\nPlease ensure that the directory you specified for external\nstorage in the config file:\n(", storageDir,")\nexists and contains the source data for this variable (", rec$download_url,").\nFor information about obtaining this source dataset, visit\n", rec$documentation_url)
      stop(msg, call. = T)
    }
    
    return(readFromZip(zipfile = file.path(storageDir, rec$download_url),
                       exdir = gisTempDir,
                       rec = rec))
  }
  
  if (rec$download_method == "file") {
    if (rec$download_subtype == "zip") {
      if(isTRUE(storageDir)) { # If there is no config file or no storageDir set, this can be skipped
      # If the storage directory exists, assume zip file must be there
        if(dir.exists(storageDir)) {
          message("Skipping download (zip file located on disk) ...")
          return(readFromZip(zipfile = file.path(storageDir, rec$download_url),
                      exdir = gisTempDir,
                      rec = rec))
        }
        
        # If the storage directory does not exist, but isPersisted is True, create storageDirectory and save zip there
        if(isPersisted && !dir.exists(storageDir)) {
          dir.create(storageDir)
          zipfile <- file.path(storageDir, basename(rec$download_url))
          # TODO use a try-catch: 
          # If download fails, delete storageDir entirely
          utils::download.file(url = rec$download_url, destfile = zipfile)
          return(readFromZip(zipfile = zipfile, exdir = gisTempDir, rec = rec))
        }
      }
    
      tempzip <- file.path(gisTempDir, basename(rec$download_url))
      if (!file.exists(tempzip)) {
        utils::download.file(rec$download_url, tempzip)
      } else {
        message("Skipping download (zip file located on disk) ...")
      }
      return(readFromZip(zipfile = tempzip, exdir = gisTempDir, rec = rec))

    } else if (rec$download_subtype == "tar" | rec$download_subtype == "tar.gz" ) { 
      # copied from above, much optimization to do in all of this ...

      if(isTRUE(storageDir)) { # If there is no config file or no storageDir set, this can be skipped
      # If the storage directory exists, assume tar file must be there
        if(dir.exists(storageDir)) {
          message("Skipping download (tar file located on disk) ...")
          return(readFromTar(tarfile = file.path(storageDir, rec$download_url),
                      exdir = gisTempDir,
                      rec = rec))
        }
        
        # If the storage directory does not exist, but isPersisted is True, create storageDirectory and save tip there
        if(isPersisted && !dir.exists(storageDir)) {
          dir.create(storageDir)
          tarfile <- file.path(storageDir, basename(rec$download_url))
          # TODO use a try-catch: 
          # If download fails, delete storageDir entirely
          utils::download.file(url = rec$download_url, destfile = tarfile)
          return(readFromTar(tarfile = tarfile, exdir = gisTempDir, rec = rec))
        }
      }
    
      temptar <- file.path(gisTempDir, basename(rec$download_url))
      if (!file.exists(temptar)) {
        utils::download.file(rec$download_url, temptar)
      } else {
        message("Skipping download (tarfile located on disk) ...")
      }
      return(readFromTar(tarfile = temptar, exdir = gisTempDir, rec = rec))

    }
  } 
}


#' Read config.yml file from inst
#'
#' @return (list) User-defined storage configuration
#' 

readStorageConfig <- function() {
  yaml::read_yaml(system.file('config/storage.yml', package = 'gaiaCore'))
}




#' Unzip and read contents of a zipfile into R memory
#'
#' @param zipfile (character) path to the compressed file
#' @param exdir (character) path to where contents of the compressed file should be extracted
#' @param rec (data.frame) A full record (entire row) from the backbone.data_source table corresponding to the data source of interest. Usually created using \code{getDataSourceRecord} function
#'
#' @return (data.frame) An untransformed version of the source data
#'

readFromZip <- function(zipfile, exdir, rec) {
  utils::unzip(zipfile, exdir=exdir)
  if (rec$download_data_standard %in% list('shp','gdb')) {
    return(sf::st_read(file.path(exdir, rec$download_filename)))
  } else if (rec$download_data_standard == 'csv') {
    return(utils::read.csv(file = file.path(exdir, rec$download_filename),
                           check.names = FALSE))
  } else {
    message(paste0("no import handler for",rec$download_data_standard))
  }
}


#' Unrar and read contents of a rar file into R memory
#'
#' @param rarfile (character) path to the compressed file
#' @param exdir (character) path to where contents of the compressed file should be extracted
#' @param rec (data.frame) A full record (entire row) from the backbone.data_source table corresponding to the data source of interest. Usually created using \code{getDataSourceRecord} function
#'
#' @return (data.frame) An untransformed version of the source data
#'

readFromTar <- function(tarfile, exdir, rec) {
  utils::untar(tarfile, exdir=exdir)
  if (rec$download_data_standard %in% list('shp','gdb')) {
    return(sf::st_read(file.path(exdir, rec$download_filename)))
  } else if (rec$download_data_standard == 'csv') {
    return(utils::read.csv(file = file.path(exdir, rec$download_filename),
                           check.names = FALSE))
  } else {
    message(paste0("no import handler for",rec$download_data_standard))
  }
}
