
# Retrieves and imports TIGER polygons to populate AREA table
import_tiger_data <- function(connectionDetails
                              ,area_type_identifier
                              ,area_type_column = NULL
                              ,year = NULL
                              ,layer_name = NULL
                              ,states = NULL){
  # default to area_type_id
  if( missing(area_type_column) || is.null(area_type_column)){
    area_type_column <- NA
  }


  area_type <- get_area_type(area_type_identifier = area_type_identifier
                            ,area_type_column = area_type_column)

  # default year
  if( missing(year) || is.null(year)){
    year <- "2018"
  }


  data_source_id <- SqlRender::render("TIGER/Line@year"
                                    ,year = year)

  # TODO: insert_data_source(ds_name, ...)
  insert_data_source(connectionDetails
                    ,data_source_id
                    ,data_source_name = paste0("Census TIGER/Line Shapefiles ", year)
                    ,data_source_type_id = 1
                    ,data_source_type_name = "polygon"
                    ,document_url = "https://www2.census.gov/geo/tiger"
                    ,collection_start_date = paste0('01-01-', year)
                    ,collection_end_date = paste0('12-31-', year)
                    ,timeframe_name = "year"
                    ,timeframe_value = 1

  )







  if(is.na(area_type$TIGER_name)){
    print("TODO: error message -> tiger spec not found, return")

  }else{

    url_list <- list()


    base_url <- SqlRender::render(paste0("https://www2.census.gov/geo/tiger/",
                                        "TIGER@year/",
                                         area_type$TIGER_name,
                                         "/",
                                         area_type$TIGER_format,
                                         ".zip"),
                                       year = year)

    # if file is state dependent
    if(grepl("@state", area_type$TIGER_format)){
      fip_list <- state_fips$STATEFP
      if(!is.null(states) & length(states) > 0){
        fip_list <- fip_list[fip_list %in% states]
      }

      # if there are any matching states
      if(length(fip_list) > 0){
        for(i in 1:length(fip_list)){
          curr_url <- SqlRender::render(base_url, state = fip_list[i])
          url_list[i] <- curr_url
        }
      }

    }else{
      url_list[1] <- base_url
    }


    # if we have any files to get...
    if(length(url_list) > 0){
      for(j in 1:length(url_list)){
        get_tiger_file(connectionDetails, url_list[[j]], area_type, data_source_id)
      }

    }


    }
}


get_tiger_file <- function(connectionDetails, url, area_type, data_source_id){


  dest_path <- paste0(temp_dir
                      , "/"
                      ,basename(url))

  # Try to get file, skip if not found (TODO: create warning?)
      # save zip to temp dir
  httr::GET(url,
         httr::write_disk(dest_path, overwrite = TRUE)
  )

  # get shapefile layer name by getting basename and removing '.zip'
  layer_name <- substr(basename(url), 0, nchar(basename(url)) -4)

  # unzip file to polygon_file_dir
  unzip(zipfile = dest_path
        , files = NULL
        , list = FALSE
        , overwrite = TRUE
        , exdir = paste(polygon_file_dir, layer_name, sep = "/")
  )

  # Convert GEOID
  sdf <- rgdal::readOGR(paste(polygon_file_dir
                              ,layer_name
                              ,sep = "/")
                        ,layer =layer_name
                        , stringsAsFactors = FALSE
                        , verbose = FALSE)


  sdf@data[area_type$TIGER_id_col][[1]] <- convert_geo_short_to_long(
                                             sdf@data[area_type$TIGER_id_col][[1]]
                                            ,summary_level = area_type$summary_level)



  rgdal::writeOGR(sdf
                  , dsn =paste(polygon_file_dir
                                  ,layer_name
                                  ,sep = "/")
                  , driver = "ESRI Shapefile"
                  , layer=layer_name
                  , overwrite_layer = TRUE
                  , verbose = FALSE)


  # insert polygon_file record into DB
  ingest_shapefile(connectionDetails
                   ,layer_name = layer_name
                   ,file_id_col = area_type$TIGER_id_col
                   ,area_type_id = area_type$area_type_id
                   ,data_source_id = data_source_id
                   ,source_file_name = url
                   ,area_name_col = area_type$TIGER_name_col
                   ,source_vocabulary = "US Census"
                       )






}





