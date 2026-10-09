#!/usr/bin/env Rscript
# Repeated-simulation check of the benchmark's coverage claims.
#   Rscript benchmark/coverage_simulation.R [--data-dir syntheticDataGIS/data] [--exposure <csv or csv.gz>]

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(parallel)
  library(tibble)
})

args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default) {
  i <- match(paste0("--", name), args)
  if (is.na(i) || i == length(args)) default else args[i + 1]
}
dataDir <- arg("data-dir", "syntheticDataGIS/data")
exposureFile <- arg("exposure", file.path(dataDir, "external_exposure_fallback.csv.gz"))
outDir <- arg("out", "syntheticDataGIS/benchmark/output")
reps <- as.integer(arg("reps", "300"))
cores <- as.integer(arg("cores", as.character(max(1, min(4, detectCores() - 1)))))
seed <- as.integer(arg("seed", "20261020"))
dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
pm25Source <- arg("pm25-source", NA_character_)
sesSource <- arg("ses-source", NA_character_)
sourceFilter <- c(`2052499839` = pm25Source, `2052497744` = sesSource)
keepSource <- function(rows, conceptId) {
  s <- sourceFilter[[as.character(conceptId)]]
  if (is.na(s)) rows else rows %>% filter(exposure_source_value == s)
}
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)

truth <- read("generator_truth.csv")
params <- read("generator_params.csv") %>% select(param, value) %>% tibble::deframe()
person <- read("person.csv") %>% select(person_id, gender_concept_id, year_of_birth)
residence <- read("location_history.csv") %>%
  inner_join(read("location.csv") %>% select(location_id, county_ref_id), by = "location_id") %>%
  mutate(days = as.numeric(as.Date(end_date) - as.Date(start_date)) + 1)
exposureRows <- read_csv(exposureFile, show_col_types = FALSE, progress = FALSE,
                         col_select = c(person_id, exposure_concept_id, exposure_source_value, exposure_start_date, exposure_end_date, value_as_number)) %>%
  filter(!is.na(value_as_number)) %>%
  mutate(days = as.numeric(as.Date(exposure_end_date) - as.Date(exposure_start_date)) + 1,
         exposure_source_value = as.character(exposure_source_value))
dayWeighted <- function(conceptId, name) {
  exposureRows %>% filter(exposure_concept_id == conceptId) %>% keepSource(conceptId) %>% group_by(person_id) %>%
    summarise(value = sum(value_as_number * days) / sum(days), .groups = "drop") %>% rename(!!name := value)
}
first <- residence %>% group_by(entity_id) %>% slice_min(as.Date(start_date), n = 1, with_ties = FALSE) %>% ungroup() %>%
  select(person_id = entity_id, county = county_ref_id)
d <- person %>%
  inner_join(dayWeighted(2052499839, "pm25"), by = "person_id") %>%
  inner_join(dayWeighted(2052497744, "ses"), by = "person_id") %>%
  inner_join(first, by = "person_id") %>%
  mutate(female = as.numeric(gender_concept_id == 8532), age_decades = (2016 - year_of_birth) / 10, ses_sd = (ses - 50) / 15) %>%
  arrange(person_id)
observed <- read("condition_occurrence.csv") %>% distinct(person_id, outcome_name = condition_source_value) %>% count(outcome_name, name = "observed_cases")

counties <- sort(unique(residence$county_ref_id))
W <- Matrix::sparseMatrix(i = match(residence$entity_id, d$person_id), j = match(residence$county_ref_id, counties), x = residence$days,
                          dims = c(nrow(d), length(counties)))
W <- Matrix::Diagonal(x = 1 / Matrix::rowSums(W)) %*% W

fixedPart <- vapply(seq_len(nrow(truth)), function(i) {
  qlogis(truth$prevalence_ref[i]) +
    truth$beta_pm25_per_ugm3[i] * (d$pm25 - params[["pm25_ref_ugm3"]]) +
    truth$beta_ses_per_sd[i] * (d$ses - params[["ses_ref"]]) / params[["ses_sd"]] +
    truth$beta_age_per_decade[i] * ((2016 - d$year_of_birth) - params[["age_ref"]]) / 10 +
    truth$beta_female[i] * d$female
}, numeric(nrow(d)))

