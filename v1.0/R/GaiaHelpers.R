

# Load config file
# Reads from YML file : config/config.yml
# Relies on 'config' package
load_config <- function(config_path = NULL){
  if (missing(config_path) || is.null(config_path)) {
    config_path <- "conf/config.yml"
  }
  config <- config::get(file = config_path)

  # Database connection information
  connectionDetails <<- DatabaseConnector::createConnectionDetails(
    dbms=config$connection_details$dbms ,
    server=config$connection_details$server,
    user=config$connection_details$user,
    password=config$connection_details$password
  )

  # Directory to store polygon paths
  polygon_file_dir <<- config$polygon_file_dir
  # Directory to store temp tables
  temp_dir <<- config$temp_dir

  # Domain specific schemas
  cdm_schema <<- config$cdm_schema
  vocab_schema <<- config$vocab_schema
  gis_schema <<-  config$gis_schema

  # Coordinate reference system
  if(config$convert_epsg){
    standard_epsg <<- config$default_epsg
  }

  rm(config)

}

# Clears config data from memory (needed?)
unload_config <- function(){

  rm("connectionDetails"
       ,"polygon_file_dir"
       ,"temp_dir"
       ,"cdm_schema"
       ,"vocab_schema"
       ,"gis_schema"
       ,"standard_epsg")
}

# create GIS tables
# does nothing if table exists already
load_ddl <- function(connectionDetails){
  conn <- DatabaseConnector::connect(connectionDetails)

  ddl_files <- list.files("inst/sqlserver/ddl", full.names = TRUE)

  for(i in 1:length(ddl_files)){
    tmp_sql <- SqlRender::readSql(ddl_files[i])
    tmp <- SqlRender::render(tmp_sql, gis_schema = gis_schema )
    DatabaseConnector::executeSql(conn, tmp)
  }

  DatabaseConnector::disconnect(conn)
}



# converts GEOID representation from short to long
# e.g. "51" -> "0400000US51"
convert_geo_short_to_long <- function(src_string, summary_level){
  return(
    paste0(summary_level, "0000US", src_string )
  )
}

# converts GEOID representation from long to short
# e.g. "0400000US51" -> "51"
convert_geo_long_to_short <- function(src_string){
  return(substr(src_string, 10, 100))
}




# Retrieve area_type record from area_type_index
# Can match on any column (col) using any value (identifier)
# col defaults to area_type_id (identity)
get_area_type <- function(area_type_identifier
                          ,area_type_column = NULL
){
  # Default to column = area_type_id
  if(missing(area_type_column) || is.na(area_type_column)){
    area_type_column <- "area_type_id"
  }

  if(!area_type_column %in% names(area_type_index)){
    print("column not found")
  }else{
    ret <- area_type_index[which(area_type_index[area_type_column] == area_type_identifier),]
    if(nrow(ret) != 1){
      print("error: area type not found or multiple area types with same id")
    }else{
      return( as.list(ret) )
    }
  }
}


# Retrieve locations and store load them as SpatialPointsDataFrame
get_locations_spdf <- function(connectionDetails
                               ,epsg = NULL){

  if(missing(epsg) || is.na(epsg)){
    epsg <- standard_epsg
  }

  conn <- DatabaseConnector::connect(connectionDetails)


  get_loc_sql <- SqlRender::render("SELECT location_id
                                   , latitude
                                   , longitude
                                   , epsg
                                   FROM @gis_schema.location;"
                                   ,gis_schema = gis_schema
  )

  # pull locations from location table
  locations <- DatabaseConnector::dbGetQuery(conn, get_loc_sql)

  epsg_list <- unique(locations$epsg)

  if(length(epsg_list) > 0){

    # Get initial spdf
    curr_epsg <- epsg_list[1]
    curr_locs <- locations[locations$epsg == curr_epsg,]
    spdf <- convert_location_spdf(curr_locs, curr_epsg)

    if(curr_epsg != epsg){
      spdf <- sp::spTransform(spdf, sp::CRS(paste0("+init=epsg:",epsg)))
    }

    # for each unique epsg value
    if(length(epsg_list) > 1){
      for(epsg_index in 2:length(epsg_list)){

        curr_epsg <- epsg_list[epsg_index]
        curr_locs <- locations[locations$epsg == curr_epsg,]
        spdf_tmp <- convert_location_spdf(curr_locs, curr_epsg)

        if(curr_epsg != epsg){
          spdf_tmp <- sp::spTransform(spdf, sp::CRS(paste0("+init=epsg:",epsg)))
        }

        # append to first result
        spdf <- sp::rbind.SpatialPointsDataFrame(spdf, spdf_tmp)
      }
    }



  }

  DatabaseConnector::disconnect(conn)

  # TODO: If NULL then throw error

  return(spdf)
}


