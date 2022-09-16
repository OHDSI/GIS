importShapefile <- function(connectionDetails, featureIndexId) {

  conn <-  DatabaseConnector::connect(connectionDetails)

  featureTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.feature_index WHERE feature_index_id = ", featureIndexId))
  dataSourceRecord <- getDataSourceRecord(conn, featureTable$data_source_uuid)
  attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", featureTable$data_source_uuid,";"))
  geomIndex <- getGeomIndexByDataSourceUuid(conn, dataSourceRecord$geom_dependency_uuid)
  attrTableString <- paste0(attrIndex$table_schema, ".\"attr_", attrIndex$table_name, "\"")
  geomTableString <- paste0(geomIndex$table_schema, ".\"geom_", geomIndex$table_name, "\"")
  feature <- featureTable$feature_name

  tableExists <- DatabaseConnector::existsTable(conn,
                                                 attrIndex$table_schema,
                                                 paste0("attr_", attrIndex$table_name))

  if (!tableExists) {
    message("Loading attr table dependency")
    loadFeature(conn, connectionDetails, featureIndexId)
  }

  featureExistsQuery <- paste0("select count(*) from ", attrTableString,
                                 " where attr_source_value = '", feature,"'")

  featureExistsResult <- DatabaseConnector::querySql(conn, featureExistsQuery)

  if (!featureExistsResult > 0) {
    message("Loading attr table dependency")
    loadFeature(conn, featureIndexId)
  }

  baseQuery <- paste0("select * from ", attrTableString,
                       " join ", geomTableString,
                       " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                       " where ", attrTableString, ".attr_source_value = '", feature,"'")

  numberRecordsQuery <- paste0("select count(*) from ", attrTableString,
                              " join ", geomTableString,
                              " on ", attrTableString, ".geom_record_id=", geomTableString, ".geom_record_id",
                              " where ", attrTableString, ".attr_source_value = '", feature,"'")

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
