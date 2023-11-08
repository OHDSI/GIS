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

# getStaged()
testthat::test_that("unpersisted geometry data is staged", {
  conn <- DatabaseConnector::connect(testConnectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  
  storageConfigStubNoPersist <- list(`offline-storage` = list(`directory` = "./storage", `persist-data` = FALSE))
  
  recStub <- getDataSourceRecord(testConnectionDetails, dataSourceUuid = 10177)
  
  staged <- getStaged(dataSourceRecord, storageConfig = readStorageConfig())
  
  testthat::expect_true(all(class(staged) == c("sf", "data.frame")))
})


# cleanup
unlink(file.path(tempdir(), 'gaia'), recursive = TRUE)

system('docker-compose -f ./inst/gaiaTest/docker-compose.yml down')

system('docker volume rm test_pgdata')