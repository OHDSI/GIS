require(httr)
require(jsonlite)

# load OMOP dbutils.R
source('../R/dbutils.R')

# retrieve EPA precalculated file
fetch_EPA_precalculated <- function(options) {

    temp <- tempfile()
    download_url <- paste(options$base_download_url,options$file_download,sep="")
    download.file(download_url,temp)
    data <- read.csv(unz(temp, options$file_name), header=TRUE)
    unlink(temp)
    
    return (list(
        download_url = download_url,
        data = data.frame(data)
    ))
    
}

# load sites into database
load_EPA_sites <- function(con,sites,geom_tablename) {
    
    dbWriteTable(con, "temp_epa_sites", sites, is.temp=TRUE)
    sql_updategeom <- paste0(
        "INSERT INTO ",geom_tablename,
        " (name,geom_source_coding,geom_source_value,geom_wgs84)
         SELECT \"Local.Site.Name\" as name,
        'SS-CCC-NNNN' as geom_source_coding,
         CONCAT(\"State.Code\"::varchar,'-',LPAD(\"County.Code\"::varchar,3,'0'),'-',LPAD(\"Site.Number\"::varchar,4,'0')) as geom_source_value,
         ST_SetSRID(ST_MakePoint(\"Longitude\",\"Latitude\"),4326) as geom_wgs84
         FROM temp_EPA_sites")

    res <- dbSendQuery(con,sql_updategeom)
    dbClearResult(res)
    
    sql_drop <- "DROP TABLE temp_epa_sites"
    res <- dbSendQuery(con,sql_drop)
    dbClearResult(res)
    
}

# retrieve EPA AQS data through their API
# TODO: create institutional email and credentials for API key
# NOTE: this could also be done through file download: 
#.      file_download <- "annual_conc_by_monitor_2020.zip"
fetch_EPA_AQS_from_api <- function(options) {

    base_api_url <- "https://aqs.epa.gov/data/api/annualData/"

    request_url <- paste0(
        base_api_url,options[['api_query_type']],"?", 
        "email=",options[['api_email']], 
        "&key=",options[['api_key']],
        "&param=",options[['api_param']],
        "&bdate=",options[['api_bdate']],
        "&edate=",options[['api_bdate']],
        "&state=",options[['api_state']]
    )

    res <- GET(request_url)
    # TODO: error checking on response
    data <- jsonlite::fromJSON(content(res,"text"), simplifyDataFrame = TRUE)$Data

    # add site_ID formatted as per https://aqs.epa.gov/aqsweb/airdata/FileFormats.html
    data$site_ID<-paste0(
        data$state_code,"-",
        data$county_code,"-",
        sprintf("%05d",as.integer(data$site_number))
    )

    return(list(
        api_query = request_url,
        data = data
    ))
    
}

# place attribute data for sites in attr table
# TODO: map attr_data columns to attr table columns
# TODO: use temp table and join for load
load_EPA_attr <- function(con,attr_data,geom_tablename,attr_tablename) {
    
    sites = unique(attr_data$site_ID)
    for (site in sites) {
        
        # more than one measurement at each site
        # TODO: bring in monitor data as well
        site_data = attr_data[ which(attr_data$site_ID==site), ]

        # assume simple average of all values at site
        val = mean(site_data$arithmetic_mean)
        sql_insertattr <- paste(
            "INSERT INTO ",attr_tablename," (
                                            geom_record_id,
                                            attr_start_date,
                                            attr_end_date,
                                            value_as_number,
                                            unit_source_value,
                                            attr_source_value,
                                            geom_source_value
                                            )
            SELECT geom_record_id,
                   to_date($1, 'yyyy'),
                   to_date($2, 'yyyy') + interval '1 year' - interval '1 day',
                   $3,
                   $4::varchar,
                   $5::varchar,
                   geom_source_value
            FROM ",geom_tablename,"
            WHERE geom_source_value = $6"
        )
        res <- dbSendQuery(
            con,
            sql_insertattr,
            list(
                site_data[1,]$year,
                site_data[1,]$year,
                val,
                paste0(unique(site_data$units_of_measure),collapse=", "),
                paste0(unique(site_data$parameter),collapse=", "),
                site
            )
        )
        dbClearResult(res)
        
    }
    
}