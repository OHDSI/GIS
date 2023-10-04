# plumber.R

library(gaiaCore)
library(DatabaseConnector)
library(plumber)

# set database connection 
# from R docker container to gaiaDB docker container - network gaiadb_default
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = "gis_postgis/gaiaDB",
  port = 5432,
  user="postgres",
  password = "mysecretpassword") 

# initialize DB connection
gaiaCore::initializeDatabase(connectionDetails)

# configure and run endpoint
root <- pr("plumber.R")
root %>% pr_run(port=8000,host='0.0.0.0')