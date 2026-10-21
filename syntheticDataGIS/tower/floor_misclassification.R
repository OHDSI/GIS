#!/usr/bin/env Rscript
# Usage: Rscript tower/floor_misclassification.R [--data DIR] [--reps 200] [--out DIR]
suppressPackageStartupMessages({ library(dplyr); library(readr); library(jsonlite) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
here <- tryCatch(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))), error = function(e) ".")
dataDir <- arg("data", file.path(here, "data")); reps <- as.integer(arg("reps", "200")); outDir <- arg("out", file.path(here, "output"))
dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
set.seed(20261021)

floors <- read_csv(file.path(dataDir, "tower_floors.csv"), show_col_types = FALSE, progress = FALSE)
series <- do.call(rbind, lapply(floors$pm25_floor_mean, function(j) unlist(fromJSON(j))))
stopifnot(nrow(series) == 100, ncol(series) == 365)
cs <- cbind(0, t(apply(series, 1, cumsum)))
truth <- read_csv(file.path(dataDir, "person_exposure_truth.csv"), show_col_types = FALSE, progress = FALSE)
lh <- read_csv(file.path(dataDir, "location_history.csv"), show_col_types = FALSE, progress = FALSE) %>%
  left_join(read_csv(file.path(dataDir, "location.csv"), show_col_types = FALSE, progress = FALSE) %>% select(location_id, floor_number), by = "location_id")
d0 <- as.Date("2019-01-01")
a <- as.integer(as.Date(lh$start_date) - d0) + 1L; b <- as.integer(as.Date(lh$end_date) - d0) + 1L; ndays <- b - a + 1L
pid <- match(lh$entity_id, truth$person_id)
cond <- read_csv(file.path(dataDir, "condition_occurrence.csv"), show_col_types = FALSE, progress = FALSE)
gt <- read_csv(file.path(dataDir, "generator_truth.csv"), show_col_types = FALSE, progress = FALSE)
outcomes <- gt$outcome_name
Y <- sapply(outcomes, function(o) as.integer(truth$person_id %in% cond$person_id[cond$condition_source_value == o]))
Z <- cbind(ses = (truth$ses_index - 50) / 15, age = (truth$age - 54) / 10, female = truth$female)

exposure <- function(floorVec) {
  e <- (cs[cbind(floorVec, b + 1L)] - cs[cbind(floorVec, a)])
  as.numeric(rowsum(e, pid)[, 1]) / 365
}
xTrue <- exposure(lh$floor_number)
stopifnot(max(abs(xTrue - truth$pm25_day_weighted)) < 1e-4)
fit <- function(x, y) { m <- glm.fit(cbind(1, x, Z), y, family = binomial()); unname(m$coefficients[2]) }
clamp <- function(f) pmin(100L, pmax(1L, as.integer(round(f))))
scenarios <- list(
  true_floor    = list(n = 1L,   f = function() lh$floor_number),
  shift_sd1     = list(n = reps, f = function() clamp(lh$floor_number + rnorm(nrow(lh), 0, 1))),
  shift_sd3     = list(n = reps, f = function() clamp(lh$floor_number + rnorm(nrow(lh), 0, 3))),
  shift_sd10    = list(n = reps, f = function() clamp(lh$floor_number + rnorm(nrow(lh), 0, 10))),
  shift_sd30    = list(n = reps, f = function() clamp(lh$floor_number + rnorm(nrow(lh), 0, 30))),
  zone_10       = list(n = 1L,   f = function() as.integer((lh$floor_number - 1) %/% 10 * 10 + 5.5)),
  zone_25       = list(n = 1L,   f = function() as.integer((lh$floor_number - 1) %/% 25 * 25 + 13)),
  random_floor  = list(n = reps, f = function() sample.int(100L, nrow(lh), replace = TRUE)))
est0 <- sapply(outcomes, function(o) fit(xTrue, Y[, o]))
res <- list()
for (sc in names(scenarios)) {
  s <- scenarios[[sc]]
  est <- matrix(NA_real_, s$n, length(outcomes), dimnames = list(NULL, outcomes)); lam <- numeric(s$n)
  for (r in seq_len(s$n)) {
    x <- exposure(s$f())
    est[r, ] <- sapply(outcomes, function(o) fit(x, Y[, o]))
    lam[r] <- unname(coef(lm.fit(cbind(1, x, Z), xTrue))[2])
  }
  res[[sc]] <- tibble(scenario = sc, outcome = outcomes, true_beta = gt$beta_pm25_per_ugm3, estimate_true_floor = est0,
                      mean_estimate = colMeans(est), sd_estimate = apply(est, 2, sd), share_recovered = colMeans(est) / est0, predicted_share = mean(lam),
                      replicates = s$n, exposure_sd = sd(x), corr_with_true = cor(x, xTrue))
  message(sprintf("%-13s COPD: share of the true-floor estimate recovered %.2f (predicted %.2f)", sc, colMeans(est)[["COPD"]] / est0[["COPD"]], mean(lam)))
}
out <- bind_rows(res); write_csv(out, file.path(outDir, "floor_misclassification.csv"))
print(as.data.frame(out %>% filter(outcome %in% c("COPD", "ASTHMA")) %>% mutate(across(where(is.numeric), ~ round(.x, 3)))), row.names = FALSE)
