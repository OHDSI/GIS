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
EPA_sites <- fetch_EPA_precalculated(options)
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
load_EPA_sites(con, EPA_sites$data, "geom_epa_aqs_sites")
print('US sites uploaded to db')


##
# get EPA AQS PM25 data, instantiate attribute table, and load
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
aqs_data = fetch_EPA_AQS_from_api(options)
print('EPA AQS PM2.5 data for Florida downloaded')

# create attribute table
# TODO: incorporate query parameters into table metadata for index
aqs_pm25_meta <- list(
  attr_type_concept_id = 0,
  attr_type_source_value = 'EPA AQS PM2.5',
  attr_of_geom_index_id = index_id_geom_epa_aqs_sites,
  geom_source_coding = 'State FIPS - County FIPS - EPA Site Number AS SS-CCC-NNNN',
  schema = 'public',
  table_name = 'attr_fl_epa_pm25_2018',
  table_desc = paste0('Sourced from EPA API ',
                      aqs_data$api_query,
                      '. See https://aqs.epa.gov/aqsweb/documents/codetables/methods_all.html for documentation.'),
  data_source_id = 0
)
instantiate_attr(con,aqs_pm25_meta,aqs_sites_meta$table_name)
print('attr table created')

# load AQS data into attr table
load_EPA_attr(con,aqs_data$data,aqs_sites_meta$table_name,aqs_pm25_meta$table_name)
print('Florida data uploaded to attr table')


# close db connection
dbDisconnect(con)