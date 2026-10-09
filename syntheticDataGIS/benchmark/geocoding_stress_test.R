#!/usr/bin/env Rscript
# Stress test of geocoding error with a sharply varying synthetic exposure surface (tract benchmark persons).
#   Rscript benchmark/geocoding_stress_test.R --data-dir <dir> --errors <dir> [--scales 100,1000,10000] [--reps 200] [--cores 4] [--sd 1.9] [--mean 9] [--features 1000] [--seed 20261020] [--out DIR]
suppressPackageStartupMessages({ library(dplyr); library(readr); library(tibble); library(parallel); library(sf) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
dataDir <- arg("data-dir"); errDir <- arg("errors"); outDir <- arg("out", "syntheticDataGIS/benchmark/output/stress")
scales <- as.numeric(strsplit(arg("scales", "100,1000,10000"), ",")[[1]]); reps <- as.integer(arg("reps", "200"))
cores <- as.integer(arg("cores", "4")); sdX <- as.numeric(arg("sd", "1.9")); meanX <- as.numeric(arg("mean", "9"))
nFeat <- as.integer(arg("features", "1000")); seed <- as.integer(arg("seed", "20261020"))
stopifnot(!is.na(dataDir), !is.na(errDir)); dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)

truth <- read("generator_truth.csv"); params <- read("generator_params.csv"); P <- setNames(params$value, params$param)
person <- read("person.csv") %>% select(person_id, gender_concept_id, year_of_birth) %>% arrange(person_id)
loc <- read("location.csv", col_types = cols(tract_geoid = col_character())) %>% select(location_id, latitude, longitude, county_ref_id, tract_geoid)
lh <- read("location_history.csv") %>% transmute(location_id, person_id = entity_id, days = as.numeric(as.Date(end_date) - as.Date(start_date)) + 1, start = as.Date(start_date)) %>% arrange(location_id)
tractRef <- read("tract_reference.csv", col_types = cols(tract_geoid = col_character())) %>% select(tract_geoid, ses_index)
L <- lh %>% inner_join(loc, by = "location_id") %>% left_join(tractRef, by = "tract_geoid") %>% arrange(location_id)
xy <- st_coordinates(st_transform(st_as_sf(L, coords = c("longitude", "latitude"), crs = 4326), 5070))
nLoc <- nrow(L); pid <- as.character(L$person_id)
byPerson <- function(v) { num <- rowsum(v * L$days, pid); den <- rowsum(L$days, pid); r <- num[, 1] / den[, 1]; r[as.character(person$person_id)] }
ses <- byPerson(L$ses_index); frailtyCounty <- sort(unique(L$county_ref_id))
firstLoc <- L %>% group_by(person_id) %>% slice_min(start, n = 1, with_ties = FALSE) %>% ungroup()
cluster <- firstLoc$county_ref_id[match(person$person_id, firstLoc$person_id)]
age <- 2016 - person$year_of_birth; female <- as.numeric(person$gender_concept_id == 8532)
stopifnot(!anyNA(ses), !anyNA(cluster))

geocoders <- c(nominatim = "Nominatim", arcgis = "ArcGIS Pro", degauss = "DeGAUSS", postgis = "PostGIS TIGER")
errors <- lapply(names(geocoders), function(g) read_csv(file.path(errDir, paste0("errors_", g, ".csv")), show_col_types = FALSE)$error_m); names(errors) <- names(geocoders)

drawField <- function(L) { w <- matrix(rnorm(2 * nFeat), nFeat, 2) / (L * sqrt(rchisq(nFeat, 1))); list(w = w, ph = runif(nFeat, 0, 2 * pi)) }
evalField <- function(f, pts, chunk = 4000) {
  out <- numeric(nrow(pts))
  for (s in seq(1, nrow(pts), by = chunk)) { i <- s:min(nrow(pts), s + chunk - 1)
    out[i] <- rowSums(cos(sweep(pts[i, , drop = FALSE] %*% t(f$w), 2, f$ph, "+"))) }
  meanX + sdX * sqrt(2 / nFeat) * out
}
fit <- function(X, y, cluster) {
  f <- suppressWarnings(glm.fit(X, y, family = binomial())); mu <- f$fitted.values
  bread <- solve(crossprod(X * sqrt(mu * (1 - mu)))); meat <- crossprod(rowsum(X * (y - mu), cluster))
  g <- length(unique(cluster)); n <- nrow(X); k <- ncol(X)
  v <- (g / (g - 1)) * ((n - 1) / (n - k)) * bread %*% meat %*% bread
  c(beta = unname(f$coefficients[2]), se = sqrt(v[2, 2]))
}
oneTask <- function(task) {
  scale <- task$scale; rep <- task$rep; set.seed(seed + 1009 * rep + as.integer(scale))
  field <- drawField(scale); sTrue <- evalField(field, xy); xTrue <- byPerson(sTrue)
  u <- rnorm(length(frailtyCounty), 0, P[["county_frailty_sd"]]); frailty <- byPerson(u[match(L$county_ref_id, frailtyCounty)])
  lin <- function(i) log(truth$prevalence_ref[i] / (1 - truth$prevalence_ref[i])) + truth$beta_pm25_per_ugm3[i] * (xTrue - P[["pm25_ref_ugm3"]]) +
    truth$beta_ses_per_sd[i] * (ses - P[["ses_ref"]]) / P[["ses_sd"]] + truth$beta_age_per_decade[i] * (age - P[["age_ref"]]) / 10 + truth$beta_female[i] * female + frailty
  Y <- vapply(seq_len(nrow(truth)), function(i) as.numeric(runif(length(xTrue)) < plogis(lin(i))), numeric(length(xTrue)))
  Xs <- list(none = xTrue)
  for (g in names(geocoders)) {
    d <- sample(errors[[g]], nLoc, replace = TRUE); a <- runif(nLoc, 0, 2 * pi)
    Xs[[g]] <- byPerson(evalField(field, xy + cbind(d * cos(a), d * sin(a))))
  }
  out <- list(); expo <- list()
  for (nm in names(Xs)) {
    x <- Xs[[nm]]; cov <- cbind((ses - 50) / 15, age / 10, female)
    if (nm != "none") expo[[length(expo) + 1]] <- tibble(scale_m = scale, rep = rep, geocoder = nm, correlation = cor(x, xTrue), rmse = sqrt(mean((x - xTrue)^2)))
    X <- cbind(1, x, cov)
    for (i in seq_len(nrow(truth))) out[[length(out) + 1]] <- tibble(scale_m = scale, rep = rep, geocoder = nm, outcome = truth$outcome_name[i], as_tibble_row(fit(X, Y[, i], cluster)))
  }
  list(effects = bind_rows(out), exposure = bind_rows(expo))
}
tasks <- unlist(lapply(scales, function(s) lapply(seq_len(reps), function(r) list(scale = s, rep = r))), recursive = FALSE)
message(length(tasks), " tasks (", length(scales), " scales x ", reps, " replicates), ", nLoc, " locations, ", nrow(person), " persons, ", cores, " cores")
runs <- mclapply(tasks, function(t) tryCatch({ r <- oneTask(t); message("scale ", t$scale, " replicate ", t$rep, " done"); r },
                 error = function(e) { message("task failed: ", conditionMessage(e)); NULL }), mc.cores = cores, mc.preschedule = FALSE)
runs <- Filter(Negate(is.null), runs); stopifnot(length(runs) > 0)
eff <- bind_rows(lapply(runs, `[[`, "effects")); expo <- bind_rows(lapply(runs, `[[`, "exposure"))
write_csv(eff, file.path(outDir, "stress_test_replicates.csv.gz"))

truthTab <- truth %>% transmute(outcome = outcome_name, truth = beta_pm25_per_ugm3)
free <- eff %>% filter(geocoder == "none") %>% select(scale_m, rep, outcome, beta_free = beta, se_free = se)
perOutcome <- eff %>% filter(geocoder != "none") %>% inner_join(free, by = c("scale_m", "rep", "outcome")) %>% inner_join(truthTab, by = "outcome") %>%
  group_by(scale_m, geocoder, outcome, truth) %>%
  summarise(error_free_mean = mean(beta_free), displaced_mean = mean(beta), shift = mean(beta - beta_free), sd_shift = sd(beta - beta_free),
            coverage_displaced = mean(abs(beta - truth) <= 1.96 * se), coverage_error_free = mean(abs(beta_free - truth) <= 1.96 * se_free), .groups = "drop")
write_csv(perOutcome %>% mutate(across(where(is.numeric), ~ round(.x, 5))), file.path(outDir, "stress_test_by_outcome.csv"))
theory <- bind_rows(lapply(scales, function(s) tibble(scale_m = s, geocoder = names(geocoders), theory_attenuation = vapply(errors, function(e) mean(exp(-e / s)), numeric(1)))))
summ <- perOutcome %>% filter(truth > 0) %>% group_by(scale_m, geocoder) %>%
  summarise(attenuation = sum(displaced_mean) / sum(error_free_mean), mean_abs_shift = mean(abs(shift)),
            coverage_effects_displaced = mean(coverage_displaced), coverage_effects_error_free = mean(coverage_error_free), .groups = "drop") %>%
  left_join(perOutcome %>% filter(truth == 0) %>% group_by(scale_m, geocoder) %>% summarise(null_shift = mean(shift), coverage_nulls_displaced = mean(coverage_displaced), .groups = "drop"), by = c("scale_m", "geocoder")) %>%
  left_join(expo %>% group_by(scale_m, geocoder) %>% summarise(exposure_correlation = mean(correlation), exposure_rmse = mean(rmse), .groups = "drop"), by = c("scale_m", "geocoder")) %>%
  left_join(theory, by = c("scale_m", "geocoder")) %>% mutate(across(where(is.numeric), ~ round(.x, 4))) %>% arrange(scale_m, geocoder)
write_csv(summ, file.path(outDir, "stress_test_summary.csv"))
print(as.data.frame(summ), digits = 3)
