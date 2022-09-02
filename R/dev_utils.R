# CREATE THE SCHEMA STRING
create_schema_string <- function(rec) {
  paste0(rec$org_id, "_", rec$org_set_id) %>% 
    tolower() %>% 
    stringr::str_replace_all("\\W", "_") %>% 
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}

create_name_string <- function(name) {
  name %>% 
    tolower() %>% 
    stringr::str_replace_all("\\W", "_") %>% 
    stringr::str_remove_all("^_+|_+$|_(?=_)")
}

# GET FOREIGN KEY FOR ATTR_OF_GEOM_INDEX_ID
get_foreign_key_gid <- function(uuid) {
  geom_index <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
  geom_index[geom_index$data_source_id == uuid,]$geom_index_id
}

# CREATE GEOM INDEX TABLE
create_geom_index_table <- function(schema) {
  DatabaseConnector::dbExecute(conn, paste0("CREATE SCHEMA IF NOT EXISTS backbone;"))
  DatabaseConnector::dbExecute(conn, paste0("CREATE TABLE IF NOT EXISTS ",
                                            "backbone.geom_index (",
                                            "geom_index_id serial4 NOT NULL, ",
                                            "data_type_id int4 NULL, ",
                                            "data_type_name varchar NULL, ",
                                            "geom_type_concept_id int4 NULL, ",
                                            "geom_type_source_value varchar NULL, ",
                                            "table_schema varchar NULL, ",
                                            "table_name varchar NULL, ",
                                            "table_desc varchar NULL, ",
                                            "data_source_id int4 NULL, ",
                                            "CONSTRAINT geom_index_pkey PRIMARY KEY (geom_index_id));"))
}