# Convert location data to SpatialPointsDataFrame
convert_location_spdf <- function(locations, epsg) {

  spdf <- sp::SpatialPointsDataFrame(coords = cbind(locations$longitude, locations$latitude)
                                     ,data = data.frame(locations["location_id"])
                                     ,proj4string = sp::CRS(paste0("+init=epsg:", epsg))
  )
  return(spdf)
}



# Populate LOCATION_TO_AREA map using point-in-polygon calculations
# Checks all locations (points) against all areas (polygons)
# Deletes any point-in-polygon relationships before calculating
populate_LTA_pip <- function(connectionDetails){

  # Getlocations
  spdf_locs <- get_locations_spdf(connectionDetails)


  # Create results table

  l2a <- data.frame(matrix(nrow=0, ncol = 3))
  names(l2a) <- c("location_id", "polygon_file_id", "polygon_id")

  # Get list of polygon_file's that are referenced in AREA table
  conn <- DatabaseConnector::connect(connectionDetails)


  tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/get_polygon_files_with_areas.sql")
  tmp <- SqlRender::render(tmp_sql, gis_schema = gis_schema )
  pf_list <- DatabaseConnector::dbGetQuery(conn, tmp)


  DatabaseConnector::disconnect(conn)

  # for each polygon_file
  for(i in 1:nrow(pf_list)){
    # load shapefile from disk
    curr_pf <-  rgdal::readOGR(dsn = paste(polygon_file_dir,pf_list$layer[i], sep = "/")
                               , layer = pf_list$layer[i]
                               , stringsAsFactors = FALSE
                               , verbose = FALSE)


    # convert SPDF to shapefile CRS
    spdf_tmp <- sp::spTransform(spdf_locs, curr_pf@proj4string)

    # for each polygon in file
    for(j in 1:nrow(curr_pf)){

      # for each point in SPDF, check point-in-polygon
      curr_poly <- curr_pf@polygons[[j]]@Polygons[[1]]@coords
      pip_result <-  sp::point.in.polygon(spdf_tmp@coords[,1]
                                          ,spdf_tmp@coords[,2]
                                          , curr_poly[,1]
                                          , curr_poly[,2])
      pip_matches <- spdf_tmp@data$location_id[pip_result > 0]

      # for each match, add to result data frame
      if(length(pip_matches) > 0){
        tmp <- data.frame(matrix(nrow=0, ncol = 3))
        names(tmp) <- names(l2a)
        for(k in 1:length(pip_matches)){

          tmp[k,] <- c(pip_matches[k]
                       ,pf_list$polygon_file_id[i]
                       ,curr_pf@data[1,pf_list$file_id_col[i]]
          )


        }
        # add matches to results data frame
        l2a <- rbind(l2a, tmp)
      }

    }
  }

  if(nrow(l2a) > 0){

    conn <- DatabaseConnector::connect(connectionDetails)

    # import results to temp table
    DatabaseConnector::insertTable(conn
                                   ,paste0(gis_schema,".tmp_l2a")
                                   ,data = l2a
                                   ,dropTableIfExists = TRUE
                                   ,createTable = TRUE
    )

    # run merge script
    # delete from LOCATION_TO_AREA where match_type = 'point-in-polygon'
    # join temp table with AREA
    # insert into LOCATION_TO_AREA
    tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/insert_lta_pip.sql")
    tmp <- SqlRender::render(tmp_sql, gis_schema = gis_schema )
    DatabaseConnector::executeSql(conn, tmp)

    # disconnect
    DatabaseConnector::disconnect(conn)
  }

}


