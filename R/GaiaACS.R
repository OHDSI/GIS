



# Pulls data from ACS API and stores in AREA_ATTRIBUTE table
# Relies on (joins via concept) appropriate AREA data already existing in database
add_acs_data <- function(connectionDetails
                         ,area_type_identifier
                         ,area_type_column = NULL
                         ,year = NULL
                         ,aggregation
                         ,variable
                         ,by_state
                         ,states = NULL
){

  # default to area_type_id
  if( missing(area_type_column) || is.null(area_type_column)){
    area_type_column <- NA
  }


  if(missing(year) || is.na(year)){
    year <- "2017"
  }

  area_type <- get_area_type(area_type_identifier = area_type_identifier
                             ,area_type_column = area_type_column)


  data_source_id <- paste("ACS", year, aggregation, sep = "_")

  # add data source (checks to see if exists first)
  insert_data_source(connectionDetails
                     ,data_source_id
                     ,data_source_name = paste("American Community Survey",aggregation, year, sep = " ")
                     ,data_source_type_id = 2
                     ,data_source_type_name = "attribute"
                     ,document_url = "https://api.census.gov/data/(year)/acs/acs5"
                     ,collection_end_date = paste0('12-31-', year)
                     ,timeframe_name = "year"
                     ,timeframe_value = 5)



  url_list <- list()

  if(by_state){
    base_url <- "https://api.census.gov/data/@year/acs/@aggregation?get=@variable,GEO_ID&for=@geography:*&in=state:@state"

    # if states = null -> consider all states
    if(missing(states) || is.na(states)){
      url <- SqlRender::render(base_url
                              ,year = year
                              ,aggregation = aggregation
                              ,variable = variable
                              ,geography = area_type$ACS_name
                              ,state = "*")
      url_list[1] <- url
    }else{
      for(i in 1:length(states)){
        url <- SqlRender::render(base_url
                                ,year = year
                                ,aggregation = aggregation
                                ,variable = variable
                                ,geography = area_type$ACS_name
                                ,state = states[i]
        )

        url_list[i] <- url
      }

    }

  }else{
    base_url <- "https://api.census.gov/data/@year/acs/@aggregation?get=@variable,GEO_ID&for=@geography:*"
    url <- SqlRender::render(base_url
                            ,year = year
                            ,aggregation = aggregation
                            ,variable = variable
                            ,geography = area_type$ACS_name
    )

    url_list[1] <- url
  }

  if(length(url_list) > 0){

    conn <- DatabaseConnector::connect(connectionDetails)

    for(i in 1:length(url_list)){
      url <- url_list[[i]]
      x <-  httr::content(
                      httr::GET(url)
                      ,"parsed"
                      )
      var_name <- unlist(x[1])[1]
      res_df <- data.frame(matrix(nrow=length(x)-1,ncol = 2))
      for(i in 2:length(x)){
        res_df[i-1,1] <- unlist(x[i])[1]
        res_df[i-1,2] <- unlist(x[i])[2]
      }

      names(res_df) <- c("attribute_value", "geoid")

      res_df$attribute_source_value <- var_name
      res_df$data_source_id <- data_source_id

      # import data source
      DatabaseConnector::insertTable(conn
                                    ,paste0(gis_schema,".tmp_attr")
                                    ,data = res_df
                                    ,dropTableIfExists = TRUE
                                    ,createTable = TRUE
      )

      tmp_sql <- SqlRender::readSql("inst/sqlserver/helpers/insert_area_attrib_from_tmp.sql")
      tmp <- SqlRender::render(tmp_sql
                               , gis_schema = gis_schema
                               , source_vocabulary = paste0("ACS", year)
                               )

      DatabaseConnector::executeSql(conn, tmp)
    }

    DatabaseConnector::disconnect(conn)
  }



}



get_acs_vars <- function(connectionDetails){
  conn <- DatabaseConnector::connect(connectionDetails)


  get_loc_sql <- SqlRender::render("SELECT concept_code, concept_name
                                   FROM @gis_schema.geo_concept
                                   WHERE vocabulary_id = 'ACS2017'
                                   ORDER BY concept_code;"
                                   ,gis_schema = gis_schema
  )

  # pull locations from location table
  acs_vars <- DatabaseConnector::dbGetQuery(conn, get_loc_sql)

  DatabaseConnector::disconnect(conn)

  return(acs_vars)

}
