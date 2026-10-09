#!/usr/bin/env Rscript
# Propagation of geocoding error into PM2.5 exposure and effect estimates (tract benchmark dataset).
#   Rscript benchmark/geocoding_error_propagation.R --data-dir <dir> --exposure <file> --mc <mc_assignment.csv.gz> --truth <mc_location_truth.csv> --pm25-source-tract <id> --pm25-source-county <id> --ses-source <id> [--out DIR] [--reps N] [--cores N]

suppressPackageStartupMessages({ library(dplyr); library(readr); library(parallel); library(tibble) })

args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
dataDir <- arg("data-dir"); exposureFile <- arg("exposure"); mcFile <- arg("mc"); truthFile <- arg("truth")
srcTract <- arg("pm25-source-tract"); srcCounty <- arg("pm25-source-county"); srcSes <- arg("ses-source")
outDir <- arg("out", "syntheticDataGIS/benchmark/output"); maxReps <- as.integer(arg("reps", "1000000"))
cores <- as.integer(arg("cores", as.character(max(1, min(4, detectCores() - 1)))))
stopifnot(!is.na(dataDir), !is.na(exposureFile), !is.na(mcFile), !is.na(truthFile), !is.na(srcTract), !is.na(srcCounty), !is.na(srcSes))
dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)

truth <- read("generator_truth.csv")
person <- read("person.csv") %>% select(person_id, gender_concept_id, year_of_birth) %>% arrange(person_id)
loc <- read("location_history.csv") %>% transmute(location_id, person_id = entity_id, res_start = as.Date(start_date), res_end = as.Date(end_date)) %>% arrange(location_id)
locTruth <- read_csv(truthFile, show_col_types = FALSE, col_types = cols(.default = col_character())) %>% mutate(location_id = as.integer(location_id))
tractRef <- read("tract_reference.csv", col_types = cols(tract_geoid = col_character())) %>% select(tract_geoid, ses_index)
countyRef <- read("county_reference.csv") %>% select(county_ref_id, urban_density_category)
firstLoc <- loc %>% group_by(person_id) %>% slice_min(res_start, n = 1, with_ties = FALSE) %>% ungroup() %>%
  inner_join(read("location.csv") %>% select(location_id, county_ref_id), by = "location_id") %>% inner_join(countyRef, by = "county_ref_id") %>%
  transmute(person_id, county = county_ref_id, stratum = ifelse(urban_density_category %in% c("Urban Core", "Suburban"), "urban", "rural"))
d <- person %>% inner_join(firstLoc, by = "person_id") %>%
  mutate(female = as.numeric(gender_concept_id == 8532), age_decades = (2016 - year_of_birth) / 10)
conditions <- read("condition_occurrence.csv") %>% distinct(person_id, outcome_name = condition_source_value)
Y <- vapply(truth$outcome_name, function(o) as.numeric(d$person_id %in% conditions$person_id[conditions$outcome_name == o]), numeric(nrow(d)))

months <- seq(as.Date("2014-01-01"), by = "month", length.out = 72); mStart <- months; mEnd <- seq(as.Date("2014-02-01"), by = "month", length.out = 72) - 1
matrixOf <- function(file, col) {
  m <- read(file, col_types = cols(.default = col_character())) %>% transmute(unit = .data[[col]], mi = match(as.Date(start_date), mStart), v = as.numeric(pm25_mean_pred))
  units <- sort(unique(m$unit)); M <- matrix(NA_real_, length(units), 72, dimnames = list(units, NULL)); M[cbind(match(m$unit, units), m$mi)] <- m$v; M
}
Mtract <- matrixOf("tract_pm25_monthly.csv.gz", "tract_geoid"); Mcounty <- matrixOf("county_pm25_monthly.csv.gz", "county_fips")
nLoc <- nrow(loc)
W <- pmax(pmin(matrix(as.numeric(loc$res_end), nLoc, 72), matrix(as.numeric(mEnd), nLoc, 72, byrow = TRUE)) -
          pmax(matrix(as.numeric(loc$res_start), nLoc, 72), matrix(as.numeric(mStart), nLoc, 72, byrow = TRUE)) + 1, 0)
