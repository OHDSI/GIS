#' Write gaiaDB DDL script
#'
#' Write the DDL to a SQL file. The SQL will be rendered (parameters replaced) and translated to the target SQL
#' dialect. By default the @cdmDatabaseSchema parameter is kept in the SQL file and needs to be replaced before
#' execution.
#'
#' @param gaiaVersion The version of the CDM you are creating, e.g. 5.3, 5.4
#' @param outputfolder The directory or folder where the SQL file should be saved.
#'
#' @export
#' 
writeDdl <- function(gaiaVersion, outputfolder) {
  
  # argument checks
  stopifnot(gaiaVersion %in% c("001"))

  if(missing(outputfolder)) {
    outputfolder <- file.path(getwd(), "inst", "ddl", gaiaVersion)  
  }
  
  if(!dir.exists(outputfolder)) dir.create(outputfolder, showWarnings = FALSE, recursive = TRUE)
  
  sql <- createDdl(gaiaVersion)
  sql <- SqlRender::render(sql = sql)
  sql <- SqlRender::translate(sql, targetDialect = "postgresql")
  
  filename <- paste("gaiadb", gaiaVersion, "ddl.sql", sep = "_")
  SqlRender::writeSql(sql = sql, targetFile = file.path(outputfolder, filename))
  invisible(filename)
}

#' @describeIn writeDdl writePrimaryKeys Write the SQL code that creates the primary keys to a file.
#' @export
writePrimaryKeys <- function(gaiaVersion, outputfolder) {
  
  # argument checks
  stopifnot(gaiaVersion %in% c("001"))

  if(missing(outputfolder)) {
    outputfolder <- file.path(getwd(), "inst", "ddl", gaiaVersion)  
  }
  
  if(!dir.exists(outputfolder)) dir.create(outputfolder, showWarnings = FALSE, recursive = TRUE)
  
  sql <- createPrimaryKeys(gaiaVersion)
  sql <- SqlRender::render(sql = sql)
  sql <- SqlRender::translate(sql, targetDialect = "postgresql")
  
  filename <- paste("gaiadb", gaiaVersion, "primary", "keys.sql", sep = "_")
  SqlRender::writeSql(sql = sql, targetFile = file.path(outputfolder, filename))
  invisible(filename)
}

#' @describeIn writeDdl writeForeignKeys Write the SQL code that creates the foreign keys to a file.
#' @export
writeForeignKeys <- function(gaiaVersion, outputfolder) {
  
  # argument checks
  stopifnot(gaiaVersion %in% c("001"))

  if(missing(outputfolder)) {
    outputfolder <- file.path(getwd(), "inst", "ddl", gaiaVersion)  
  }
  
  if(!dir.exists(outputfolder)) dir.create(outputfolder, showWarnings = FALSE, recursive = TRUE)
  
  sql <- createForeignKeys(gaiaVersion)
  sql <- SqlRender::render(sql = sql)
  sql <- SqlRender::translate(sql, targetDialect = "postgresql")
  
  filename <- paste("gaiadb", gaiaVersion, "constraints.sql", sep = "_")
  SqlRender::writeSql(sql = sql, targetFile = file.path(outputfolder, filename))
  invisible(filename)
}
