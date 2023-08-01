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
#' @param gaiaVersion The version of gaiaDB you are creating, e.g. 001
#' @return A character string containing postgresql DDL
#' @importFrom utils read.csv
#' @export
#' @examples
#' ddl <- createDdl("001")
#' pk <- createPrimaryKeys("001")
#' fk <- createForeignKeys("001")
createDdl <- function(gaiaVersion){
  
  gaiaTableCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "tableLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  gaiaFieldCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "fieldLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  
  tableSpecs <- read.csv(gaiaTableCsvLoc, stringsAsFactors = FALSE)
  gaiaSpecs <- read.csv(gaiaFieldCsvLoc, stringsAsFactors = FALSE)
  
  tableList <- subset(tableSpecs$gaiaTableName, tableSpecs$schema == 'gaia')
  
  sql_result <- c()
  sql_result <- c(paste0("-- DDL Specification for gaiaDB version ", gaiaVersion))
  for (tableName in tableList){
    fields <- subset(gaiaSpecs, gaiaTableName == tableName)
    fieldNames <- fields$gaiaFieldName
    
    sql_result <- c(sql_result, paste0("\n\nCREATE TABLE backbone.", tableName, " ("))
    
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
createPrimaryKeys <- function(gaiaVersion){
  
  # argument checks
  stopifnot(is.character(gaiaVersion), length(gaiaVersion) == 1, gaiaVersion %in% c("001"))
  
  gaiaFieldCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "fieldLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  gaiaSpecs <- read.csv(gaiaFieldCsvLoc, stringsAsFactors = FALSE)
  
  primaryKeys <- subset(gaiaSpecs, isPrimaryKey == "Yes" & gaiaTableName != "exposure_occurrence")
  pkFields <- primaryKeys$gaiaFieldName
  
  sql_result <- c(paste0("-- Primary Key Constraints for gaiaDB version ", gaiaVersion))
  for (pkField in pkFields){
    
    subquery <- subset(primaryKeys, gaiaFieldName==pkField)
    
    sql_result <- c(sql_result, paste0("\nALTER TABLE backbone.", subquery$gaiaTableName, " ADD CONSTRAINT xpk_", subquery$gaiaTableName, " PRIMARY KEY NONCLUSTERED (", subquery$gaiaFieldName , ");\n"))
    
  }
  return(paste0(sql_result, collapse = ""))
}

#' @describeIn createDdl createForeignKeys Returns a string containing the OHDSQL for creation of foreign keys in the OMOP CDM.
#' @export
createForeignKeys <- function(gaiaVersion){
  
  # argument checks
  stopifnot(is.character(gaiaVersion), length(gaiaVersion) == 1, gaiaVersion %in% c("001"))
  
  gaiaFieldCsvLoc <- system.file(file.path("csv", paste0("gaia", gaiaVersion, "fieldLevel.csv")), package = "gaiaCore", mustWork = TRUE)
  gaiaSpecs <- read.csv(gaiaFieldCsvLoc, stringsAsFactors = FALSE)
  
  foreignKeys <- subset(gaiaSpecs, isForeignKey == "Yes" & gaiaTableName != "exposure_occurrence")
  foreignKeys$key <- paste0(foreignKeys$gaiaTableName, "_", foreignKeys$gaiaFieldName)
  
  sql_result <- c(paste0("-- Foreign Key Constraints for gaiaDB version ", gaiaVersion))
  for (foreignKey in foreignKeys$key){
    
    subquery <- subset(foreignKeys, foreignKeys$key==foreignKey)
    
    sql_result <- c(sql_result, paste0("\nALTER TABLE backbone.", subquery$gaiaTableName, " ADD CONSTRAINT fpk_", subquery$gaiaTableName, "_", subquery$gaiaFieldName, " FOREIGN KEY (", subquery$gaiaFieldName , ") REFERENCES backbone.", subquery$fkTableName, " (", subquery$fkFieldName, ");\n"))
    
  }
  return(paste0(sql_result, collapse = ""))
}