locDays <- rowSums(W)
sesOf <- setNames(tractRef$ses_index, tractRef$tract_geoid)

personExposure <- function(unitIdx, M, values = NULL) {
  e <- if (is.null(values)) rowSums(W * M[unitIdx, , drop = FALSE], na.rm = FALSE) / locDays else values
  ok <- !is.na(e)
  num <- rowsum(ifelse(ok, e * locDays, 0), loc$person_id); den <- rowsum(ifelse(ok, locDays, 0), loc$person_id)
  r <- num[, 1] / den[, 1]; r[den[, 1] == 0] <- NA; r[as.character(d$person_id)]
}

mc <- read_csv(mcFile, show_col_types = FALSE, col_types = cols(.default = col_character())) %>%
  mutate(rep = as.integer(rep), location_id = as.integer(location_id)) %>% filter(rep <= maxReps)
refAssign <- mc %>% filter(rep == 0) %>% arrange(location_id); stopifnot(length(refAssign$location_id) == nrow(loc), all(refAssign$location_id == loc$location_id))
assignFor <- function(r) { a <- mc %>% filter(rep == r) %>% arrange(location_id); stopifnot(length(a$location_id) == nrow(loc), all(a$location_id == loc$location_id)); a }

gaia <- read_csv(exposureFile, show_col_types = FALSE, progress = FALSE,
                 col_select = c(person_id, exposure_start_date, exposure_end_date, exposure_source_value, value_as_number)) %>%
  mutate(exposure_source_value = as.character(exposure_source_value), days = as.numeric(as.Date(exposure_end_date) - as.Date(exposure_start_date)) + 1)
gaiaPerson <- function(src) gaia %>% filter(exposure_source_value == src) %>% group_by(person_id) %>% summarise(m = sum(value_as_number * days) / sum(days), .groups = "drop") %>% { setNames(.$m, .$person_id) }
refTract <- unname(gaiaPerson(srcTract)[as.character(d$person_id)]); refCountyGaia <- unname(gaiaPerson(srcCounty)[as.character(d$person_id)])
refSes <- unname(gaiaPerson(srcSes)[as.character(d$person_id)])
chk <- personExposure(match(refAssign$tract_geoid, rownames(Mtract)), Mtract)
message(sprintf("matrix exposure vs Gaia rows (tract): max abs difference %.2e", max(abs(chk - refTract))))
refCounty <- personExposure(match(refAssign$county_fips, rownames(Mcounty)), Mcounty)
message(sprintf("tract-nested county exposure vs Gaia county rows: %d of %d persons differ by more than 1e-6 ug/m3 (county boundary vintages)",
                sum(abs(refCounty - refCountyGaia) > 1e-6, na.rm = TRUE), length(refCounty)))

