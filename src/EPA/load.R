#!/usr/bin/env Rscript --vanilla

##
# proof of concept pipeline to load EPA data
#
# two step process based on data type: geoms and atts
# for each step three sub-steps: acquire data, instantiate table, load data
##


# load OMOP dbutils.R
source('../R/dbutils.R')
source('./EPA_loader.R')

con <- db_con()


##
# get EPA site data, instantiate geom table, and load
# TODO: check to see if it exists already
##

# fetch EPS AQS site from static file
options <- list(
    base_download_url = "https://aqs.epa.gov/aqsweb/airdata/",
    file_download = "aqs_sites.zip",
    file_name = "aqs_sites.csv"
)
EPA_sites <- fetch_EPA_AQS_static(options)
print('sites downloaded')

# create geom table
aqs_sites_meta <- list(
  data_type_id = 0,
  data_type_name = 'POINT',
  geom_type_concept_id = 0,
  geom_type_source_value = 'EPA AQS Site. Identified AS (State FIPS - County FIPS - EPA Site Number) SS-CCC-NNNN',
  schema = 'public',
  table_name = 'geom_epa_aqs_sites',
  table_desc = paste0('Sourced from pre-calculated csv (zip) file of EPA AQS sites available from ',EPA_sites$download_url,'.'),
  data_source_id = 0,
  epsg_local = 0,
  epsg_local_name = ''
)
index_id_geom_epa_aqs_sites <- instantiate_geom(con,aqs_sites_meta)
print('geom table created')

# load EPA AQS sites into geom table
load_EPA_AQS_sites(con, EPA_sites$data, "geom_epa_aqs_sites")
print('US sites uploaded to db')

# fetch metadata for EPS AQS monitors from static file
# TODO: load into database with correct columns and link with attrs
options <- list(
    base_download_url = "https://aqs.epa.gov/aqsweb/airdata/",
    file_download = "aqs_monitors.zip",
    file_name = "aqs_monitors.csv"
)
EPA_monitors <- fetch_EPA_AQS_static(options)
print('monitors downloaded')

# write monitors to temp(?) table
dbWriteTable(con, "meta_epa_monitors", EPA_monitors$data, is.temp=TRUE)


##
# get EPA AQS PM25 data from API, instantiate attribute table, and load
##

# get EPA AQS data from API
# TODO: fetch from pre-calculated file
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
aqs_data = fetch_EPA_AQS_api(options)
print('EPA AQS PM2.5 data for Florida downloaded')

# create attribute table
# TODO: incorporate query parameters into table metadata for index
aqs_pm25_api_meta <- list(
  attr_type_concept_id = 0,
  attr_type_source_value = 'EPA AQS PM2.5',
  attr_of_geom_index_id = index_id_geom_epa_aqs_sites,
  geom_source_coding = 'State FIPS - County FIPS - EPA Site Number AS SS-CCC-NNNN',
  schema = 'public',
  table_name = 'attr_fl_epa_pm25_2018_api',
  table_desc = paste0('Sourced from EPA API ',
                      aqs_data$api_query,
                      '. See https://aqs.epa.gov/aqsweb/documents/codetables/methods_all.html for documentation.'),
  data_source_id = 0
)
instantiate_attr(con,aqs_pm25_api_meta,aqs_sites_meta$table_name)
print('attr table created')

# load AQS data from API into attr table
load_EPA_AQS_api_attr(con,aqs_data$data,aqs_sites_meta$table_name,aqs_pm25_api_meta$table_name)
print('Florida data uploaded to attr table')


##
# get EPA AQS PM25 data from static precomputed, instantiate attribute table, and load
##

# fetch EPS AQS precomputed daily PM2.5 from static file
year <- '2020'
parameter_code <- '88101'
filename <- paste0("daily_",parameter_code,"_",year)
options <- list(
    base_download_url = "https://aqs.epa.gov/aqsweb/airdata/",
    file_download = paste0(filename,".zip"),
    file_name = paste0(filename,".csv")
)
EPA_daily <- fetch_EPA_AQS_static(options)
print('daily downloaded')

# create attribute table
# TODO: incorporate query parameters into table metadata for index
aqs_pm25_static_meta <- list(
  attr_type_concept_id = 0,
  attr_type_source_value = '2020 EPA Daily PM2.5',
  attr_of_geom_index_id = index_id_geom_epa_aqs_sites,
  geom_source_coding = 'State FIPS - County FIPS - EPA Site Number AS SS-CCC-NNNN',
  schema = 'public',
  table_name = 'attr_epa_pm25_2020_static',
  table_desc = paste0('Sourced from pre-calculated csv (zip) file of EPA AQS data available from ',EPA_daily$download_url,'.'),
  data_source_id = 0,
  attr_meta_id = 'CONCAT(
                  LPAD(\"State.Code\"::varchar,2,\'0\'),\'-\',
                  LPAD(\"County.Code\"::varchar,3,\'0\'),\'-\',
                  LPAD(\"Site.Num\"::varchar,4,\'0\'),\'-\',
                  LPAD(\"Parameter.Code\"::varchar,5,\'0\'),\'-\',
                  \"POC\"::varchar)'
)
instantiate_attr(con,aqs_pm25_static_meta,aqs_sites_meta$table_name)
print('attr table created')

# load AQS data from static file into attr table
load_EPA_AQS_static_attr(con,EPA_daily$data,aqs_sites_meta$table_name,aqs_pm25_static_meta$table_name)


# close db connection
dbDisconnect(con)