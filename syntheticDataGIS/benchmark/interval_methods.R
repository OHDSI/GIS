#!/usr/bin/env Rscript
# Which confidence interval to use for the continuous-exposure PM2.5 effect when there are few, very unbalanced county clusters.
#   Rscript benchmark/interval_methods.R [--data-dir <dir>] [--exposure <file>] [--pm25-source <id>] [--ses-source <id>]

suppressPackageStartupMessages({ library(dplyr); library(readr); library(parallel); library(tibble); library(lme4) })

args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
dataDir <- arg("data-dir", "syntheticDataGIS/data")
exposureFile <- arg("exposure", file.path(dataDir, "external_exposure_fallback.csv.gz"))
outDir <- arg("out", "syntheticDataGIS/benchmark/output")
reps <- as.integer(arg("reps", "100")); cores <- as.integer(arg("cores", "4")); seed <- as.integer(arg("seed", "20261020"))
outcomes <- strsplit(arg("outcomes", "COPD,STROKE,T2DM,CKD"), ",")[[1]]
pm25Source <- arg("pm25-source", NA_character_); sesSource <- arg("ses-source", NA_character_)
dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)
keepSource <- function(rows, src) if (is.na(src)) rows else rows %>% filter(exposure_source_value == src)

truth <- read("generator_truth.csv") %>% filter(outcome_name %in% outcomes)
params <- read("generator_params.csv") %>% select(param, value) %>% tibble::deframe()
person <- read("person.csv") %>% select(person_id, gender_concept_id, year_of_birth)
residence <- read("location_history.csv") %>%
  inner_join(read("location.csv") %>% select(location_id, county_ref_id), by = "location_id") %>%
  mutate(days = as.numeric(as.Date(end_date) - as.Date(start_date)) + 1)
exposureRows <- read_csv(exposureFile, show_col_types = FALSE, progress = FALSE,
                         col_select = c(person_id, exposure_concept_id, exposure_source_value, exposure_start_date, exposure_end_date, value_as_number)) %>%
  filter(!is.na(value_as_number)) %>%
  mutate(days = as.numeric(as.Date(exposure_end_date) - as.Date(exposure_start_date)) + 1, exposure_source_value = as.character(exposure_source_value))
dayWeighted <- function(conceptId, src, name) {
  exposureRows %>% filter(exposure_concept_id == conceptId) %>% keepSource(src) %>% group_by(person_id) %>%
    summarise(value = sum(value_as_number * days) / sum(days), .groups = "drop") %>% rename(!!name := value)
}
first <- residence %>% group_by(entity_id) %>% slice_min(as.Date(start_date), n = 1, with_ties = FALSE) %>% ungroup() %>%
  select(person_id = entity_id, county = county_ref_id)
d <- person %>%
  inner_join(dayWeighted(2052499839, pm25Source, "pm25"), by = "person_id") %>%
  inner_join(dayWeighted(2052497744, sesSource, "ses"), by = "person_id") %>%
  inner_join(first, by = "person_id") %>%
  mutate(female = as.numeric(gender_concept_id == 8532), age_decades = (2016 - year_of_birth) / 10, ses_sd = (ses - 50) / 15) %>%
  arrange(person_id)
counties <- sort(unique(residence$county_ref_id))
W <- Matrix::sparseMatrix(i = match(residence$entity_id, d$person_id), j = match(residence$county_ref_id, counties), x = residence$days, dims = c(nrow(d), length(counties)))
W <- Matrix::Diagonal(x = 1 / Matrix::rowSums(W)) %*% W
fixedPart <- vapply(seq_len(nrow(truth)), function(i) {
  qlogis(truth$prevalence_ref[i]) + truth$beta_pm25_per_ugm3[i] * (d$pm25 - params[["pm25_ref_ugm3"]]) +
    truth$beta_ses_per_sd[i] * (d$ses - params[["ses_ref"]]) / params[["ses_sd"]] +
    truth$beta_age_per_decade[i] * ((2016 - d$year_of_birth) - params[["age_ref"]]) / 10 + truth$beta_female[i] * d$female
}, numeric(nrow(d)))
X <- cbind(1, d$pm25, d$ses_sd, d$age_decades, d$female)
cl <- factor(d$county); G <- nlevels(cl)
pairs <- which(upper.tri(matrix(0, ncol(X), ncol(X)), diag = TRUE), arr.ind = TRUE)