fit <- function(X, y, cluster) {
  f <- suppressWarnings(glm.fit(X, y, family = binomial())); mu <- f$fitted.values
  bread <- solve(crossprod(X * sqrt(mu * (1 - mu)))); meat <- crossprod(rowsum(X * (y - mu), cluster))
  g <- length(unique(cluster)); n <- nrow(X); k <- ncol(X)
  v <- (g / (g - 1)) * ((n - 1) / (n - k)) * bread %*% meat %*% bread
  c(beta = unname(f$coefficients[2]), se = sqrt(v[2, 2]))
}
oneRep <- function(r) {
  a <- if (r == 0) refAssign else assignFor(r)
  tIdx <- match(a$tract_geoid, rownames(Mtract)); cIdx <- match(a$county_fips, rownames(Mcounty))
  sesLoc <- unname(sesOf[a$tract_geoid])
  ses <- personExposure(NULL, NULL, values = sesLoc)
  out <- list(); mis <- list()
  for (res in c("tract", "county")) {
    x <- if (res == "tract") personExposure(tIdx, Mtract) else personExposure(cIdx, Mcounty)
    ref <- if (res == "tract") refTract else refCounty
    same <- if (res == "tract") a$tract_geoid == refAssign$tract_geoid else a$county_fips == refAssign$county_fips
    for (st in c("all", "urban", "rural")) {
      sel <- (st == "all" | d$stratum == st) & !is.na(x) & !is.na(ses)
      locSel <- loc$person_id %in% d$person_id[d$stratum == st | st == "all"]
      mis[[length(mis) + 1]] <- tibble(rep = r, resolution = res, stratum = st, share_reassigned = mean(!(same[locSel] %in% TRUE)),
        share_unassigned = mean(is.na(if (res == "tract") a$tract_geoid[locSel] else a$county_fips[locSel])),
        bias = mean(x[sel] - ref[sel]), rmse = sqrt(mean((x[sel] - ref[sel])^2)), correlation = cor(x[sel], ref[sel]), slope = unname(coef(lm(x[sel] ~ ref[sel]))[2]), persons = sum(sel))
      X <- cbind(1, x[sel], (ses[sel] - 50) / 15, d$age_decades[sel], d$female[sel])
      for (i in seq_len(nrow(truth))) out[[length(out) + 1]] <- tibble(rep = r, resolution = res, stratum = st, outcome = truth$outcome_name[i], as_tibble_row(fit(X, Y[sel, i], d$county[sel])))
    }
  }
  list(effects = bind_rows(out), mis = bind_rows(mis))
}

reps <- sort(unique(mc$rep[mc$rep > 0]))
message(sprintf("%d replicates (+ the error-free reference), %d outcomes, %d cores", length(reps), nrow(truth), cores))
base <- oneRep(0)
runs <- mclapply(reps, function(r) tryCatch({ res <- oneRep(r); message("replicate ", r, " done"); res }, error = function(e) {
  message("replicate ", r, " failed: ", conditionMessage(e), " | in: ", paste(deparse(conditionCall(e)), collapse = " ")); NULL
}), mc.cores = cores)
runs <- Filter(Negate(is.null), runs)
stopifnot(length(runs) > 0)
effects <- bind_rows(lapply(runs, `[[`, "effects")); mis <- bind_rows(lapply(runs, `[[`, "mis"))

misSummary <- mis %>% group_by(resolution, stratum) %>%
  summarise(replicates = n(), share_locations_reassigned = mean(share_reassigned), share_locations_unassigned = mean(share_unassigned),
            exposure_bias = mean(bias), exposure_rmse = mean(rmse), correlation_with_error_free = mean(correlation), slope_on_error_free = mean(slope), .groups = "drop")
write_csv(misSummary %>% mutate(across(where(is.numeric), ~ round(.x, 4))), file.path(outDir, "geocoding_error_misclassification.csv"))

baseline <- base$effects %>% transmute(resolution, stratum, outcome, error_free_estimate = beta, error_free_se = se)
effSummary <- effects %>% left_join(truth %>% transmute(outcome = outcome_name, truth = beta_pm25_per_ugm3), by = "outcome") %>%
  mutate(covers = abs(beta - truth) <= qnorm(0.975) * se) %>%
  group_by(resolution, stratum, outcome, truth) %>%
  summarise(mean_estimate = mean(beta), mc_sd = sd(beta), mean_se = mean(se), coverage_of_truth = mean(covers), .groups = "drop") %>%
  left_join(baseline, by = c("resolution", "stratum", "outcome")) %>%
  mutate(bias_vs_truth = mean_estimate - truth, shift_vs_error_free = mean_estimate - error_free_estimate, sd_over_se = mc_sd / mean_se) %>%
  arrange(resolution, stratum, desc(truth), outcome)
write_csv(effSummary %>% mutate(across(where(is.numeric), ~ round(.x, 4))), file.path(outDir, "geocoding_error_effects.csv"))
print(as.data.frame(misSummary %>% mutate(across(where(is.numeric), ~ round(.x, 4)))))
print(as.data.frame(effSummary %>% filter(stratum == "all", outcome %in% c("COPD", "CKD", "T2DM")) %>% mutate(across(where(is.numeric), ~ round(.x, 4)))), digits = 3)
