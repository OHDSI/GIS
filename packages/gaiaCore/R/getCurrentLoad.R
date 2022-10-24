#' Get summary table of all variables and associated geoms that are currently loaded
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#'
#' @return (data.frame) A variable source summary table with records of all currently loaded variables
#'
#' @examples
#'
#' currentLoadTable <- getCurrentLoad(connectionDetails = connectionDetails)
#'
#' @export
#'

getCurrentLoad <- function(connectionDetails) {
  attrIndex <- getAttrIndexTable(connectionDetails = connectionDetails)
  variableSource <- getVariableSourceTable(connectionDetails = connectionDetails)
  loadedVariables <- lapply(1:nrow(attrIndex), function(i) {
    attrTableExists <- checkTableExists(connectionDetails = connectionDetails,
                                        databaseSchema = attrIndex[i,]$database_schema,
                                        tableName = paste0("attr_", attrIndex[i,]$table_name))
    if(attrTableExists) {
      getUniqueVariablesInAttrX(
        connectionDetails = connectionDetails,
        databaseSchema = attrIndex[i,]$database_schema,
        tableName = paste0("attr_", attrIndex[i,]$table_name))
    }
  })
  getVariableSourceSummaryTable(connectionDetails = connectionDetails,
                                  variableSourceIds = unlist(loadedVariables))
}

