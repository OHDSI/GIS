#!/usr/bin/env Rscript --vanilla

# load OMOP dbutils.R
source('../R/dbutils.R')
source('./EPA_loader.R')

con <- db_con()

instantiate_geom(con,'geom_fl_epa_aqs_sites','POINT')
print('geom table created')

instantiate_attr(con,'attr_fl_epa_pm25_2018','geom_fl_epa_aqs_sites')
print('attr table created')

EPA_sites <- fetch_EPA_sites_from_file()
print('sites downloaded')

load_EPA_sites(EPA_sites[ which(EPA_sites$State.Code=='12'), ],'geom_fl_epa_aqs_sites')
print('Florida sites uploaded to db')

options <- list(
    api_query_type = "byState",
    api_email = "test@aqs.api",
    api_key = "test",
    api_param = "88101,88502",  # PM2.5 88101,88502; NO2 42602
                                # https://aqs.epa.gov/aqsweb/documents/codetables/methods_all.html
    api_bdate = "20180115",     # begin date
    api_edate = "20180115",     # end date: set to same as bdate for whole year
    api_state = "12"            # Florida
)
aqs_data = fetch_EPA_AQS_from_api(options)
print('EPA AQS PM2.5 data for Florida downloaded')

load_EPA_attr(con,aqs_data,'geom_fl_epa_aqs_sites','attr_fl_epa_pm25_2018')
print('Florida data uploaded to attr table')

dbDisconnect(con)