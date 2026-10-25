#!/usr/bin/env Rscript
# Builds a DuckDB OMOP CDM v5.4 (+ GIS extension tables) from the tutorial CSV files so that
# Achilles, DQD and exportToAres() can run on it without a database server.
#
# The tutorial `location` table has no county FIPS column (only county_ref_id), so the FIPS code is
# joined in from county_reference.csv and added as the non-standard location.county_fips column that
# Achilles' geographic export reads. external_exposure is loaded from the prebuilt fallback file,
# because the published SQL dump ships that table empty.
#
# Usage: Rscript build_cdm.R <tutorial data dir> <GIS ddl dir> <output .duckdb>
args <- commandArgs(trailingOnly = TRUE)
dataDir <- args[1]; ddlDir <- args[2]; dbFile <- args[3]

suppressMessages({
  library(DatabaseConnector)
  library(DBI)
})
unlink(dbFile)
connectionDetails <- createConnectionDetails(dbms = "duckdb", server = dbFile)

CommonDataModel::executeDdl(
  connectionDetails = connectionDetails,
  cdmVersion = "5.4",
  cdmDatabaseSchema = "main",
  executePrimaryKey = FALSE,
  executeForeignKey = FALSE
)

con <- connect(connectionDetails)
on.exit(disconnect(con))

# GIS extension tables (location_history, external_exposure)
ddl <- paste(readLines(file.path(ddlDir, "OMOPCDM_duckdb_5.4_ddl.sql")), collapse = "\n")
ddl <- SqlRender::render(ddl, cdmDatabaseSchema = "main")
for (stmt in SqlRender::splitSql(ddl)) executeSql(con, stmt, progressBar = FALSE, reportOverallTime = FALSE)
executeSql(con, "ALTER TABLE location ADD COLUMN county_fips VARCHAR(10)", progressBar = FALSE, reportOverallTime = FALSE)

load <- function(table, file) {
  cols <- tolower(dbGetQuery(con, sprintf("SELECT name FROM pragma_table_info('%s')", table))$name)
  src <- dbGetQuery(con, sprintf("SELECT * FROM read_csv_auto('%s', sample_size=-1) LIMIT 0", file))
  use <- intersect(tolower(names(src)), cols)
  list_ <- paste(sprintf('"%s"', use), collapse = ", ")
  n <- dbExecute(con, sprintf(
    "INSERT INTO %s (%s) SELECT %s FROM read_csv_auto('%s', sample_size=-1, all_varchar=true)",
    table, list_, list_, file
  ))
  cat(sprintf("%-22s %8d rows (%d columns)\n", table, n, length(use)))
}

for (t in c("person", "observation_period", "condition_occurrence", "drug_exposure", "procedure_occurrence",
            "measurement", "observation", "episode", "location_history", "concept", "concept_ancestor",
            "concept_relationship", "concept_synonym", "concept_class", "vocabulary", "domain", "relationship",
            "cdm_source")) {
  load(t, file.path(dataDir, paste0(t, ".csv")))
}
n <- dbExecute(con, sprintf("
  INSERT INTO location (location_id, address_1, address_2, city, state, zip, county, location_source_value,
                        country_source_value, latitude, longitude, county_fips)
  SELECT l.location_id, l.address_1, l.address_2, l.city, l.state, l.zip, l.county, l.location_source_value,
         'US', l.latitude, l.longitude, c.county_fips
  FROM read_csv_auto('%s', all_varchar=true) l
  LEFT JOIN read_csv_auto('%s', all_varchar=true) c ON c.county_ref_id = l.county_ref_id",
  file.path(dataDir, "location.csv"), file.path(dataDir, "county_reference.csv")))
cat(sprintf("%-22s %8d rows\n", "location", n))
load("external_exposure", file.path(dataDir, "external_exposure_fallback.csv.gz"))

# the vocabulary extract has the micro sign mangled to "?" in the PM2.5 concept name
dbExecute(con, "UPDATE concept SET concept_name = replace(concept_name, '(?g/M3)', '(\u00b5g/M3)')")
