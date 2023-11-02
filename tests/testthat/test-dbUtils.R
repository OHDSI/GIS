system('docker-compose -f ./inst/gaiaTest/docker-compose.yml up -d')

testConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = "localhost/gaiaTest",
  port = 5431,
  user="postgres",
  password = "mysecretpassword"
)

initializeDatabase(testConnectionDetails, testing = T)

library(gaiaCore)


# initializeDatabase()
testthat::test_that("database initializes", {
  conn <- DatabaseConnector::connect(testConnectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  
  schema_created <- DatabaseConnector::querySql(conn, "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'backbone')")[[1]]
  testthat::expect_equal(schema_created, "t")
  
  backbone_tables <- c('attr_index', 'geom_index', 'attr_template', 'geom_template', 'data_source', 'variable_source')
  tables_exist <- unlist(lapply(backbone_tables, function(x) DatabaseConnector::existsTable(conn, 'backbone', x)))
  testthat::expect_true(all(tables_exist))
  
  expected_data_source_rows <- nrow(readr::read_csv(system.file("inst/csv", "test_data_source.csv", package = "gaiaCore")))
  actual_data_source_rows <- DatabaseConnector::querySql(conn, "SELECT count(*) FROM backbone.data_source")[[1]]
  testthat::expect_equal(actual_data_source_rows, expected_data_source_rows)
  
  expected_variable_source_rows <- nrow(readr::read_csv(system.file("inst/csv", "test_variable_source.csv", package = "gaiaCore"), ))
  actual_variable_source_rows <- DatabaseConnector::querySql(conn, "SELECT count(*) FROM backbone.variable_source")[[1]]
  testthat::expect_equal(actual_variable_source_rows, expected_variable_source_rows)
})

# createIndices()
testthat::test_that("data_sources are indexed", {
  conn <- DatabaseConnector::connect(testConnectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  
  data_source <- DatabaseConnector::querySql(conn, "SELECT * FROM backbone.data_source")
  geom_index <- DatabaseConnector::querySql(conn, "SELECT * FROM backbone.geom_index")
  attr_index <- DatabaseConnector::querySql(conn, "SELECT * FROM backbone.attr_index")
  
  geom_ids <- subset(data_source, !is.na(data_source$GEOM_TYPE))[['DATA_SOURCE_UUID']]
  attr_ids <- subset(data_source, data_source$HAS_ATTRIBUTES == 1)[['DATA_SOURCE_UUID']]
  
  testthat::expect_true(all(geom_ids %in% geom_index$DATA_SOURCE_ID))
  testthat::expect_true(all(attr_ids %in% attr_index$DATA_SOURCE_ID))
  
})


system('docker-compose -f ./inst/gaiaTest/docker-compose.yml down')

system('docker volume rm test_pgdata')
