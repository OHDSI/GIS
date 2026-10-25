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

# Achilles analyses 109 (persons observed in each year) and 110 (in each month) only list the
# years/months in which some observation period *starts*. Every person in this dataset starts in
# January 2014, so both series collapse to a single point and ARES reports the observation period as
# ending in 2014-01. Recompute them over the full span (DuckDB SQL).
con <- connect(connectionDetails)
executeSql(con, "
  DELETE FROM main.achilles_results WHERE analysis_id IN (109, 110);
  INSERT INTO main.achilles_results (analysis_id, stratum_1, count_value)
  SELECT 109, CAST(y.yr AS VARCHAR), COUNT(DISTINCT op.person_id)
  FROM main.observation_period op,
       (SELECT unnest(range(year(min(observation_period_start_date)),
                            year(max(observation_period_end_date)) + 1)) AS yr FROM main.observation_period) y
  WHERE op.observation_period_start_date <= make_date(y.yr, 1, 1)
    AND op.observation_period_end_date >= make_date(y.yr, 12, 31)
  GROUP BY y.yr;
  INSERT INTO main.achilles_results (analysis_id, stratum_1, count_value)
  SELECT 110, CAST(year(m.d) * 100 + month(m.d) AS VARCHAR), COUNT(DISTINCT op.person_id)
  FROM main.observation_period op,
       (SELECT unnest(generate_series(date_trunc('month', min(observation_period_start_date)),
                                      date_trunc('month', max(observation_period_end_date)),
                                      INTERVAL 1 MONTH)) AS d FROM main.observation_period) m
  WHERE op.observation_period_start_date <= m.d
    AND op.observation_period_end_date >= last_day(m.d)
  GROUP BY m.d;",
  progressBar = FALSE, reportOverallTime = FALSE)
disconnect(con)

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
  geoOptions = list(minCellCount = 1)
)

# DQD output belongs next to the release's other files
release <- list.dirs(file.path(work, "ares"), recursive = FALSE)
release <- list.dirs(release[1], recursive = FALSE, full.names = TRUE)
release <- release[!basename(release) %in% c("concepts", "geo")][1]
file.copy(file.path(work, "dqd", dqdFile), file.path(release, dqdFile), overwrite = TRUE)
cat("ARES release folder:", release, "\n")
