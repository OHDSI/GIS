#!/usr/bin/env Rscript
# Runs Achilles, the Data Quality Dashboard and Achilles::exportToAres() on the DuckDB CDM built by
# build_cdm.R and writes an ARES data folder.
#
# Usage: Rscript run_ares_pipeline.R <cdm.duckdb> <work dir>
#   <work dir>/ares  receives the ARES data folder (<source>/<release>/...)
# Achilles is taken from the installed package, so install the version you want to test first.
args <- commandArgs(trailingOnly = TRUE)
dbFile <- args[1]; work <- args[2]
sourceName <- "OHDSI GIS tutorial dataset (synthetic)"

suppressMessages(library(DatabaseConnector))
cat("Achilles", as.character(packageVersion("Achilles")), "| exportGeoToAres available:",
    exists("exportGeoToAres", asNamespace("Achilles")), "\n")
connectionDetails <- createConnectionDetails(dbms = "duckdb", server = dbFile)
dir.create(file.path(work, "ares"), showWarnings = FALSE, recursive = TRUE)

# 1. Achilles characterization
Achilles::achilles(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = "main", resultsDatabaseSchema = "main", vocabDatabaseSchema = "main",
  sourceName = sourceName, cdmVersion = "5.4",
  numThreads = 1, createTable = TRUE, smallCellCount = 5,
  outputFolder = file.path(work, "achilles"), verboseMode = FALSE, optimizeAtlasCache = FALSE
)

# 2. Data Quality Dashboard
dqdFile <- "dq-result.json"
DataQualityDashboard::executeDqChecks(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = "main", resultsDatabaseSchema = "main",
  cdmSourceName = sourceName, cdmVersion = "5.4",
  numThreads = 1, sqlOnly = FALSE, writeToTable = FALSE,
  outputFolder = file.path(work, "dqd"), outputFile = dqdFile, verboseMode = FALSE
)

# 3. ARES export (includes the geographic export when external_exposure has data)
Achilles::exportToAres(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = "main", resultsDatabaseSchema = "main", vocabDatabaseSchema = "main",
  outputPath = file.path(work, "ares"),
  geoOptions = list(minCellCount = 3)
)

# DQD output belongs next to the release's other files
release <- list.dirs(file.path(work, "ares"), recursive = FALSE)
release <- list.dirs(release[1], recursive = FALSE, full.names = TRUE)
release <- release[!basename(release) %in% c("concepts", "geo")][1]
file.copy(file.path(work, "dqd", dqdFile), file.path(release, dqdFile), overwrite = TRUE)
cat("ARES release folder:", release, "\n")