# Populate LOCATION_TO_AREA map by matching zip code to ZCTA concept
# Deletes any LTA records with 'zcta match' relationships before calculating
populate_LTA_zcta_match <- function(connectionDetails){


  conn <- DatabaseConnector::connect(connectionDetails)


  get_loc_sql <- SqlRender::render("SELECT location_id
                                   , zip
                                   FROM @gis_schema.location
                                   WHERE zip IS NOT NULL;"
                                   ,cdm_schema = cdm_schema
  )

  # pull locations from location table
  locations <- DatabaseConnector::dbGetQuery(conn, get_loc_sql)

  # truncate zip codes over 5 digits
  locations$zip <- substr(locations$zip, 1, 5)

  locations$zip <- convert_geo_short_to_long(locations$zip, "860")


  # import results to temp table
  DatabaseConnector::insertTable(conn
                                 ,paste0(gis_schema,".tmp_l2a")
                                 ,data = locations
                                 ,dropTableIfExists = TRUE
                                 ,createTable = TRUE
  )

  # run merge script
  # delete from LOCATION_TO_AREA where match_type = 'zcta match'
  # join temp table with AREA
  # insert into LOCATION_TO_AREA
  tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/insert_lta_zcta.sql")
  tmp <- SqlRender::render(tmp_sql, gis_schema = gis_schema )
  DatabaseConnector::executeSql(conn, tmp)

  # disconnect
  DatabaseConnector::disconnect(conn)


}

# Populate LOCATION_TO_AREA map by matching (state + county name) to concept_code
# Deletes any LTA records with 'string match' relationships before calculating
populate_lta_string_county <- function(connectionDetails){


  conn <- DatabaseConnector::connect(connectionDetails)


  get_loc_sql <- SqlRender::render("SELECT *
                                   FROM @gis_schema.location
                                   WHERE state IS NOT NULL
                                   AND county IS NOT NULL;"
                                   ,gis_schema = gis_schema
  )

  # pull locations from location table
  locations <- DatabaseConnector::dbGetQuery(conn, get_loc_sql)

  # choose column by state represention (e.g. ME (STUSPS) vs. Maine (NAME))
  if ( max(nchar(locations$state)) == 2){
    # 'ME'
    locations$state_fips <- state_fips$STATEFP[match( locations$state,state_fips$STUSPS)]
  }else{
    # 'Maine'
    locations$state_fips <- state_fips$STATEFP[match( locations$state,state_fips$NAME)]
  }


  locations <- locations[!is.na(locations$state_fips),]

  get_counties_sql <- SqlRender::render("SELECT *
                                        FROM @gis_schema.geo_concept
                                        WHERE concept_class_id = 'county';"
                                        ,gis_schema = gis_schema
  )


  counties <- DatabaseConnector::dbGetQuery(conn, get_counties_sql)

  c2 <- data.frame(cbind(counties$concept_id, counties$concept_name, substr(counties$concept_code, 10, 11)))
  names(c2) <- c("concept_id", "concept_name", "state_fips")


  res_df <- merge(locations, c2, by.x = c("state_fips", "county"), by.y = c("state_fips", "concept_name"))




  l2a <- unique(data.frame(res_df$location_id, res_df$concept_id))
  names(l2a) <- c("location_id", "concept_id")

  # import results to temp table
  DatabaseConnector::insertTable(conn
                                 ,paste0(gis_schema,".tmp_l2a")
                                 ,data = l2a
                                 ,dropTableIfExists = TRUE
                                 ,createTable = TRUE
  )


  # run merge script
  # delete from LOCATION_TO_AREA where relationship_id = 'string match'
  # join temp table with GEO_CONCEPT
  # join temp table with AREA
  # insert into LOCATION_TO_AREA
  tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/insert_lta_string_county.sql")
  tmp <- SqlRender::render(tmp_sql, gis_schema = gis_schema )
  DatabaseConnector::executeSql(conn, tmp)

  # disconnect
  DatabaseConnector::disconnect(conn)

}