glmSE <- function(y) {
  f <- suppressWarnings(glm.fit(X, y, family = binomial())); mu <- f$fitted.values; w <- mu * (1 - mu); beta <- f$coefficients
  H <- crossprod(X * sqrt(w)); bread <- solve(H)
  s <- rowsum(X * (y - mu), cl)
  n <- nrow(X); k <- ncol(X)
  cr1 <- (G / (G - 1)) * ((n - 1) / (n - k)) * bread %*% crossprod(s) %*% bread
  Hg <- array(0, c(G, k, k))
  for (r in seq_len(nrow(pairs))) { a <- pairs[r, 1]; b <- pairs[r, 2]; v <- rowsum(X[, a] * X[, b] * w, cl)[, 1]; Hg[, a, b] <- v; Hg[, b, a] <- v }
  bj <- t(vapply(seq_len(G), function(g) beta - solve(H - Hg[g, , ], s[g, ]), numeric(k)))
  cr3 <- ((G - 1) / G) * crossprod(sweep(bj, 2, colMeans(bj)))
  c(beta = unname(beta[2]), se_model = sqrt(bread[2, 2]), se_cr1 = sqrt(cr1[2, 2]), se_cr3 = sqrt(cr3[2, 2]))
}
glmmFit <- function(y) {
  dd <- data.frame(y = y, pm25 = d$pm25, ses_sd = d$ses_sd, age = d$age_decades, female = d$female, county = cl)
  f <- suppressWarnings(suppressMessages(glmer(y ~ pm25 + ses_sd + age + female + (1 | county), data = dd, family = binomial(), nAGQ = 0,
                                              control = glmerControl(optimizer = "bobyqa"))))
  s <- summary(f)$coefficients; c(beta_glmm = unname(s["pm25", "Estimate"]), se_glmm = unname(s["pm25", "Std. Error"]))
}

tq <- qt(0.975, G - 1); zq <- qnorm(0.975)
oneReplicate <- function(r) {
  set.seed(seed + r)
  u <- rnorm(length(counties), 0, params[["county_frailty_sd"]]); frailty <- as.numeric(W %*% u)
  bind_rows(lapply(seq_len(nrow(truth)), function(i) {
    y <- rbinom(nrow(d), 1, plogis(fixedPart[, i] + frailty))
    a <- glmSE(y); b <- glmmFit(y)
    tibble(rep = r, outcome = truth$outcome_name[i], truth = truth$beta_pm25_per_ugm3[i], t(c(a, b)) %>% as_tibble())
  }))
}
message(sprintf("%d replicates x %d outcomes, %d persons, %d counties, %d cores", reps, nrow(truth), nrow(d), G, cores))
sims <- bind_rows(mclapply(seq_len(reps), function(r) tryCatch(oneReplicate(r), error = function(e) { message("replicate ", r, " failed: ", conditionMessage(e)); NULL }), mc.cores = cores))

long <- bind_rows(
  sims %>% transmute(rep, outcome, truth, method = "model SE (z)", est = beta, lo = beta - zq * se_model, hi = beta + zq * se_model, se = se_model),
  sims %>% transmute(rep, outcome, truth, method = "CR1 (z)", est = beta, lo = beta - zq * se_cr1, hi = beta + zq * se_cr1, se = se_cr1),
  sims %>% transmute(rep, outcome, truth, method = "CR1 (t, G-1)", est = beta, lo = beta - tq * se_cr1, hi = beta + tq * se_cr1, se = se_cr1),
  sims %>% transmute(rep, outcome, truth, method = "CR3 jackknife (t, G-1)", est = beta, lo = beta - tq * se_cr3, hi = beta + tq * se_cr3, se = se_cr3),
  sims %>% transmute(rep, outcome, truth, method = "GLMM (z)", est = beta_glmm, lo = beta_glmm - zq * se_glmm, hi = beta_glmm + zq * se_glmm, se = se_glmm),
  sims %>% transmute(rep, outcome, truth, method = "GLMM (t, G-1)", est = beta_glmm, lo = beta_glmm - tq * se_glmm, hi = beta_glmm + tq * se_glmm, se = se_glmm))
summ <- long %>% mutate(covers = lo <= truth & truth <= hi) %>%
  group_by(method, outcome) %>%
  summarise(replicates = n(), coverage = mean(covers), mean_width = mean(hi - lo), bias = mean(est - truth), empirical_sd = sd(est), mean_se = mean(se),
            sd_over_mean_se = sd(est) / mean(se), .groups = "drop")
overall <- summ %>% group_by(method) %>% summarise(across(c(coverage, mean_width, bias, empirical_sd, mean_se, sd_over_mean_se), mean), .groups = "drop") %>% mutate(outcome = "all")
res <- bind_rows(summ, overall) %>% mutate(across(where(is.numeric), ~ round(.x, 4))) %>%
  arrange(factor(outcome, c("all", outcomes)), factor(method, unique(long$method)))
write_csv(res, file.path(outDir, "interval_methods.csv"))
writeLines(c(paste0("| ", paste(names(res), collapse = " | "), " |"), paste0("|", paste(rep("---", ncol(res)), collapse = "|"), "|"),
             vapply(seq_len(nrow(res)), function(i) paste0("| ", paste(as.character(unlist(res[i, ])), collapse = " | "), " |"), "")),
           file.path(outDir, "interval_methods.md"))
print(as.data.frame(res %>% filter(outcome == "all")), digits = 3)
