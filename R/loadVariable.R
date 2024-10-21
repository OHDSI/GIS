#' Loads a variable from a registered source into PostGIS as attr_X
#'
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
#' variableSourceRecord <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))
#'
#' attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", variableSourceRecord$data_source_uuid,";"))
#'
#' tableExists <- DatabaseConnector::existsTable(conn,
#'                                               attrIndex$database_schema,
#'                                               paste0("attr_", attrIndex$table_name))
#'
#' if (!tableExists) {
#'   message("Loading attr table dependency")
#'   loadVariable(connectionDetails = connectionDetails, variableSourceId)
#' }
#' }
#'
#' @export
#'

loadVariable <- function(connectionDetails, variableSourceId){

  # get variable
  variableSourceRecord <- getVariableSourceRecord(connectionDetails = connectionDetails,
                                           variableSourceId = variableSourceId)

  if(nrow(variableSourceRecord) == 0) {
    return(message(paste0("Variable ", variableSourceId," not found in the database.")))
  }
  # get attr_index
  attrIndexRecord <- getAttrIndexRecord(connectionDetails = connectionDetails,
                                        variableSourceId = variableSourceRecord$variable_source_id)

  # Prevents same variable from being loaded twice

  if(checkVariableExists(connectionDetails = connectionDetails,
                      attrIndexRecord$database_schema,
                      attrIndexRecord$table_name,
                      variableSourceRecord$variable_name)) {
    return(message("Variable already exists in the database."))
  }

  geomIndexRecord <- getGeomIndexRecord(connectionDetails = connectionDetails,
                                        dataSourceUuid = variableSourceRecord$geom_dependency_uuid)

  # get data_source_record
  dataSourceRecord <- getDataSourceRecord(connectionDetails = connectionDetails,
                                          dataSourceUuid = variableSourceRecord$data_source_uuid)
  
  # get stage data
  staged <- getStaged(dataSourceRecord)

  # for attr, remove geom
  if ("sf" %in% class(staged)) {
    staged <- sf::st_drop_geometry(staged)
  }

  # format table for insert

  stagedResult <- standardizeStaged(staged = staged, spec = variableSourceRecord$attr_spec)

  stagedResult$variable_source_record_id <- variableSourceRecord$variable_source_id

  # prepare for insert

  # Load geom_dependency if necessary
  geomTableExists <- checkTableExists(connectionDetails = connectionDetails,
                                      databaseSchema = geomIndexRecord$database_schema,
                                      tableName = paste0("geom_", geomIndexRecord$table_name))
  if (!geomTableExists) {
    message("Loading geom table dependency")
    loadGeometry(connectionDetails = connectionDetails,
                 dataSourceUuid = variableSourceRecord$geom_dependency_uuid)
  }

  # get mapping values from geom table
  stagedResult <- assignGeomIdToAttr(connectionDetails = connectionDetails,
                                     stagedResult = stagedResult,
                                     geomIndexId = attrIndexRecord$attr_of_geom_index_id)

  # stagedResult <- tmp
  # get attr template
  attrTemplate <- getAttrTemplate(connectionDetails = connectionDetails)
  
  names(attrTemplate) <- tolower(names(attrTemplate))

  stagedResult <- dplyr::select(stagedResult, which(names(stagedResult) %in% names(attrTemplate)))

  # append staging data to template format
  attrToIngest <- plyr::rbind.fill(attrTemplate, stagedResult)

  createAttrInstanceTable(connectionDetails = connectionDetails,
                          schema = attrIndexRecord$database_schema,
                          name = attrIndexRecord$table_name)

  # import
  importAttrTable(connectionDetails = connectionDetails,
                  attribute = attrToIngest,
                  attrIndex = attrIndexRecord)

}

