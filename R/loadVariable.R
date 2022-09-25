#' Loads a variable from a registered source into PostGIS as attr_X
#'
#' @param conn (DatabaseConnectorJdbcConnection) A database connection object created with \code{DatabaseConnector::connect} function
#' @param connectionDetails (list) An object of class connectionDetails as created by the createConnectionDetails function
#' @param variableSourceId (integer) The identifier for the variable that is registered in the PostGIS variable_source table
#'
#' @return A table (attr_X) in PostGIS
#'
#' @examples
#' \dontrun{
#'
#' variableSourceId <- 157
#'
#' variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))
#'
#' attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", variableTable$data_source_uuid,";"))
#'
#' tableExists <- DatabaseConnector::existsTable(conn,
#'                                               attrIndex$table_schema,
#'                                               paste0("attr_", attrIndex$table_name))
#'
#' if (!tableExists) {
#'   message("Loading attr table dependency")
#'   loadVariable(conn = conn, connectionDetails = connectionDetails, variableSourceId)
#' }
#' }
#'
#' @export
#'

# TODO conn: remove conn as a parameter (once variableSource fun created)
loadVariable <- function(conn, connectionDetails, variableSourceId){

  # get variable
  # TODO conn: replace with fun (once created)
  # TODO rename as variableSourceTable
  variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))

  # get attr_index
  attrIndexRecord <- getAttrIndexRecord(connectionDetails = connectionDetails,
                                        dataSourceUuid = variableTable$data_source_uuid)

  # get data_source_record
  dataSourceRecord <- getDataSourceRecord(connectionDetails = connectionDetails,
                                          dataSourceUuid = variableTable$data_source_uuid)

  geomIndexRecord <- getGeomIndexRecord(connectionDetails = connectionDetails,
                                        dataSourceUuid = dataSourceRecord$geom_dependency_uuid)

  # get stage data
  staged <- getStaged(dataSourceRecord)

  # for attr, remove geom
  if ("sf" %in% class(staged)) {
    staged <- sf::st_drop_geometry(staged)
  }

  ## format table for insert ----

  # create spec table
  specTable <- createSpecTable(variableTable$attr_spec)

  stagedResult <- standardizeStaged(staged, specTable)

  # prepare for insert

  # Load geom_dependency if necessary
  geomTableExists <- checkTableExists(connectionDetails = connectionDetails,
                                      databaseSchema = geomIndex$table_schema,
                                      tableName = paste0("geom_", geomIndex$table_name))
  if (!geomTableExists) {
    message("Loading geom table dependency")
    loadGeometry(connectionDetails = connectionDetails,
                 dataSourceUuid = dataSourceRecord$geom_dependency_uuid)
  }

  # get mapping values from geom table
  stagedResult <- assignGeomIdToAttr(connectionDetails = connectionDetails,
                                     stagedResult = stagedResult,
                                     geomIndex = attrIndex$attr_of_geom_index_id)

  # stagedResult <- tmp
  # get attr template
  attrTemplate <- getAttrTemplate(connectionDetails = connectionDetails)

  # append staging data to template format
  attrToIngest <- plyr::rbind.fill(attrTemplate, stagedResult)

  createAttrInstanceTable(connectionDetails = connectionDetails,
                          schema = attrIndex$table_schema,
                          name = attrIndex$table_name)

  # import
  importAttrTable(connectionDetails = connectionDetails,
                  attribute = attrToIngest,
                  attrIndex = attrIndex)

}

