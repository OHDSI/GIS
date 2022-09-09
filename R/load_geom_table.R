load_geom_table <- function(conn, connectionDetails, ds_uuid) {

  ds_rec <- get_data_source_record(conn, ds_uuid)

  stage_data <- get_stage_data(ds_rec)

  spec_df <- create_spec_table(ds_rec$geom_spec)

  result_df <- standardize_staged_data(stage_data, spec_df)

  geom_index <- get_geom_index_by_ds_uuid(conn, ds_rec$data_source_uuid)


  # format for insert
  if (!"character" %in% class(result_df$geom_local_value)) {
    result_df$geom_local_value <- sf::st_as_binary(result_df$geom_local_value, EWKB = TRUE, hex = TRUE)
  }

  geom_template <- get_geom_template(conn)

  res <- plyr::rbind.fill(geom_template, result_df)

  res <- res[-1]

  res$geom_name <- iconv(res$geom_name, "latin1")

  create_geom_instance_table(conn, schema =  geom_index$table_schema, name = geom_index$table_name)

  # insert into geom table
  import_geom_table(connectionDetails, res, geom_index)
}





import_geom_table <- function(connectionDetails, stage_data, geom_index){

  data_size_gb <- utils::object.size(stage_data) / 1000000000

  message(paste0("Expect ", ceiling(2*2**floor(log(data_size_gb)/log(2))), " database inserts."))

  if(data_size_gb > 1) {
    print("divide and conquer")
    import_geom_table(connectionDetails, stage_data = stage_data[1:floor(nrow(stage_data)*.5),], geom_index)
    import_geom_table(connectionDetails, stage_data = stage_data[floor(nrow(stage_data)*.5)+1:nrow(stage_data),], geom_index)
  } else {

    # TODO could this be simpler if rewritten as sf::st_write? Did I already try that?
    serv <- strsplit(connectionDetails$server(), "/")[[1]]

    postgis_con <- RPostgreSQL::dbConnect("PostgreSQL",
                                          host = serv[1], dbname = serv[2],
                                          user = connectionDetails$user(),
                                          password = connectionDetails$password(),
                                          port = connectionDetails$port()
    )


    rpostgis::pgInsert(postgis_con,
                       name = c(geom_index$table_schema, paste0("geom_", geom_index$table_name)),
                       geom = "geom_local_value",
                       data.obj = stage_data)





    RPostgreSQL::dbDisconnect(postgis_con)
  }

}

# CREATE GEOM INSTANCE TABLE
create_geom_instance_table <- function(conn, schema, name) {
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS ", schema, ";"))
  DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ", schema,
                                            ".\"geom_", name, "\" (",
                                            "geom_record_id serial4 NOT NULL, ",
                                            "geom_name varchar NULL, ",
                                            "geom_source_coding varchar NULL, ",
                                            "geom_source_value varchar NULL, ",
                                            "geom_wgs84 ", "public.geometry NULL, ",
                                            "geom_local_epsg int4 NULL, ",
                                            "geom_local_value ", "public.geometry NULL, ",
                                            "CONSTRAINT geom_record_", create_name_string(name),
                                            "_pkey PRIMARY KEY (geom_record_id));"))
}
