# Functions to retrieve and import base polygons


# Inserts new DATA_SOURCE record
# If record already exists with same ID, it does nothing
insert_data_source <- function(connectionDetails, data_source_id, ...){


  conn <- DatabaseConnector::connect(connectionDetails)

  # check if already exists
  tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/get_data_source_by_id.sql")
  tmp <- SqlRender::render(tmp_sql
                           , gis_schema = gis_schema
                           , data_source_id = data_source_id)
  res <- DatabaseConnector::dbGetQuery(conn, tmp)

  if(nrow(res) > 0){
    print("Data source id already exists")
  }else{
    d_src <- data.frame( data_source_id = data_source_id
                         ,data_source_name = ""
                         ,data_source_type_id = 0
                         ,data_source_type_name = ""
                         ,document_url = ""
                         ,source_version = 0
                         ,collection_start_date = ""
                         ,collection_end_date = ""
                         ,timeframe_concept_id = 0
                         ,timeframe_name = ""
                         ,timeframe_value = 0
                         ,last_updated_date = "")

    params <- list(...)

    # If column information was passed into function, update data frame
    if(length(params) > 0){
      for(i in 1:length(params)){
        if(names(params)[i] %in% names(d_src)){
          d_src[names(params)[i]][1] <- params[[i]]
        }
      }
    }


    # import data source
    DatabaseConnector::insertTable(conn
                      ,paste0(gis_schema,".data_source")
                      ,data = d_src
                      ,dropTableIfExists = FALSE
                      ,createTable = FALSE
    )
  }

  DatabaseConnector::disconnect(conn)

}

# Inserts new polygon file record
# if polygon file already exists with same layer, does nothing
insert_polygon_file <- function(connectionDetails
                                ,layer_name
                                ,file_id_col
                                ,area_type_id
                                ,data_source_id
                                ,...){

  conn <- DatabaseConnector::connect(connectionDetails)

  # check if already exists
  tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/get_polygon_file_by_layer.sql")
  tmp <- SqlRender::render(tmp_sql
                           , gis_schema = gis_schema
                           , layer_name = layer_name)
  res <- DatabaseConnector::dbGetQuery(conn, tmp)


  if(nrow(res) > 0){
    print("Layer already exists")
  }else{
    p_file <- data.frame(
      area_type_id = area_type_id
      ,alt_path = ""
      ,layer = layer_name
      ,file_id_col = file_id_col
      ,source_file_name = ""
      ,file_format = ""
      ,data_source_id = data_source_id
    )

    params <- list(...)

    # If column information was passed into function, update data frame
    if(length(params) > 0){
      for(i in 1:length(params)){
        if(names(params)[i] %in% names(p_file)){
          p_file[names(params)[i]][1] <- params[[i]]
        }
      }
    }


    DatabaseConnector::insertTable(conn
                ,paste0(gis_schema,".polygon_file")
                ,data = p_file
                ,dropTableIfExists = FALSE
                ,createTable = FALSE
    )

    DatabaseConnector::disconnect(conn)


  }
}

# Inserts area data into AREA table
insert_areas <- function(connectionDetails
                         , layer_name
                         , area_type_id
                         , file_id_col
                         , data_source_id
                         , area_type_name = NULL
                         , area_name_col = NULL
                         , source_vocabulary = NULL){

  conn <- DatabaseConnector::connect(connectionDetails)

  # check if already exists
  tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/get_polygon_file_by_layer.sql")
  tmp <- SqlRender::render(tmp_sql
                           , gis_schema = gis_schema
                           , layer_name = layer_name)
  res <- DatabaseConnector::dbGetQuery(conn, tmp)

  if(nrow(res) == 0){
    print("Could not find polygon_file with specified layer name")
  }else{
    polygon_file_id <- res[[1]]

    sdf <- rgdal::readOGR(paste(polygon_file_dir
                                ,layer_name
                                ,sep = "/")
                          ,layer =layer_name
                          , stringsAsFactors = FALSE
                          , verbose = FALSE)@data


    areanames <- c("area_concept_id"
                   ,"area_name"
                   ,"area_type_id"
                   ,"area_source_concept_id"
                   ,"area_source_value"
                   ,"polygon_file_id"
                   ,"polygon_id"
                   ,"data_source_id")

    num_rows <- nrow(sdf)


    area_names <- NULL



    if(missing(area_name_col) || is.na(area_name_col)){
      area_names <- rep("", num_rows)
    }else{
      if(!area_name_col %in% names(sdf)){
        if("NAMELSAD" %in% names(sdf)){
          area_names <- sdf["NAMELSAD"]
        }else{
          area_names <- rep("", num_rows)
        }

      }else{
        area_names <- sdf[area_name_col]
      }
    }



    area_df <- data.frame(
      cbind(
        rep(0, num_rows)
        ,area_names
        ,rep(area_type_id, num_rows)
        ,rep(0, num_rows)
        ,sdf[file_id_col]
        ,rep(polygon_file_id, num_rows)
        ,sdf[file_id_col]
        ,rep(data_source_id, num_rows)
      ), stringsAsFactors = FALSE)

    names(area_df) <- areanames

    # if no vocabulary listed insert straight into area table
    if(missing(source_vocabulary) || is.na(source_vocabulary)){
      # inserttable
      DatabaseConnector::insertTable(conn
                                     ,paste0(gis_schema,".area")
                                     ,data = area_df
                                     ,dropTableIfExists = FALSE
                                     ,createTable = FALSE
      )

      # Mapping needed, insert to temp table then run script to join with concept
    }else{
      # inserttable
      DatabaseConnector::insertTable(conn
                                     ,paste0(gis_schema,".tmp_area")
                                     ,data = area_df
                                     ,dropTableIfExists = TRUE
                                     ,createTable = TRUE
      )


      tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/insert_area_from_tmp_area.sql")
      tmp <- SqlRender::render(tmp_sql
                               , gis_schema = gis_schema
                               , source_vocabulary = source_vocabulary)
      DatabaseConnector::executeSql(conn, tmp)
    }



  }

  DatabaseConnector::disconnect(conn)

}





# Grouping function to import shapefile
# Assumes DATA_SOURCE already exists
# Creates POLYGON_FILE and AREA records
ingest_shapefile <-   function(connectionDetails
                               ,layer_name
                               ,file_id_col
                               ,area_type_id
                               ,data_source_id
                               ,source_file_name
                               ,area_name_col
                               ,source_vocabulary = NULL){

  # insert polygon_file record into DB
  insert_polygon_file(connectionDetails = connectionDetails
                      ,layer_name = layer_name
                      ,file_id_col = file_id_col
                      ,area_type_id = area_type_id
                      ,data_source_id = data_source_id
                      ,source_file_name = source_file_name
                      ,file_format = "ESRI Shapefile") # hardcoded here



  insert_areas(connectionDetails = connectionDetails
                ,layer_name = layer_name
                , area_type_id = area_type_id
                , file_id_col = file_id_col
                , data_source_id = data_source_id
                , area_name_col = area_name_col
                , source_vocabulary = source_vocabulary)

}

