#' Create the OHDSI-SQL Common Data Model DDL code
#'
#' The createDdl, createForeignKeys, and createPrimaryKeys functions each return a character string
#' containing their respective DDL SQL code in OHDSQL dialect for a specific CDM version.
#' The SQL they generate needs to be rendered and translated before it can be executed.
#'
#' The DDL SQL code is created from a two csv files that detail the OMOP CDM Specifications.
#' These files also form the basis of the CDM documentation and the Data Quality
#' Dashboard.
#'
#' @param cdmVersion The version of the CDM you are creating, e.g. 5.3, 5.4
#' @return A character string containing the OHDSQL DDL
#' @importFrom utils read.csv
#' @export
#' @examples
#' ddl <- createDdl("5.4")
#' pk <- createPrimaryKeys("5.4")
#' fk <- createForeignKeys("5.4")
createOccurrenceDdl <- function(gaiaVersion){
  
  gaiaTableCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "tableLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  gaiaFieldCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "fieldLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  
  tableSpecs <- read.csv(gaiaTableCsvLoc, stringsAsFactors = FALSE)
  gaiaSpecs <- read.csv(gaiaFieldCsvLoc, stringsAsFactors = FALSE)
  
  tableList <- subset(tableSpecs$gaiaTableName, tableSpecs$schema == 'gaiaResults')
  
  sql_result <- c()
  sql_result <- c(paste0("--@targetDialect DDL Specification for Gaia Results Exposure Occurrence ", gaiaVersion))
  for (tableName in tableList){
    fields <- subset(gaiaSpecs, gaiaTableName == tableName)
    fieldNames <- fields$gaiaFieldName
    
    if ('person_id' %in% fieldNames){
      query <- "\n\n--HINT DISTRIBUTE ON KEY (person_id)\n"
    } else {
      query <- "\n\n--HINT DISTRIBUTE ON RANDOM\n"
    }
    
    sql_result <- c(sql_result, query, paste0("CREATE TABLE @cdmDatabaseSchema.", tableName, " ("))
    
    n_fields <- length(fieldNames)
    for(fieldName in fieldNames) {
      
      if (subset(fields, gaiaFieldName == fieldName, isRequired) == "Yes") {
        nullable_sql <- (" NOT NULL")
      } else {
        nullable_sql <- (" NULL")
      }
      
      if (fieldName == fieldNames[[n_fields]]) {
        closing_sql <- (" );")
      } else {
        closing_sql <- (",")
      }
      
      if (fieldName=="offset") {
        field <- paste0('"',fieldName,'"')
      } else {
        field <- fieldName
      }
      fieldSql <- paste0("\n\t\t\t",
                         field," ",
                         subset(fields, gaiaFieldName == fieldName, gaiaDataType),
                         nullable_sql,
                         closing_sql)
      sql_result <- c(sql_result, fieldSql)
    }
    sql_result <- c(sql_result, "")
  }
  return(paste0(sql_result, collapse = ""))
}


#' @describeIn createDdl createPrimaryKeys Returns a string containing the OHDSQL for creation of primary keys in the OMOP CDM.
#' @export
createOccurrencePrimaryKeys <- function(gaiaVersion){
  
  # argument checks
  stopifnot(is.character(gaiaVersion), length(gaiaVersion) == 1, gaiaVersion %in% c("001"))
  
  gaiaFieldCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "fieldLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  gaiaSpecs <- read.csv(gaiaFieldCsvLoc, stringsAsFactors = FALSE)
  
  primaryKeys <- subset(gaiaSpecs, isPrimaryKey == "Yes" & gaiaTableName == "exposure_occurrence")
  pkFields <- primaryKeys$gaiaFieldName
  
  sql_result <- c(paste0("--@targetDialect CDM Primary Key Constraints for Gaia Results Exposure Occurrence ", gaiaVersion, "\n"))
  for (pkField in pkFields){
    
    subquery <- subset(primaryKeys, gaiaFieldName==pkField)
    
    sql_result <- c(sql_result, paste0("\nALTER TABLE @cdmDatabaseSchema.", subquery$gaiaTableName, " ADD CONSTRAINT xpk_", subquery$gaiaTableName, " PRIMARY KEY NONCLUSTERED (", subquery$gaiaFieldName , ");\n"))
    
  }
  return(paste0(sql_result, collapse = ""))
}

