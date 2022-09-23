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

  conn <-  DatabaseConnector::connect(connectionDetails)

  #TODO rename variableTable to variableSourceRecord
  variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))
  dataSourceRecord <- getDataSourceRecord(conn, variableTable$data_source_uuid)
  attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", variableTable$data_source_uuid,";"))
  geomIndex <- getGeomIndexByDataSourceUuid(conn, dataSourceRecord$geom_dependency_uuid)
  attrTableString <- paste0(attrIndex$table_schema, ".\"attr_", attrIndex$table_name, "\"")
  geomTableString <- paste0(geomIndex$table_schema, ".\"geom_", geomIndex$table_name, "\"")
  # TODO rename to variableName
  variable <- variableTable$variable_name

  tableExists <- DatabaseConnector::existsTable(conn,
                                                 attrIndex$table_schema,
                                                 paste0("attr_", attrIndex$table_name))

  if (!tableExists) {
    message("Loading attr table dependency")
    loadVariable(conn, connectionDetails, variableSourceId)
  }

  variableExistsQuery <- paste0("select count(*) from ", attrTableString,
                                 " where attr_source_value = '", variable,"'")

  variableExistsResult <- DatabaseConnector::querySql(conn, variableExistsQuery)

  if (!variableExistsResult > 0) {
    message("Loading attr table dependency")
    loadVariable(conn, variableSourceId)
  }

  baseQuery <- paste0("select * from ", attrTableString,
                       " join ", geomTableString,
                       " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                       " where ", attrTableString, ".attr_source_value = '", variable,"'")

  numberRecordsQuery <- paste0("select count(*) from ", attrTableString,
                              " join ", geomTableString,
                              " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                              " where ", attrTableString, ".attr_source_value = '", variable,"'")

  queryCountResult <- DatabaseConnector::querySql(conn, numberRecordsQuery)
  rowCount <- queryCountResult$COUNT

  if (rowCount <= 1001) {
    x <- sf::st_read(dsn = conn, query = baseQuery)
  } else {
    shapefileBaseQuery <- paste0(baseQuery, " limit 1")
    shapefileBase <- sf::st_read(dsn = conn, query = shapefileBaseQuery)
    for (i in 0:(rowCount%/%1000)) {
      print(i)
      iterativeQuery <- paste0(baseQuery, " limit 1000 offset ", i * 1000 + 1)
      shapefileBase <- rbind(shapefileBase, sf::st_read(dsn = conn, query = iterativeQuery))
    }
  }
  DatabaseConnector::disconnect(conn)

  return(shapefileBase)
}
