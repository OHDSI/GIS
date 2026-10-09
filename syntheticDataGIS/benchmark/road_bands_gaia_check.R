#!/usr/bin/env Rscript
# Checks Gaia's road-band assignment (synthetic_road_proximity) against the exact distance to the nearest road.
#   Rscript benchmark/road_bands_gaia_check.R [--server localhost/gaiacore] [--cdm omopgis] [--out DIR] [--assert]
suppressPackageStartupMessages({ library(dplyr); library(readr); library(gaiaCore); library(DatabaseConnector) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
server <- arg("server", "localhost/gaiacore"); cdm <- arg("cdm", "omopgis"); outDir <- arg("out", "syntheticDataGIS/benchmark/output/roads_check"); doAssert <- "--assert" %in% args
dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
edges <- c(50, 100, 200, 400); increments <- c(1.693, 1.213, 0.736, 0.271); tolerance <- 0.08

connection <- connectGaia(createGaiaConnectionDetails(server = server))
stopifnot("the working schema is not empty" = querySql(connection, "SELECT count(*) AS n FROM working.location")$N == 0)
loadLocationsFromOmop(connection, cdmSchema = cdm)
loadVariables(connection, "synthetic_road_proximity", geomLabel = "band")
n <- spatialJoin(connection, "road_increment", "synthetic_road_proximity", exposureTypeConceptId = 2052499878)
vars <- listVariables(connection); src <- vars$variable_source_id[vars$table_name == "synthetic_road_proximity" & vars$variable_name == "road_increment"]
gaia <- getExposure(connection, sourceValue = as.character(src)) %>% group_by(location_id) %>% summarise(gaia = mean(value_as_number), rows = n(), .groups = "drop")

executeSql(connection, "CREATE TEMP TABLE roads5070 AS SELECT ST_Transform(geom, 5070) AS geom FROM us_2019_prisecroads_tl;
                        CREATE INDEX ON roads5070 USING gist (geom);", progressBar = FALSE, reportOverallTime = FALSE)
direct <- querySql(connection, "SELECT l.location_id, d.dist FROM working.location l
  CROSS JOIN LATERAL (SELECT ST_Distance(ST_Transform(l.geom, 5070), r.geom) AS dist FROM roads5070 r
                      ORDER BY r.geom <-> ST_Transform(l.geom, 5070) LIMIT 1) d")
names(direct) <- tolower(names(direct))
d <- direct %>% left_join(gaia, by = "location_id") %>% mutate(gaia = coalesce(gaia, 0))
band <- findInterval(d$dist, c(0, edges)); d$expected <- ifelse(band >= 1 & band <= 4, increments[pmax(band, 1)], 0)
nearEdge <- vapply(d$dist, function(x) any(abs(x - edges) / edges < tolerance), logical(1))
clear <- d[!nearEdge, ]
res <- tibble(locations = nrow(d), joined_rows = n, within_400m_gaia = sum(d$gaia > 0), within_400m_exact = sum(d$dist < 400),
              near_band_edge = sum(nearEdge), compared = nrow(clear), agree = sum(abs(clear$gaia - clear$expected) < 1e-6),
              disagree = sum(abs(clear$gaia - clear$expected) >= 1e-6), duplicate_rows = sum(gaia$rows > 1))
write_csv(res, file.path(outDir, "road_bands_gaia_check.csv")); print(as.data.frame(res))
clearExposure(connection)
executeSql(connection, "TRUNCATE working.location_history, working.location CASCADE;", progressBar = FALSE, reportOverallTime = FALSE)
disconnectGaia(connection)
if (doAssert && (res$disagree > 0 || res$duplicate_rows > 0 || res$compared < 0.9 * res$locations)) stop("Road band check failed", call. = FALSE)
if (doAssert) message("Road band check passed")