#' @describeIn createDdl createForeignKeys Returns a string containing the OHDSQL for creation of foreign keys in the OMOP CDM.
#' @export
createOccurrenceForeignKeys <- function(gaiaVersion){
  
  # argument checks
  stopifnot(is.character(gaiaVersion), length(gaiaVersion) == 1, gaiaVersion %in% c("001"))
  
  gaiaFieldCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "fieldLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  gaiaSpecs <- read.csv(gaiaFieldCsvLoc, stringsAsFactors = FALSE)
  
  foreignKeys <- subset(gaiaSpecs, isForeignKey == "Yes" & gaiaTableName == "exposure_occurrence")
  foreignKeys$key <- paste0(foreignKeys$gaiaTableName, "_", foreignKeys$gaiaFieldName)
  
  sql_result <- c(paste0("--@targetDialect CDM Foreign Key Constraints for Gaia Results Exposure Occurrence ", gaiaVersion, "\n"))
  for (foreignKey in foreignKeys$key){
    
    subquery <- subset(foreignKeys, foreignKeys$key==foreignKey)
    
    sql_result <- c(sql_result, paste0("\nALTER TABLE @cdmDatabaseSchema.", subquery$gaiaTableName, " ADD CONSTRAINT fpk_", subquery$gaiaTableName, "_", subquery$gaiaFieldName, " FOREIGN KEY (", subquery$gaiaFieldName , ") REFERENCES @cdmDatabaseSchema.", subquery$fkTableName, " (", subquery$fkFieldName, ");\n"))
    
  }
  return(paste0(sql_result, collapse = ""))
}



#' Write DDL script
#'
#' Write the DDL to a SQL file. The SQL will be rendered (parameters replaced) and translated to the target SQL
#' dialect. By default the @cdmDatabaseSchema parameter is kept in the SQL file and needs to be replaced before
#' execution.
#'
#' @param targetDialect  The dialect of the target database. Choices are "oracle", "postgresql", "pdw", "redshift", "impala", "netezza", "bigquery", "sql server",
#'                       "spark", "snowflake", "synapse"
#' @param cdmVersion The version of the CDM you are creating, e.g. 5.3, 5.4
#' @param outputfolder The directory or folder where the SQL file should be saved.
#' @param cdmDatabaseSchema The schema of the CDM instance where the DDL will be run. For example, this would be "ohdsi.dbo" when testing on sql server.
#'                          Defaults to "@cdmDatabaseSchema"
#'
#' @export
writeOccurrenceDdl <- function(targetDialect, gaiaVersion, outputfolder, cdmDatabaseSchema = "@cdmDatabaseSchema") {
  
  # argument checks
  stopifnot(targetDialect %in% c("oracle", "postgresql", "pdw", "redshift", "impala", "netezza", "bigquery", "sql server", "spark", "snowflake", "synapse"))
  stopifnot(gaiaVersion %in% c("001"))
  stopifnot(is.character(cdmDatabaseSchema))
  
  if(missing(outputfolder)) {
    outputfolder <- file.path(getwd(), "inst", "ddl", gaiaVersion, gsub(" ", "_", targetDialect))
  }
  
  if(!dir.exists(outputfolder)) dir.create(outputfolder, showWarnings = FALSE, recursive = TRUE)
  
  sql <- createOccurrenceDdl(gaiaVersion)
  sql <- SqlRender::render(sql = sql, cdmDatabaseSchema = cdmDatabaseSchema, targetDialect = targetDialect)
  sql <- SqlRender::translate(sql, targetDialect = targetDialect)
  
  filename <- paste("gaiaResults", gsub(" ", "_", targetDialect), gaiaVersion, "ddl.sql", sep = "_")
  SqlRender::writeSql(sql = sql, targetFile = file.path(outputfolder, filename))
  invisible(filename)
}

