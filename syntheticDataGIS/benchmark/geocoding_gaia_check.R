#!/usr/bin/env Rscript
# Checks the geocoding stress-test surfaces through Gaia: catalog grids joined at true and displaced locations against the analytic surface.
#   Rscript benchmark/geocoding_gaia_check.R --features-dir <dir> --errors <dir> [--data-dir <dir> | --n-synthetic 300] [--server gaia-db/gaiacore] [--reps 3] [--assert] [--out DIR]
suppressPackageStartupMessages({ library(dplyr); library(readr); library(sf); library(gaiaCore); library(DatabaseConnector) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
dataDir <- arg("data-dir"); featDir <- arg("features-dir"); errDir <- arg("errors"); server <- arg("server", "gaia-db/gaiacore")
reps <- as.integer(arg("reps", "3")); doAssert <- "--assert" %in% args; nSynthetic <- as.integer(arg("n-synthetic", "300")); outDir <- arg("out", "syntheticDataGIS/benchmark/output/gaia_check"); dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
scales <- list(`100m` = c(L = 100, cell = 25), `1km` = c(L = 1000, cell = 250), `10km` = c(L = 10000, cell = 2500))
meanX <- 9; sdX <- 1.9; halfWindow <- 5000; center <- c(-118.25, 34.05); geocoders <- c("postgis", "arcgis")

centre5070 <- st_coordinates(st_transform(st_sfc(st_point(center), crs = 4326), 5070))
bbox <- c(centre5070[1] + c(-1, 1) * halfWindow, centre5070[2] + c(-1, 1) * halfWindow)
if (!is.na(dataDir)) {
  loc <- read_csv(file.path(dataDir, "location.csv"), show_col_types = FALSE, progress = FALSE) %>% select(location_id, latitude, longitude, county_ref_id)
  lh <- read_csv(file.path(dataDir, "location_history.csv"), show_col_types = FALSE, progress = FALSE) %>% transmute(location_id, entity_id, start_date = as.Date(start_date), end_date = as.Date(end_date))
  xy <- st_coordinates(st_transform(st_as_sf(loc, coords = c("longitude", "latitude"), crs = 4326), 5070))
  inWin <- xy[, 1] > bbox[1] & xy[, 1] < bbox[2] & xy[, 2] > bbox[3] & xy[, 2] < bbox[4]
  loc <- loc[inWin, ]; xy <- xy[inWin, , drop = FALSE]; lh <- lh %>% filter(location_id %in% loc$location_id)
} else {
  set.seed(1)
  xy <- cbind(runif(nSynthetic, bbox[1], bbox[2]), runif(nSynthetic, bbox[3], bbox[4]))
  loc <- tibble(location_id = seq_len(nSynthetic))
  lh <- tibble(location_id = loc$location_id, entity_id = loc$location_id, start_date = as.Date("2014-01-01"), end_date = as.Date("2019-12-31"))
}
message(nrow(loc), " locations (", length(unique(lh$entity_id)), " persons) in the window")

set.seed(20261020)
errors <- lapply(setNames(geocoders, geocoders), function(g) read_csv(file.path(errDir, paste0("errors_", g, ".csv")), show_col_types = FALSE)$error_m)
pts <- tibble(location_id = loc$location_id, entity_id = lh$entity_id[match(loc$location_id, lh$location_id)], set = "true", x = xy[, 1], y = xy[, 2])
for (g in geocoders) for (r in seq_len(reps)) {
  d <- sample(errors[[g]], nrow(loc), replace = TRUE); a <- runif(nrow(loc), 0, 2 * pi)
  pts <- bind_rows(pts, tibble(location_id = loc$location_id, entity_id = pts$entity_id[seq_len(nrow(loc))], set = paste0(g, "_", r), x = xy[, 1] + d * cos(a), y = xy[, 2] + d * sin(a)))
}
setIdx <- match(pts$set, unique(pts$set)) - 1L
pts$location_id <- pts$location_id + setIdx * 1000000L; pts$entity_id <- pts$entity_id + setIdx * 1000000L
ll <- st_coordinates(st_transform(st_as_sf(pts, coords = c("x", "y"), crs = 5070, remove = FALSE), 4326))
pts$lon <- ll[, 1]; pts$lat <- ll[, 2]
pts$inside <- pts$x > bbox[1] & pts$x < bbox[2] & pts$y > bbox[3] & pts$y < bbox[4]

connection <- connectGaia(createGaiaConnectionDetails(server = server))
executeSql(connection, "TRUNCATE working.location_history, working.location CASCADE;", progressBar = FALSE, reportOverallTime = FALSE)
histBase <- lh %>% select(location_id, start_date, end_date)
loadLocations(connection, data.frame(location_id = pts$location_id, latitude = pts$lat, longitude = pts$lon),
              data.frame(location_id = pts$location_id, entity_id = pts$entity_id, start_date = histBase$start_date[match(pts$location_id %% 1000000L, histBase$location_id)],
                         end_date = histBase$end_date[match(pts$location_id %% 1000000L, histBase$location_id)]))
res <- list()
for (key in names(scales)) {
  tid <- paste0("synthetic_surface_", key); L <- scales[[key]][["L"]]; cell <- scales[[key]][["cell"]]
  loadVariables(connection, tid, geomLabel = "cell_id")
  clearExposure(connection)
  n <- spatialJoin(connection, "pm25_surface", tid, exposureTypeConceptId = 2052499878)
  ex <- getExposure(connection) %>% group_by(location_id) %>% summarise(gaia = mean(value_as_number), rows = n(), .groups = "drop")
  f <- read_csv(file.path(featDir, sprintf("surface_%s_features.csv", key)), show_col_types = FALSE)
  surf <- function(x, y) meanX + sdX * sqrt(2 / nrow(f)) * vapply(seq_along(x), function(i) sum(cos(f$w1 * x[i] + f$w2 * y[i] + f$phase)), numeric(1))
  d <- pts %>% mutate(cx = (floor(x / cell) + 0.5) * cell, cy = (floor(y / cell) + 0.5) * cell) %>% left_join(ex, by = "location_id")
  d$cell_value <- ifelse(d$inside, surf(d$cx, d$cy), NA_real_); d$point_value <- surf(d$x, d$y)
  ok <- d$inside & !is.na(d$gaia)
  res[[key]] <- tibble(surface = key, rows_created = n, points = nrow(d), inside_window = sum(d$inside), joined = sum(ok), unjoined_inside = sum(d$inside & is.na(d$gaia)),
    exact_match_share = mean(abs(d$gaia[ok] - d$cell_value[ok]) < 1e-6), max_abs_diff_cell = max(abs(d$gaia[ok] - d$cell_value[ok])),
    cor_with_point_value = cor(d$gaia[ok], d$point_value[ok]), rmse_vs_point_value = sqrt(mean((d$gaia[ok] - d$point_value[ok])^2)))
  base <- d$location_id %% 1000000L
  trueGaia <- d$gaia[d$set == "true"][match(base, base[d$set == "true"])]
  res[[paste0(key, "_att")]] <- d %>% mutate(trueGaia = trueGaia) %>% filter(set != "true", ok, !is.na(trueGaia)) %>% mutate(geocoder = sub("_.*", "", set)) %>%
    group_by(surface = key, geocoder) %>% summarise(n = n(), gaia_exposure_correlation = cor(gaia, trueGaia), .groups = "drop")
  message(key, ": ", paste(capture.output(print(as.data.frame(res[[key]]))), collapse = "\n"))
  clearExposure(connection)
}
check <- bind_rows(res[names(scales)]); write_csv(check, file.path(outDir, "gaia_check_summary.csv")); print(as.data.frame(check), digits = 5)
corr <- bind_rows(res[paste0(names(scales), "_att")]); write_csv(corr, file.path(outDir, "gaia_check_displaced.csv")); print(as.data.frame(corr), digits = 4)
if (doAssert) {
  fail <- character()
  if (any(check$exact_match_share < 1) || any(check$max_abs_diff_cell > 1e-9)) fail <- c(fail, "Gaia's join does not reproduce the analytic grid values exactly")
  if (any(check$unjoined_inside > 0) || any(check$inside_window < 0.5 * check$points)) fail <- c(fail, "points inside the window were not joined")
  mono <- corr %>% mutate(order = match(surface, names(scales))) %>% arrange(geocoder, order) %>% group_by(geocoder) %>% summarise(ok = all(diff(gaia_exposure_correlation) > 0), .groups = "drop")
  if (!all(mono$ok)) fail <- c(fail, "exposure correlation under displacement does not rise with the correlation length")
  if (length(fail)) stop(paste("Gaia check failed:", paste(fail, collapse = "; ")), call. = FALSE)
  message("Gaia check passed")
}
disconnectGaia(connection)
