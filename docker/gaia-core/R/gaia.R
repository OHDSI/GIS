library(gaiaCore)
library(DatabaseConnector)
library(plumber)

# set database connection 
# from R docker container to gaiaDB docker container - network gaiadb_default
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = paste0("gaia-db/",Sys.getenv(c("POSTGRES_DB"))),
  port = Sys.getenv(c("POSTGRES_PORT")),
  user=Sys.getenv(c("POSTGRES_USER")),
  password = scan(Sys.getenv(c("POSTGRES_PASSWORD_FILE")),"character")) 

# initialize DB connection
gaiaCore::initializeDatabase(connectionDetails)

# configure and run endpoint
root <- pr("plumber.R")
root %>% pr_run(
  port=as.numeric(Sys.getenv(c("GAIA_CORE_API_PORT"))),
  host='0.0.0.0')