#' @describeIn writeDdl writePrimaryKeys Write the SQL code that creates the primary keys to a file.
#' @export
writeOccurrencePrimaryKeys <- function(targetDialect, gaiaVersion, outputfolder, cdmDatabaseSchema = "@cdmDatabaseSchema") {
  
  # argument checks
  stopifnot(targetDialect %in% c("oracle", "postgresql", "pdw", "redshift", "impala", "netezza", "bigquery", "sql server", "spark", "snowflake", "synapse"))
  stopifnot(gaiaVersion %in% c("001"))
  stopifnot(is.character(cdmDatabaseSchema))
  
  if(missing(outputfolder)) {
    outputfolder <- file.path(getwd(), "inst", "ddl", gaiaVersion, gsub(" ", "_", targetDialect))
  }
  
  if(!dir.exists(outputfolder)) dir.create(outputfolder, showWarnings = FALSE, recursive = TRUE)
  
  sql <- createOccurrencePrimaryKeys(gaiaVersion)
  sql <- SqlRender::render(sql = sql, cdmDatabaseSchema = cdmDatabaseSchema, targetDialect = targetDialect)
  sql <- SqlRender::translate(sql, targetDialect = targetDialect)
  
  filename <- paste("gaiaResults", gsub(" ", "_", targetDialect), gaiaVersion, "primary", "keys.sql", sep = "_")
  SqlRender::writeSql(sql = sql, targetFile = file.path(outputfolder, filename))
  invisible(filename)
}

#' @describeIn writeDdl writeForeignKeys Write the SQL code that creates the foreign keys to a file.
#' @export
writeOccurrenceForeignKeys <- function(targetDialect, gaiaVersion, outputfolder, cdmDatabaseSchema = "@cdmDatabaseSchema") {
  
  # argument checks
  stopifnot(targetDialect %in% c("oracle", "postgresql", "pdw", "redshift", "impala", "netezza", "bigquery", "sql server", "spark", "snowflake", "synapse"))
  stopifnot(gaiaVersion %in% c("001"))
  stopifnot(is.character(cdmDatabaseSchema))
  
  if(missing(outputfolder)) {
    outputfolder <- file.path(getwd(), "inst", "ddl", gaiaVersion, gsub(" ", "_", targetDialect))
  }
  
  if(!dir.exists(outputfolder)) dir.create(outputfolder, showWarnings = FALSE, recursive = TRUE)
  
  sql <- createOccurrenceForeignKeys(gaiaVersion)
  sql <- SqlRender::render(sql = sql, cdmDatabaseSchema = cdmDatabaseSchema, targetDialect = targetDialect)
  sql <- SqlRender::translate(sql, targetDialect = targetDialect)
  
  filename <- paste("gaiaResults", gsub(" ", "_", targetDialect), gaiaVersion, "constraints.sql", sep = "_")
  SqlRender::writeSql(sql = sql, targetFile = file.path(outputfolder, filename))
  invisible(filename)
}

#' @describeIn writeDdl writeIndex Write the rendered and translated sql that creates recommended indexes to a file.
#' @export
writeOccurrenceIndex <- function(targetDialect, gaiaVersion, outputfolder, cdmDatabaseSchema  = "@cdmDatabaseSchema") {
  
  # argument checks
  stopifnot(targetDialect %in% c("oracle", "postgresql", "pdw", "redshift", "impala", "netezza", "bigquery", "sql server", "spark", "snowflake", "synapse"))
  stopifnot(gaiaVersion %in% c("001"))
  stopifnot(is.character(cdmDatabaseSchema))
  
  if(missing(outputfolder)) {
    outputfolder <- file.path(getwd(), "inst", "ddl", gaiaVersion, gsub(" ", "_", targetDialect))
  }
  
  if(!dir.exists(outputfolder)) dir.create(outputfolder, showWarnings = FALSE, recursive = TRUE)
  
  sqlFilename <- paste0("gaiaResults_indices_v", gaiaVersion, ".sql")
  sql <- readr::read_file(system.file(file.path("sql", "sql_server", sqlFilename), package = "gaiaCore"))
  sql <- SqlRender::render(sql, targetDialect = targetDialect, cdmDatabaseSchema = cdmDatabaseSchema)
  sql <- SqlRender::translate(sql, targetDialect = targetDialect)
  
  filename <- paste("gaiaResults", gsub(" ", "_", targetDialect), gaiaVersion, "indices.sql", sep = "_")
  SqlRender::writeSql(sql = sql, targetFile = file.path(outputfolder, filename))
  invisible(filename)
}