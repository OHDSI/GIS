#!/usr/bin/env Rscript --vanilla

install.packages("DBI",repos = "http://cran.us.r-project.org")
install.packages("RPostgres",repos = "http://cran.us.r-project.org")
library(DBI)

# load OMOP dbutils.R
source('../R/dbutils.R')
source('./EPA_loader.R')

con <- db_con()
instantiate_geom(con,'geo_us_epa_aqs_sites','attr_us_epa_pm25_2018')
EPA_sites = fetch_EPA_sites_from_file()
dbload(EPA_sites,'geo_us_epa_aqs_sites')
dbDisconnect(con)