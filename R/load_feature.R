load_feature <- function(conn, feature_index_id){

  # get feature
  feature_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.feature_index WHERE feature_index_id = ", feature_index_id))

  # get attr_index
  attr_index_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", feature_df$data_source_uuid,";"))

  # get data_source_record
  ds_rec <- get_data_source_record(conn, feature_df$data_source_uuid)

  geom_index_df <- get_geom_index_by_ds_uuid(conn, ds_rec$geom_dependency_uuid)

  # get stage data
  stage_data <- get_stage_data(ds_rec)

  # for attr, remove geom
  if ("sf" %in% class(stage_data)) {
    stage_data <- sf::st_drop_geometry(stage_data)
  }

  ## format table for insert ----

  # create spec table
  spec_df <- create_spec_table(feature_df$attr_spec)

  result_df <- standardize_staged_data(stage_data, spec_df)

  # prepare for insert

  # Load geom_dependency if necessary
  if (!existsTable(conn, geom_index_df$table_schema, paste0("geom_",geom_index_df$table_name))) {
    message("Loading geom table dependency")
    load_geom_table(conn, ds_rec$geom_dependency_uuid)
  }

  # get mapping values from geom table
  result_df <- assign_geom_id_to_attr(conn, result_df, attr_index_df$attr_of_geom_index_id)

  # result_df <- tmp
  # get attr template
  attr_template <- get_attr_template(conn)

  # append staging data to template format
  attr_to_ingest <- plyr::rbind.fill(attr_template, result_df)

  create_attr_instance_table(conn, schema = attr_index_df$table_schema, name = attr_index_df$table_name)

  # import
  import_attr_table(conn, attr_to_ingest, attr_index_df)

}



import_attr_table <- function(conn, df, attr_index_df){
  insert_table_name <- paste0("\"", attr_index_df$table_schema, "\"", "." ,"\"attr_", attr_index_df$table_name, ".\"")

  df <- subset(df, select = -c(attr_record_id))

  DatabaseConnector::insertTable(conn,
                                 databaseSchema = paste0("\"",attr_index_df$table_schema,"\""),
                                 tableName = paste0("\"attr_",attr_index_df$table_name,"\""),
                                 data = df,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE
  )

}


create_attr_instance_table <- function(conn, schema, name) {
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
                                            "CONSTRAINT attr_record_", create_name_string(name),
                                            "_pkey PRIMARY KEY (attr_record_id));"))
}


get_geom_id_map <- function(conn, geom_index_id){
  geom_index_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE geom_index_id = ", geom_index_id,";"))

  sql_query <- paste0(
    "SELECT geom_record_id, geom_source_value FROM "
    , geom_index_df$table_schema
    ,".\"geom_"
    , geom_index_df$table_name
    ,'\";'
  )
  DatabaseConnector::dbGetQuery(conn, sql_query)
}

assign_geom_id_to_attr <- function(conn, result_df, geom_index_id){

  geom_id_map <- get_geom_id_map(conn, geom_index_id)

  tmp <- merge(x = result_df, y= geom_id_map, by.x = "geom_join_column", by.y = "geom_source_value")

  tmp <- subset(tmp, select = -c(geom_join_column))

  return(tmp)

}
