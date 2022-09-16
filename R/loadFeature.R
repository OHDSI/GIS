loadFeature <- function(conn, connectionDetails, featureIndexId){

  # get feature
  featureTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.feature_index WHERE feature_index_id = ", featureIndexId))

  # get attr_index
  attrIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", featureTable$data_source_uuid,";"))

  # get data_source_record
  dataSourceRecord <- getDataSourceRecord(conn, featureTable$data_source_uuid)

  geomIndex <- getGeomIndexByDataSourceUuid(conn, dataSourceRecord$geom_dependency_uuid)

  # get stage data
  staged <- getStaged(dataSourceRecord)

  # for attr, remove geom
  if ("sf" %in% class(staged)) {
    staged <- sf::st_drop_geometry(staged)
  }

  ## format table for insert ----

  # create spec table
  specTable <- createSpecTable(featureTable$attr_spec)

  stagedResult <- standardizeStaged(staged, specTable)

  # prepare for insert

  # Load geom_dependency if necessary
  if (!DatabaseConnector::existsTable(conn, geomIndex$table_schema, paste0("geom_",geomIndex$table_name))) {
    message("Loading geom table dependency")
    loadGeomTable(conn, connectionDetails, dataSourceRecord$geom_dependency_uuid)
  }

  # get mapping values from geom table
  stagedResult <- assignGeomIdToAttr(conn, stagedResult, attrIndex$attr_of_geom_index_id)

  # stagedResult <- tmp
  # get attr template
  attrTemplate <- getAttrTemplate(conn)

  # append staging data to template format
  attrToIngest <- plyr::rbind.fill(attrTemplate, stagedResult)

  createAttrInstanceTable(conn, schema = attrIndex$table_schema, name = attrIndex$table_name)

  # import
  importAttrTable(conn, attrToIngest, attrIndex)

}



importAttrTable <- function(conn, attribute, attrIndex){

  #TODO is this insertTableName doing anything?
  insertTableName <- paste0("\"", attrIndex$table_schema, "\"", "." ,"\"attr_", attrIndex$table_name, ".\"")

  attribute <- dplyr::select(attribute, -"attr_record_id")

  DatabaseConnector::insertTable(conn,
                                 databaseSchema = paste0("\"",attrIndex$table_schema,"\""),
                                 tableName = paste0("\"attr_",attrIndex$table_name,"\""),
                                 data = attribute,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE
  )

}


createAttrInstanceTable <- function(conn, schema, name) {
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS ", schema, ";"))
  DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                            ".\"attr_", name, "\" (",
                                            "attr_record_id serial4 NOT NULL, ",
                                            "geom_record_id int4 NULL, ",
                                            "attr_concept_id int4 NULL, ",
                                            "attr_start_date date NULL, ",
                                            "attr_end_date date NULL, ",
                                            "value_as_number float8 NULL, ",
                                            "value_as_string varchar NULL, ",
                                            "value_as_concept_id int4 NULL, ",
                                            "unit_concept_id int4 NULL, ",
                                            "unit_source_value varchar NULL, ",
                                            "qualifier_concept_id int4 NULL, ",
                                            "qualifier_source_value varchar NULL, ",
                                            "attr_source_concept_id int4 NULL, ",
                                            "attr_source_value varchar NULL, ",
                                            "value_source_value varchar NULL, ",
                                            "CONSTRAINT attr_record_", createNameString(name),
                                            "_pkey PRIMARY KEY (attr_record_id));"))
}


getGeomIdMap <- function(conn, geomIndex){
  geomIndex <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE geom_index_id = ", geomIndex,";"))

sqlQuery <- paste0(
    "SELECT geom_record_id, geom_source_value FROM "
    , geomIndex$table_schema
    ,".\"geom_"
    , geomIndex$table_name
    ,'\";'
  )
  DatabaseConnector::dbGetQuery(conn, sqlQuery)
}

assignGeomIdToAttr <- function(conn, stagedResult, geomIndex){

  geomIdMap <- getGeomIdMap(conn, geomIndex)

  tmp <- merge(x = stagedResult, y= geomIdMap, by.x = "geom_join_column", by.y = "geom_source_value")

  tmp <- dplyr::select(tmp, -"geom_join_column")

  return(tmp)

}
