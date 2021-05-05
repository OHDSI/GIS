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
dbload_EPA_sites <- function(sites,geom_tablename) {
    
    loaded <- list()
    done <- by(EPA_sites, seq_len(nrow(EPA_sites)), function(site) {

        if (! site$Site.Number %in% loaded) {

            # create location with geometry
            loaded <- c(site$Site.Number,loaded)
            sql_createsite <- paste(
                'INSERT INTO',geom_tablename,' ("geom_record_id","name","geom_wgs84") 
                VALUES (DEFAULT,$3,ST_SetSRID(ST_MakePoint($2,$1),4326))
                RETURNING geom_record_id'
            )
            res <- dbSendQuery(con,sql_createsite)
            dbBind(res, list(site$Latitude,site$Longitude,paste(site$Site.Number,":",site$Local.Site.Name)))
            site_ID <- dbFetch(res)[1,1]
            dbClearResult(res)

        }

    })
    
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
    
    res <- jsonlite::fromJSON(request_url, simplifyDataFrame = TRUE)
    # TODO: error checking on response
    data <- res$Data
    return(data)
    
}