# CREATE GEOM_INDEX RECORD
create_geom_index_record <- function(rec) {
  
  index_record <- tibble::tibble(
    data_type_id = "NULL",
    data_type_name = rec$geom_type,
    geom_type_concept_id = "NULL",
    geom_type_source_value = rec$boundary_type,
    table_schema = create_schema_string(rec),
    table_name = rec$dataset_name,
    table_desc = paste(rec$org_id, rec$org_set_id, rec$dataset_name),
    data_source_id = rec$data_source_uuid)
  
  insert_logic <- paste0("INSERT INTO backbone.geom_index ",
                         "(data_type_id, data_type_name, geom_type_concept_id, ",
                         "geom_type_source_value, table_schema, table_name, table_desc, ",
                         "data_source_id) VALUES ('",
                         paste(index_record %>% slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                         "');") %>% 
    stringr::str_replace_all("'NULL'", "NULL")
  
  DatabaseConnector::executeSql(conn, insert_logic)
}

# CREATE ATTR_INDEX RECORD
create_attr_index_record <- function(rec) {
  index_record <- tibble::tibble(
    attr_of_geom_index_id = get_foreign_key_gid(rec$geom_dependency_uuid),
    table_schema = create_schema_string(rec),
    table_name = rec$dataset_name,
    data_source_id = rec$data_source_uuid)
  
  insert_logic <- paste0("INSERT INTO backbone.attr_index ",
                         "(attr_of_geom_index_id, table_schema, table_name, data_source_id) ",
                         "VALUES ('",
                         paste(index_record %>% dplyr::slice(1) %>% unlist(., use.names = FALSE), collapse = "', '"),
                         "');") %>% 
    stringr::str_replace_all("'NULL'", "NULL")
  
  DatabaseConnector::executeSql(conn, insert_logic)
}

# CREATE GEOM AND ATTR INDICES FROM DATA SOURCES
create_indices <-  function(uuids) {
  
  lapply(uuids, function(id) {
    record <- get_data_source_record(id)
    
    #GET GEOM AND ATTR INDEX (SCHEMA SPECIFIC)
    geom_index <- DatabaseConnector::dbReadTable(conn, "backbone.geom_index")
    geom_index_data_source_ids <- geom_index$data_source_id
    
    attr_index <- DatabaseConnector::dbReadTable(conn, "backbone.attr_index")
    attr_index_data_source_ids <- attr_index$data_source_id  
    
    # IF record type geom AND not in gidsid then create geom index record
    if (record$geom_type != "" & !id %in% geom_index_data_source_ids) {
      gi_record <- create_geom_index_record(record)
    }
    # IF attr AND not in aidsid check dependency
    if (record$has_attributes == 1 & !id %in% attr_index_data_source_ids) {

    ## IF geom dependency AND dependency not in gidsid then create geom index record AND insert into db 
      if (!is.na(record$geom_dependency_uuid) & !record$geom_dependency_uuid %in% geom_index_data_source_ids) {
        gi_dependency <- create_geom_index_record(get_data_source_record(record$geom_dependency_uuid))
        # insert into db
      }
    # create attr index record
      attr_record <- create_attr_index_record(record)
      
    }
  })
}

# CREATE GEOM SPEC TABLE
create_spec_table <- function(json_string_spec) {
  json_spec <- rjson::fromJSON(json_string_spec)
  tibble::tibble("t_name"=names(json_spec),
         "t_type"=unlist(lapply(t_name, function(x) json_spec[[x]]$type)),
         "t_value"=unlist(lapply(t_name, function(x) json_spec[[x]]$value)))
}

# STANDARDIZE STAGED DATA
standardize_staged_data <- function(stage_data, spec_table) {
  select_df <- spec_table[spec_table$t_type == "select",]
  result_df <- stage_data[,select_df$t_value] %>% as.data.frame()
  names(result_df) <- select_df$t_name
  
  hardcode_df <- spec_table[spec_table$t_type == "hardcode",]
  if (nrow(hardcode_df) > 0){
    for(i in 1:nrow(hardcode_df)){
      result_df[hardcode_df$t_name[i]] <- hardcode_df$t_value[i]  
    }
  }
  
  rcode_df <- spec_table[spec_table$t_type == "code",]
  if (nrow(rcode_df) > 0){
    for(i in 1:nrow(rcode_df)){
      result_df[rcode_df$t_name[i]] <- eval(parse(text=rcode_df$t_value[i]))  
    }
  }
  
  return(result_df)
}

# GET DATA SOURCE RECORD
get_data_source_record <- function(ds_uuid){
  conn <- connect(connectionDetails)
  return_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.data_source WHERE data_source_uuid = ", ds_uuid))
  disconnect(conn)
  return(return_df)
}

# GET STAGING DATA
get_stage_data <- function(rec) {
  # ONLY HANDLES FILES (NO API YET)
  base_timeout <- getOption('timeout')
  options(timeout = 600)
  if (rec$download_method == "file") {
    if (rec$download_subtype == "zip") {
      tempzip <- paste0(tempfile(), ".zip")
      download.file(rec$download_url, tempzip)
      unzip(tempzip, exdir = tempdir())
      if (rec$download_data_standard == 'shp') {
        return(sf::st_read(file.path(tempdir(), rec$download_filename)))
      } else if (rec$download_data_standard == 'csv') {
        return(read.csv(file.path(tempdir(), rec$download_filename)))
      }
      
    }
  }
  options(timeout = base_timeout)
}

# CREATE GEOM INSTANCE TABLE
create_geom_instance_table <- function(connectionDetails, schema, name) {
  conn <- connect(connectionDetails)
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
  disconnect(conn)
}

create_attr_instance_table <- function(connectionDetails, schema, name) {
  conn <- connect(connectionDetails)
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
  disconnect(conn)
}

get_uuids <- function() {
  
  conn <- connect(connectionDetails)
  data_source <- DatabaseConnector::dbReadTable(conn, "backbone.data_source")
  disconnect(conn)
  return(data_source$data_source_uuid)
}

get_geom_template <- function(connectionDetails){
  conn <- connect(connectionDetails)
  geom_template <- DatabaseConnector::dbReadTable(conn, "backbone.geom_template")											 
  disconnect(conn)
  return(geom_template)
}
																		
get_geom_index_by_ds_uuid <- function(ds_uuid){
  conn <- connect(connectionDetails)
  return_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE data_source_id = ", ds_uuid))
  disconnect(conn)
  return(return_df)
}

import_geom_table <- function(stage_data, geom_index){
  
  conn <- connect(connectionDetails)
  DatabaseConnector::dbAppendTable(conn , paste0(geom_index$table_schema, ".", geom_index$table_name), value = stage_data)
  disconnect(conn)
}

get_geom_template <- function(connectionDetails){
  conn <- connect(connectionDetails)
  geom_template <- DatabaseConnector::dbReadTable(conn, "backbone.geom_template")
  disconnect(conn)
  return(geom_template)
}

get_attr_template <- function(connectionDetails){
  conn <- connect(connectionDetails)
  geom_template <- DatabaseConnector::dbReadTable(conn, "backbone.attr_template")
  disconnect(conn)
  return(geom_template)
}

get_geom_id_map <- function(connectionDetails, geom_index_id){
  
  conn <- connect(connectionDetails)
  geom_index_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.geom_index WHERE geom_index_id = ", geom_index_id,";"))
  
  sql_query <- paste0(
    "SELECT geom_record_id, geom_source_value FROM "
    , geom_index_df$table_schema
    ,".\"geom_" 
    , geom_index_df$table_name
    ,'\";'
  )
  geom_id_map <- DatabaseConnector::dbGetQuery(conn, sql_query)
  
  disconnect(conn)
  
  return(geom_id_map)
  
}

assign_geom_id_to_attr <- function(connectionDetails, result_df, geom_index_id){
  
  geom_id_map <- get_geom_id_map(connectionDetails, geom_index_id)
  
  tmp <- merge(x = result_df, y= geom_id_map, by.x = "geom_join_column", by.y = "geom_source_value")
  
  tmp <- subset(tmp, select = -c(geom_join_column))
  
  return(tmp)
  
}

import_geom_table <- function(connectionDetails, stage_data, geom_index){
  
  data_size_gb <- object.size(stage_data) / 1000000000
  
  message(paste0("Expect ", ceiling(2*2**floor(log(data_size_gb)/log(2))), " database inserts."))
  
  if(data_size_gb > 1) {
    print("divide and conquer")
    import_geom_table_recr(connectionDetails, stage_data = stage_data[1:floor(nrow(stage_data)*.5),], geom_index)
    import_geom_table_recr(connectionDetails, stage_data = stage_data[floor(nrow(stage_data)*.5)+1:nrow(stage_data),], geom_index)
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
    
    
    
    
    
    dbDisconnect(postgis_con)
  }
  
}


import_attr_table <- function(connectionDetails, df, attr_index_df){
  conn <- connect(connectionDetails)
  
  insert_table_name <- paste0("\"", attr_index_df$table_schema, "\"", "." ,"\"attr_", attr_index_df$table_name, ".\"")
  
  df <- subset(df, select = -c(attr_record_id))
  
  DatabaseConnector::insertTable(conn,
                                 databaseSchema = paste0("\"",attr_index_df$table_schema,"\""),
                                 tableName = paste0("\"attr_",attr_index_df$table_name,"\""),
                                 data = df,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE
                                 )
  
  disconnect(conn)
  
}

# TODO try and make load_geom_table and load_feature as symmetrical as possible

load_geom_table <- function(ds_uuid) {
  
  ds_rec <- get_data_source_record(ds_uuid)
  
  stage_data <- get_stage_data(ds_rec)
  
  spec_df <- create_spec_table(ds_rec$geom_spec)
  
  result_df <- standardize_staged_data(stage_data, spec_df)
  
  geom_index <- get_geom_index_by_ds_uuid(ds_rec$data_source_uuid)
  
  
  # format for insert
  if (!"character" %in% class(result_df$geom_local_value)) {
    result_df$geom_local_value <- sf::st_as_binary(result_df$geom_local_value, EWKB = TRUE, hex = TRUE)
  }
  
  geom_template <- get_geom_template(connectionDetails)
  
  res <- plyr::rbind.fill(geom_template, result_df)
  
  res <- res[-1]
  
  res$geom_name <- iconv(res$geom_name, "latin1")
  
  create_geom_instance_table(connectionDetails, schema =  geom_index$table_schema, name = geom_index$table_name)
  
  # insert into geom table
  import_geom_table(connectionDetails, res, geom_index)
}

			   
load_feature <- function(connectionDetails, feature_index_id){
  # connect db
  conn <- connect(connectionDetails)
  
  # get feature
  feature_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.feature_index WHERE feature_index_id = ", feature_index_id))
  
  # get attr_index
  attr_index_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", feature_df$data_source_uuid,";"))
  
  # get data_source_record
  ds_rec <- get_data_source_record(feature_df$data_source_uuid)
  
  geom_index_df <- get_geom_index_by_ds_uuid(ds_rec$geom_dependency_uuid)
  
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
  print(paste0("schema: ", geom_index_df$table_schema))
  print(paste0("name: ", geom_index_df$table_name))
  if (!existsTable(conn, geom_index_df$table_schema, paste0("geom_",geom_index_df$table_name))) {
    message("Loading geom table dependency")
    load_geom_table(ds_rec$geom_dependency_uuid)
  }
  
  # get mapping values from geom table
  result_df <- assign_geom_id_to_attr(connectionDetails, result_df, attr_index_df$attr_of_geom_index_id)
  
  # result_df <- tmp
  # get attr template
  attr_template <- get_attr_template(connectionDetails)
  
  # append staging data to template format
  attr_to_ingest <- plyr::rbind.fill(attr_template, result_df)
  
  create_attr_instance_table(connectionDetails, schema = attr_index_df$table_schema, name = attr_index_df$table_name)
  
  # import
  import_attr_table(connectionDetails, attr_to_ingest, attr_index_df)
  
  disconnect(conn)
}



import_sf <- function(connectionDetails, feature_index_id) {
  
  conn = DatabaseConnector::connect(connectionDetails)
  
  feature_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.feature_index WHERE feature_index_id = ", feature_index_id))
  ds_rec <- get_data_source_record(feature_df$data_source_uuid)
  attr_index_df <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.attr_index WHERE data_source_id = ", feature_df$data_source_uuid,";"))
  geom_index_df <- get_geom_index_by_ds_uuid(ds_rec$geom_dependency_uuid)
  
  if (!existsTable(conn, attr_index_df$table_schema, paste0("attr_", attr_index_df$table_name))) {
    message("Loading attr table dependency")
    load_feature(connectionDetails, feature_index_id)
  }
  
  attr_table_string <- paste0(attr_index_df$table_schema, ".\"attr_", attr_index_df$table_name, "\"")
  geom_table_string <- paste0(geom_index_df$table_schema, ".\"geom_", geom_index_df$table_name, "\"")
  feature <- feature_df$feature_name
  
  base_query <- paste0("select * from ", attr_table_string, 
                       " join ", geom_table_string, 
                       " on ", attr_table_string, ".geom_record_id=", geom_table_string, ".geom_record_id",
                       " where ", attr_table_string, ".attr_source_value = '", feature,"'")
  
  num_records_query <- paste0("select count(*) from ", attr_table_string, 
                              " join ", geom_table_string, 
                              " on ", attr_table_string, ".geom_record_id=", geom_table_string, ".geom_record_id",
                              " where ", attr_table_string, ".attr_source_value = '", feature,"'")
  
  query_count_result <- DatabaseConnector::querySql(conn, num_records_query)
  row_count <- query_count_result$COUNT
  
  if (row_count <= 1001) {
    x <- sf::st_read(dsn = conn, query = base_query)
  } else {
    sf_base_query <- paste0(base_query, " limit 1")
    sf_base <- sf::st_read(dsn = conn, query = sf_base_query)
    for (i in 0:(row_count%/%1000)) {
      print(i)
      iter_query <- paste0(base_query, " limit 1000 offset ", i * 1000 + 1)
      sf_base <- rbind(sf_base, sf::st_read(dsn = conn, query = iter_query))
    }
  }
  disconnect(conn)
  
  return(sf_base)
}

