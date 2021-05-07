require(httr)
require(jsonlite)

# load OMOP dbutils.R
source('../R/dbutils.R')

# retrieve EPA monitor sites through file download
fetch_EPA_sites_from_file <- function() {
    
     # all sites (i.e. monitor locations)
    base_download_url <- "https://aqs.epa.gov/aqsweb/airdata/"
    file_download <- "aqs_sites.zip"
    file_name <- "aqs_sites.csv"

    temp <- tempfile()
    download.file(paste(base_download_url,file_download,sep=""),temp)
    data <- read.csv(unz(temp, file_name), header=TRUE)
    unlink(temp)
    
    return (data.frame(data))
    
}

# load sites into database
load_EPA_sites <- function(sites,geom_tablename) {
    
    # to make sure no duplicate sites get loaded
    setRefClass("SiteList",fields=list(sites="list"))
    sites_done <- new("SiteList",sites=list())
    
    # loop through list
    done <- by(sites, seq_len(nrow(sites)), function(site,loaded) {
        
        # formatted as per https://aqs.epa.gov/aqsweb/airdata/FileFormats.html
        site_ID <- paste0(
            site$State.Code,"-",
            sprintf("%03d",site$County.Code),"-",
            sprintf("%05d",site$Site.Number)
        )

        if (! site_ID %in% loaded$sites) {

            # create location with geometry
            if (site$Longitude != 0 && site$Latitude != 0 && !is.na(site$Longitude) && !is.na(site$Latitude)) {
                loaded$sites <- c(site_ID,loaded$sites)
                sql_createsite <- paste(
                    'INSERT INTO',geom_tablename,' ("geom_record_id","name","geom_source_coding","geom_source_value","geom_wgs84") 
                    VALUES (DEFAULT,$1,$2,$3,ST_SetSRID(ST_MakePoint($4,$5),4326))
                    RETURNING geom_record_id'
                )
                res <- dbSendQuery(
                    con,
                    sql_createsite,
                    list(
                        site$Local.Site.Name,
                        "SS-CCC-NNNN",
                        site_ID,
                        site$Longitude,
                        site$Latitude
                    )
                )
                dbClearResult(res)
            }

        }

    },sites_done)
    
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

    return(data)
    
}

# place attribute data for sites in attr table
load_EPA_attr <- function(con,attr_data,geom_tablename,attr_tablename) {
    
    sites = unique(attr_data$site_ID)
    for (site in sites) {
        
        # assume simple average of all values at site
        val = mean(aqs_data[ which(aqs_data$site_ID==site), ]$arithmetic_mean)
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
            SELECT geom_record_id,'2018-01-01','2018-12-31',$1,'(µg/m3)','EPA AQS PM2.5',geom_source_value
            FROM ",geom_tablename,"
            WHERE geom_source_value = $2"
        )
        res <- dbSendQuery(
            con,
            sql_insertattr,
            list(
                val,
                site
            )
        )
        dbClearResult(res)

    }
    
}