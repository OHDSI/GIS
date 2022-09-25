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

  # TODO conn: don't make the connection here
  conn <-  DatabaseConnector::connect(connectionDetails)

  #TODO rename variableTable to variableSourceRecord
  # TODO conn: replace with fun (once created)
  variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))
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
    # TODO conn: replace conn with connectionDetails (once ready)
    loadVariable(conn, connectionDetails, variableSourceId)
  }

  variableExists <- checkVariableExists(connectionDetails = connectionDetails,
                                        databaseSchema = attrIndex$table_schema,
                                        tableName = attrIndex$table_name,
                                        variableName = variable)

  if (!variableExists) {
    message("Loading attr table dependency")
    # TODO conn: remove conn as a arg (once variableSource fun created)
    loadVariable(conn, connectionDetails = connectionDetails,
                 variableSourceId = variableSourceId)
  }


  # TODO conn: replace with fun (once created)
  # args: connectionDetails, attrTableString, geomTableString, variable/variableName
  numberRecordsQuery <- paste0("select count(*) from ", attrTableString,
                              " join ", geomTableString,
                              " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                              " where ", attrTableString, ".attr_source_value = '", variable,"'")

  queryCountResult <- DatabaseConnector::querySql(conn, numberRecordsQuery)
  rowCount <- queryCountResult$COUNT


  baseQuery <- paste0("select * from ", attrTableString,
                       " join ", geomTableString,
                       " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                       " where ", attrTableString, ".attr_source_value = '", variable,"'")
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
