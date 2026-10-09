#!/usr/bin/env Rscript
# Gaia output as input to a machine-learning workflow, and why the validation scheme matters (tract benchmark dataset).
#   Rscript benchmark/spatial_cv_model.R --data-dir <dir> --exposure <file> --pm25-source <id> --ses-source <id> [--outcome COPD] [--out DIR]
suppressPackageStartupMessages({ library(dplyr); library(readr); library(sf); library(xgboost); library(pROC) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
dataDir <- arg("data-dir"); exposureFile <- arg("exposure"); srcPm <- arg("pm25-source"); srcSes <- arg("ses-source")
outcomes <- strsplit(arg("outcome", "COPD,T2DM"), ",")[[1]]; outDir <- arg("out", "syntheticDataGIS/benchmark/output"); blockKm <- as.numeric(arg("block-km", "150"))
stopifnot(!is.na(dataDir), !is.na(exposureFile), !is.na(srcPm), !is.na(srcSes)); dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)

person <- read("person.csv") %>% transmute(person_id, female = as.numeric(gender_concept_id == 8532), age = 2016 - year_of_birth)
first <- read("location_history.csv") %>% group_by(entity_id) %>% slice_min(as.Date(start_date), n = 1, with_ties = FALSE) %>% ungroup() %>%
  inner_join(read("location.csv") %>% select(location_id, latitude, longitude, county_ref_id), by = "location_id") %>%
  transmute(person_id = entity_id, lat = latitude, lon = longitude, county = county_ref_id)
gaia <- read_csv(exposureFile, show_col_types = FALSE, progress = FALSE,
                 col_select = c(person_id, exposure_start_date, exposure_end_date, exposure_source_value, value_as_number)) %>%
  mutate(days = as.numeric(as.Date(exposure_end_date) - as.Date(exposure_start_date)) + 1)
mean_by_person <- function(src, name) gaia %>% filter(as.character(exposure_source_value) == src) %>% group_by(person_id) %>%
  summarise(!!name := sum(value_as_number * days) / sum(days), .groups = "drop")
d <- person %>% inner_join(first, by = "person_id") %>% inner_join(mean_by_person(srcPm, "pm25"), by = "person_id") %>% inner_join(mean_by_person(srcSes, "ses"), by = "person_id")
conditions <- read("condition_occurrence.csv") %>% distinct(person_id, outcome_name = condition_source_value)
message(nrow(d), " persons, ", length(unique(d$county)), " counties")

xy <- st_coordinates(st_transform(st_as_sf(d, coords = c("lon", "lat"), crs = 4326), 5070))
block <- paste(floor(xy[, 1] / (blockKm * 1000)), floor(xy[, 2] / (blockKm * 1000)))
sizes <- sort(table(block), decreasing = TRUE)
foldOfBlock <- integer(length(sizes)); names(foldOfBlock) <- names(sizes); load <- rep(0, 5)
for (b in names(sizes)) { k <- which.min(load); foldOfBlock[b] <- k; load[k] <- load[k] + sizes[[b]] }
blockFold <- unname(foldOfBlock[block])
message(length(sizes), " grid blocks of ", blockKm, " km assigned to 5 folds with ", paste(load, collapse = " / "), " persons")

featureSets <- list(`exposure, SES, age, sex` = c("pm25", "ses", "age", "female"),
                    `... plus coordinates` = c("pm25", "ses", "age", "female", "lon", "lat"))
fitScore <- function(kind, X, y, train, test) {
  if (kind == "boosted trees") {
    m <- xgboost(data = X[train, , drop = FALSE], label = y[train], nrounds = 150, max_depth = 4, eta = 0.05, subsample = 0.8, colsample_bytree = 1,
                 objective = "binary:logistic", nthread = 2, verbose = 0)
    predict(m, X[test, , drop = FALSE])
  } else {
    df <- as.data.frame(X); df$y <- y
    predict(glm(y ~ ., data = df[train, ], family = binomial()), newdata = df[test, ], type = "response")
  }
}
cvAuc <- function(kind, X, y, folds) {
  pred <- rep(NA_real_, length(y)); fa <- numeric(0)
  for (f in sort(unique(folds))) { te <- which(folds == f); pred[te] <- fitScore(kind, X, y, which(folds != f), te); fa <- c(fa, as.numeric(auc(y[te], pred[te], quiet = TRUE))) }
  c(pooled = as.numeric(auc(y, pred, quiet = TRUE)), fold_min = min(fa), fold_max = max(fa))
}
res <- list()
for (o in outcomes) {
  y <- as.numeric(d$person_id %in% conditions$person_id[conditions$outcome_name == o])
  for (fs in names(featureSets)) {
    X <- as.matrix(d[, featureSets[[fs]]])
    for (kind in c("logistic regression", "boosted trees")) {
      rnd <- sapply(1:5, function(s) { set.seed(s); cvAuc(kind, X, y, sample(rep(1:5, length.out = length(y)))) })
      blk <- cvAuc(kind, X, y, blockFold)
      res[[length(res) + 1]] <- tibble(outcome = o, cases = sum(y), features = fs, model = kind,
        auc_random_cv = mean(rnd["pooled", ]), auc_random_cv_sd = sd(rnd["pooled", ]),
        auc_blocked_cv = blk[["pooled"]], blocked_fold_min = blk[["fold_min"]], blocked_fold_max = blk[["fold_max"]])
      message(o, " | ", fs, " | ", kind, ": random ", round(mean(rnd["pooled", ]), 3), ", blocked ", round(blk[["pooled"]], 3))
    }
  }
}
out <- bind_rows(res) %>% mutate(optimism = auc_random_cv - auc_blocked_cv, across(where(is.numeric), ~ round(.x, 4)))
write_csv(out, file.path(outDir, "spatial_cv_model.csv"))
print(as.data.frame(out))
