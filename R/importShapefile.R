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
  # TODO rename as variableSourceRecord
  variableTable <- getVariableSourceRecord(connectionDetails = connectionDetails,
                                           variableSourceId = variableSourceId)
  dataSourceRecord <- getDataSourceRecord(connectionDetails = connectionDetails,
                                          dataSourceUuid = variableTable$data_source_uuid)
  # TODO rename attrIndexRecord
  attrIndex <- getAttrIndexRecord(connectionDetails = connectionDetails,
                                        dataSourceUuid = variableTable$data_source_uuid)
  # TODO rename geomIndexRecord
  geomIndex <- getGeomIndexRecord(connectionDetails = connectionDetails,
                                  dataSourceUuid = dataSourceRecord$geom_dependency_uuid)
  attrTableString <- paste0(attrIndex$table_schema, ".\"attr_", attrIndex$table_name, "\"")
  geomTableString <- paste0(geomIndex$table_schema, ".\"geom_", geomIndex$table_name, "\"")
  # TODO rename to variableName
  variable <- variableTable$variable_name

  tableExists <- checkTableExists(connectionDetails = connectionDetails,
                                  databaseSchema = attrIndex$table_schema,
                                  tableName = paste0("attr_", attrIndex$table_name))

  if (!tableExists) {
    message("Loading attr table dependency")
    loadVariable(connectionDetails = connectionDetails,
                 variableSourceId = variableSourceId)
  }

  variableExists <- checkVariableExists(connectionDetails = connectionDetails,
                                        databaseSchema = attrIndex$table_schema,
                                        tableName = attrIndex$table_name,
                                        variableName = variable)

  if (!variableExists) {
    message("Loading attr table dependency")
    loadVariable(connectionDetails = connectionDetails,
                 variableSourceId = variableSourceId)
  }


  handleShapefileImportJob(connectionDetails = connectionDetails,
                           attrTableString = attrTableString,
                           geomTableString = geomTableString,
                           variable = variable)
}