X1 <- cbind(1, d$pm25)
X2 <- cbind(1, d$pm25, d$ses_sd, d$age_decades, d$female)
fitCluster <- function(X, y, cluster) {
  fit <- suppressWarnings(glm.fit(X, y, family = binomial()))
  mu <- fit$fitted.values
  bread <- solve(crossprod(X * sqrt(mu * (1 - mu))))
  meat <- crossprod(rowsum(X * (y - mu), cluster))
  g <- length(unique(cluster)); n <- nrow(X); k <- ncol(X)
  v <- (g / (g - 1)) * ((n - 1) / (n - k)) * bread %*% meat %*% bread
  c(beta = unname(fit$coefficients[2]), se = sqrt(v[2, 2]), se_model = sqrt(bread[2, 2]))
}

oneReplicate <- function(r) {
  set.seed(seed + r)
  u <- rnorm(length(counties), 0, params[["county_frailty_sd"]])
  frailty <- as.numeric(W %*% u)
  bind_rows(lapply(seq_len(nrow(truth)), function(i) {
    y <- rbinom(nrow(d), 1, plogis(fixedPart[, i] + frailty))
    bind_rows(
      tibble(model = "Crude", outcome = truth$outcome_name[i], cases = sum(y), as_tibble_row(fitCluster(X1, y, d$county))),
      tibble(model = "Adjusted", outcome = truth$outcome_name[i], cases = sum(y), as_tibble_row(fitCluster(X2, y, d$county))))
  })) %>% mutate(rep = r)
}
message(sprintf("%d replicates x %d outcomes, %d cores", reps, nrow(truth), cores))
sims <- bind_rows(mclapply(seq_len(reps), oneReplicate, mc.cores = cores)) %>%
  left_join(truth %>% transmute(outcome = outcome_name, truth = beta_pm25_per_ugm3, group = ifelse(is_pm25_null_outcome, "null", "effect")), by = "outcome") %>%
  mutate(covers = abs(beta - truth) <= qnorm(0.975) * se, covers_model = abs(beta - truth) <= qnorm(0.975) * se_model,
         excludes_null = abs(beta) > qnorm(0.975) * se)

summary <- sims %>%
  group_by(model, group, outcome, truth) %>%
  summarise(sim_cases = mean(cases), mean_estimate = mean(beta), bias = mean(beta) - first(truth), empirical_sd = sd(beta),
            mean_clustered_se = mean(se), mean_model_se = mean(se_model),
            coverage_clustered = mean(covers), coverage_model_se = mean(covers_model),
            rejects_null = mean(excludes_null), .groups = "drop") %>%
  left_join(observed, by = c("outcome" = "outcome_name")) %>%
  arrange(model, group, desc(truth), outcome)
write_csv(summary %>% mutate(across(where(is.numeric), ~ round(.x, 4))), file.path(outDir, "coverage_simulation.csv"))

misses <- sims %>% group_by(model, rep) %>% summarise(n_missed = sum(!covers), .groups = "drop") %>%
  group_by(model) %>% summarise(replicates = n(), mean_misses = mean(n_missed), share_with_at_least_one_miss = mean(n_missed >= 1),
                                share_with_at_least_two_misses = mean(n_missed >= 2), .groups = "drop")
write_csv(misses, file.path(outDir, "coverage_simulation_misses.csv"))

md <- summary %>% transmute(Model = model, Outcome = outcome, Group = group, `True log-odds` = round(truth, 3), `Observed cases` = observed_cases,
                            `Simulated cases` = round(sim_cases), Bias = round(bias, 4), `Empirical SD` = round(empirical_sd, 4),
                            `Mean clustered SE` = round(mean_clustered_se, 4), `Mean model SE` = round(mean_model_se, 4),
                            `Coverage (clustered SE)` = round(coverage_clustered, 3), `Coverage (model SE)` = round(coverage_model_se, 3),
                            `Rejects 0` = round(rejects_null, 3))
writeLines(c(paste0("| ", paste(names(md), collapse = " | "), " |"), paste0("|", paste(rep("---", ncol(md)), collapse = "|"), "|"),
             vapply(seq_len(nrow(md)), function(i) paste0("| ", paste(as.character(unlist(md[i, ])), collapse = " | "), " |"), "")),
           file.path(outDir, "coverage_simulation.md"))

print(as.data.frame(sims %>% group_by(model, group) %>% summarise(coverage_clustered = round(mean(covers), 3), coverage_model_se = round(mean(covers_model), 3),
                                                                bias = round(mean(beta - truth), 4), rejects_null = round(mean(excludes_null), 3), .groups = "drop")))
print(as.data.frame(misses), digits = 3)
print(as.data.frame(summary %>% filter(outcome == "T2DM") %>% select(model, truth, mean_estimate, bias, empirical_sd, mean_clustered_se, coverage_clustered, observed_cases, sim_cases)), digits = 3)
