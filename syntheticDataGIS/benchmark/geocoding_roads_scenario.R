#!/usr/bin/env Rscript
# Road-proximity scenario of the geocoding stress test (tract benchmark persons, real road geometry, simulated near-road increment).
#   Rscript benchmark/geocoding_roads_scenario.R --data-dir <dir> --mc-dir <dir with <geocoder>/mc_assignment.csv.gz> [--out DIR] [--reps N] [--cores N]
suppressPackageStartupMessages({ library(dplyr); library(readr); library(tibble); library(parallel) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
dataDir <- arg("data-dir"); mcDir <- arg("mc-dir"); outDir <- arg("out", "syntheticDataGIS/benchmark/output/roads")
maxReps <- as.integer(arg("reps", "1000000")); cores <- as.integer(arg("cores", "4")); seed <- 20261020L
stopifnot(!is.na(dataDir), !is.na(mcDir)); dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)
geocoders <- c(nominatim = "Nominatim", arcgis = "ArcGIS Pro", degauss = "DeGAUSS", postgis = "PostGIS TIGER")
geocoders <- geocoders[file.exists(file.path(mcDir, names(geocoders), "mc_assignment.csv.gz"))]; stopifnot(length(geocoders) > 0)

truth <- read("generator_truth.csv"); params <- read("generator_params.csv"); P <- setNames(params$value, params$param)
person <- read("person.csv") %>% select(person_id, gender_concept_id, year_of_birth) %>% arrange(person_id)
loc <- read("location_history.csv") %>% transmute(location_id, person_id = entity_id, res_start = as.Date(start_date), res_end = as.Date(end_date)) %>% arrange(location_id)
locInfo <- read("location.csv", col_types = cols(tract_geoid = col_character())) %>% select(location_id, county_ref_id, tract_geoid)
tractRef <- read("tract_reference.csv", col_types = cols(tract_geoid = col_character())) %>% select(tract_geoid, ses_index)
firstLoc <- loc %>% group_by(person_id) %>% slice_min(res_start, n = 1, with_ties = FALSE) %>% ungroup() %>% inner_join(locInfo, by = "location_id")
cluster <- firstLoc$county_ref_id[match(person$person_id, firstLoc$person_id)]
age <- 2016 - person$year_of_birth; female <- as.numeric(person$gender_concept_id == 8532)
months <- seq(as.Date("2014-01-01"), by = "month", length.out = 72); mStart <- months; mEnd <- seq(as.Date("2014-02-01"), by = "month", length.out = 72) - 1
Mraw <- read("tract_pm25_monthly.csv.gz", col_types = cols(.default = col_character())) %>% transmute(unit = tract_geoid, mi = match(as.Date(start_date), mStart), v = as.numeric(pm25_mean_pred))
units <- sort(unique(Mraw$unit)); Mtract <- matrix(NA_real_, length(units), 72, dimnames = list(units, NULL)); Mtract[cbind(match(Mraw$unit, units), Mraw$mi)] <- Mraw$v
nLoc <- nrow(loc)
W <- pmax(pmin(matrix(as.numeric(loc$res_end), nLoc, 72), matrix(as.numeric(mEnd), nLoc, 72, byrow = TRUE)) -
          pmax(matrix(as.numeric(loc$res_start), nLoc, 72), matrix(as.numeric(mStart), nLoc, 72, byrow = TRUE)) + 1, 0)
locDays <- rowSums(W)
personMean <- function(e) { ok <- !is.na(e); num <- rowsum(ifelse(ok, e * locDays, 0), loc$person_id); den <- rowsum(ifelse(ok, locDays, 0), loc$person_id)
  r <- num[, 1] / den[, 1]; r[den[, 1] == 0] <- NA; r[as.character(person$person_id)] }
tractExposure <- function(geoid) personMean(rowSums(W * Mtract[match(geoid, rownames(Mtract)), , drop = FALSE]) / locDays)
ses <- personMean(tractRef$ses_index[match(locInfo$tract_geoid[match(loc$location_id, locInfo$location_id)], tractRef$tract_geoid)])
stopifnot(!anyNA(cluster), !anyNA(ses))
frailtyCounty <- sort(unique(locInfo$county_ref_id))

fit <- function(X, y, cluster, js) {
  f <- suppressWarnings(glm.fit(X, y, family = binomial())); mu <- f$fitted.values
  bread <- solve(crossprod(X * sqrt(mu * (1 - mu)))); meat <- crossprod(rowsum(X * (y - mu), cluster))
  g <- length(unique(cluster)); n <- nrow(X); k <- ncol(X)
  v <- (g / (g - 1)) * ((n - 1) / (n - k)) * bread %*% meat %*% bread
  c(unname(f$coefficients[js]), sqrt(diag(v)[js]))
}
cov <- cbind((ses - 50) / 15, age / 10, female)

oneGeocoder <- function(g) {
  mc <- read_csv(file.path(mcDir, g, "mc_assignment.csv.gz"), show_col_types = FALSE, col_types = cols(.default = col_character())) %>%
    mutate(rep = as.integer(rep), location_id = as.integer(location_id), band_increment = as.numeric(band_increment)) %>% filter(rep <= maxReps) %>% arrange(rep, location_id)
  stopifnot("mc file has no band_increment column; run geocoding_error_mc.sh --bands" = !all(is.na(mc$band_increment)))
  split_mc <- split(mc, mc$rep); ref <- split_mc[["0"]]; stopifnot(length(ref$location_id) == nrow(loc), all(ref$location_id == loc$location_id))
  xt0 <- tractExposure(ref$tract_geoid); xi0 <- personMean(ref$band_increment)
  oneRep <- function(r) {
    a <- split_mc[[as.character(r)]]; set.seed(seed + r)
    xt <- tractExposure(a$tract_geoid); xi <- personMean(a$band_increment)
    u <- rnorm(length(frailtyCounty), 0, P[["county_frailty_sd"]]); frailty <- personMean(u[match(locInfo$county_ref_id[match(loc$location_id, locInfo$location_id)], frailtyCounty)])
    total <- xt0 + xi0
    out <- list()
    for (i in seq_len(nrow(truth))) {
      lin <- log(truth$prevalence_ref[i] / (1 - truth$prevalence_ref[i])) + truth$beta_pm25_per_ugm3[i] * (total - P[["pm25_ref_ugm3"]]) +
        truth$beta_ses_per_sd[i] * (ses - P[["ses_ref"]]) / P[["ses_sd"]] + truth$beta_age_per_decade[i] * (age - P[["age_ref"]]) / 10 + truth$beta_female[i] * female + frailty
      y <- as.numeric(runif(length(total)) < plogis(lin))
      for (nm in c("true", "displaced")) {
        X <- if (nm == "true") cbind(1, xt0, xi0, cov) else cbind(1, xt, xi, cov); ok <- stats::complete.cases(X)
        r2 <- fit(X[ok, , drop = FALSE], y[ok], cluster[ok], 2:3)
        out[[length(out) + 1]] <- tibble(rep = r, outcome = truth$outcome_name[i], truth = truth$beta_pm25_per_ugm3[i], location = nm,
                                        beta_tract = r2[1], beta_road = r2[2], se_tract = r2[3], se_road = r2[4])
      }
    }
    list(effects = bind_rows(out), expo = tibble(rep = r, cor_tract = cor(xt, xt0, use = "complete.obs"), cor_road = cor(xi, xi0, use = "complete.obs"),
                                                share_road_band_changed = mean(a$band_increment != ref$band_increment), share_near_road = mean(ref$band_increment > 0),
                                                share_road_increment_zero_to_positive = mean(ref$band_increment == 0 & a$band_increment > 0)))
  }
  reps <- sort(as.integer(setdiff(names(split_mc), "0")))
  runs <- mclapply(reps, function(r) tryCatch({ x <- oneRep(r); message(g, " replicate ", r, " done"); x }, error = function(e) { message("replicate ", r, " failed: ", conditionMessage(e)); NULL }), mc.cores = cores)
  runs <- Filter(Negate(is.null), runs); stopifnot(length(runs) > 0)
  list(effects = bind_rows(lapply(runs, `[[`, "effects")) %>% mutate(geocoder = g), expo = bind_rows(lapply(runs, `[[`, "expo")) %>% mutate(geocoder = g))
}
res <- lapply(names(geocoders), oneGeocoder)
eff <- bind_rows(lapply(res, `[[`, "effects")); expo <- bind_rows(lapply(res, `[[`, "expo"))
write_csv(eff, file.path(outDir, "roads_scenario_replicates.csv.gz"))
long <- eff %>% tidyr::pivot_longer(c(beta_tract, beta_road, se_tract, se_road), names_to = c(".value", "component"), names_pattern = "(beta|se)_(tract|road)")
summ <- long %>% group_by(geocoder, component, outcome, truth, location) %>% summarise(mean_beta = mean(beta), mean_se = mean(se), coverage = mean(abs(beta - truth) <= 1.96 * se), .groups = "drop")
write_csv(summ %>% mutate(across(where(is.numeric), ~ round(.x, 5))), file.path(outDir, "roads_scenario_by_outcome.csv"))
headline <- summ %>% filter(truth > 0) %>% group_by(geocoder, component, location) %>% summarise(sum_beta = sum(mean_beta), sum_truth = sum(truth), coverage = mean(coverage), .groups = "drop") %>%
  mutate(recovery = sum_beta / sum_truth) %>% select(-sum_beta, -sum_truth) %>% tidyr::pivot_wider(names_from = location, values_from = c(recovery, coverage)) %>%
  mutate(attenuation = recovery_displaced / recovery_true)
headline <- headline %>% left_join(expo %>% group_by(geocoder) %>% summarise(across(c(cor_tract, cor_road, share_road_band_changed, share_near_road, share_road_increment_zero_to_positive), mean), .groups = "drop"), by = "geocoder") %>%
  mutate(across(where(is.numeric), ~ round(.x, 4)))
write_csv(headline, file.path(outDir, "roads_scenario_summary.csv")); print(as.data.frame(headline), digits = 3)
