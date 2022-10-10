#' Import an attribute-geometry pair from PostGIS
#'
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param variableSourceId (integer) The identifier for the variable that is registered in the PostGIS variable_source table
#'
#' @return (sf, data.frame) An sf object consisting of a single attribute and geometry; the result of joining attr_X and geom_X from the PostGIS
#'
#' @examples
#'
#' \dontrun{
#' shape <- importShapefile(connectionDetails = connectionDetails, variableSourceId = 157)
#' }
#'
#' @export
#'

importShapefile <- function(connectionDetails, variableSourceId) {
  variableSourceRecord <- getVariableSourceRecord(connectionDetails = connectionDetails,
                                           variableSourceId = variableSourceId)
  dataSourceRecord <- getDataSourceRecord(connectionDetails = connectionDetails,
                                          dataSourceUuid = variableSourceRecord$data_source_uuid)
  attrIndexRecord <- getAttrIndexRecord(connectionDetails = connectionDetails,
                                        dataSourceUuid = variableSourceRecord$data_source_uuid)
  geomIndexRecord <- getGeomIndexRecord(connectionDetails = connectionDetails,
                                  dataSourceUuid = dataSourceRecord$geom_dependency_uuid)
  attrTableString <- paste0(attrIndexRecord$table_schema, ".\"attr_", attrIndexRecord$table_name, "\"")
  geomTableString <- paste0(geomIndexRecord$table_schema, ".\"geom_", geomIndexRecord$table_name, "\"")
  variableName <- variableSourceRecord$variable_name
  tableExists <- checkTableExists(connectionDetails = connectionDetails,
                                  databaseSchema = attrIndexRecord$table_schema,
                                  tableName = paste0("attr_", attrIndexRecord$table_name))

  if (!tableExists) {
    message("Loading attr table dependency")
    loadVariable(connectionDetails = connectionDetails,
                 variableSourceId = variableSourceId)
  }

  variableExists <- checkVariableExists(connectionDetails = connectionDetails,
                                        databaseSchema = attrIndexRecord$table_schema,
                                        tableName = attrIndexRecord$table_name,
                                        variableName = variableName)

  if (!variableExists) {
    message("Loading attr table dependency")
    loadVariable(connectionDetails = connectionDetails,
                 variableSourceId = variableSourceId)
  }


  handleShapefileImportJob(connectionDetails = connectionDetails,
                           attrTableString = attrTableString,
                           geomTableString = geomTableString,
                           variableName = variableName)
}
