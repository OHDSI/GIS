#!/usr/bin/env Rscript
# Continuous-exposure analysis of the simulated PM2.5 effects that accounts for county clustering.
#   Rscript benchmark/continuous_model.R [--data-dir syntheticDataGIS/data] [--exposure <csv or csv.gz>]

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default) {
  i <- match(paste0("--", name), args)
  if (is.na(i) || i == length(args)) default else args[i + 1]
}
dataDir <- arg("data-dir", "syntheticDataGIS/data")
exposureFile <- arg("exposure", file.path(dataDir, "external_exposure_fallback.csv.gz"))
outDir <- arg("out", "syntheticDataGIS/benchmark/output")
useGlmm <- !("--no-glmm" %in% args) && requireNamespace("lme4", quietly = TRUE)
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
truthTbl <- truth
person <- read("person.csv") %>% select(person_id, gender_concept_id, year_of_birth)
residence <- read("location_history.csv") %>%
  inner_join(read("location.csv") %>% select(location_id, county_ref_id), by = "location_id")
cluster <- residence %>% group_by(entity_id) %>% slice_min(as.Date(start_date), n = 1, with_ties = FALSE) %>%
  ungroup() %>% select(person_id = entity_id, county = county_ref_id)
exposureRows <- read_csv(exposureFile, show_col_types = FALSE, progress = FALSE,
                         col_select = c(person_id, exposure_concept_id, exposure_source_value, exposure_start_date, exposure_end_date, value_as_number)) %>%
  filter(!is.na(value_as_number)) %>%
  mutate(days = as.numeric(as.Date(exposure_end_date) - as.Date(exposure_start_date)) + 1,
         exposure_source_value = as.character(exposure_source_value))
dayWeighted <- function(conceptId, name) {
  exposureRows %>% filter(exposure_concept_id == conceptId) %>% keepSource(conceptId) %>% group_by(person_id) %>%
    summarise(value = sum(value_as_number * days) / sum(days), .groups = "drop") %>% rename(!!name := value)
}
d <- person %>%
  inner_join(dayWeighted(2052499839, "pm25"), by = "person_id") %>%
  inner_join(dayWeighted(2052497744, "ses"), by = "person_id") %>%
  inner_join(cluster, by = "person_id") %>%
  mutate(female = as.numeric(gender_concept_id == 8532), age_decades = (2016 - year_of_birth) / 10, ses_sd = (ses - 50) / 15)
conditions <- read("condition_occurrence.csv") %>% distinct(person_id, outcome_name = condition_source_value)

fitCluster <- function(formula, data, cluster) {
  fit <- glm(formula, data = data, family = binomial())
  X <- model.matrix(fit); mu <- fitted(fit); w <- mu * (1 - mu); beta <- coef(fit)
  H <- crossprod(X * sqrt(w)); bread <- solve(H)
  cl <- factor(cluster); G <- nlevels(cl); n <- nrow(X); k <- ncol(X)
  s <- rowsum(X * (fit$y - mu), cl)
  cr1 <- (G / (G - 1)) * ((n - 1) / (n - k)) * bread %*% crossprod(s) %*% bread
  Hg <- array(0, c(G, k, k))
  for (a in seq_len(k)) for (b in a:k) { v <- rowsum(X[, a] * X[, b] * w, cl)[, 1]; Hg[, a, b] <- v; Hg[, b, a] <- v }
  bj <- t(vapply(seq_len(G), function(g) beta - solve(H - Hg[g, , ], s[g, ]), numeric(k)))
  cr3 <- ((G - 1) / G) * crossprod(sweep(bj, 2, colMeans(bj)))
  c(beta = unname(beta["pm25"]), se = sqrt(cr3["pm25", "pm25"]), se_model = sqrt(bread["pm25", "pm25"]), se_cr1 = sqrt(cr1["pm25", "pm25"]), df = G - 1)
}
fitGlmm <- function(data) {
  fit <- suppressWarnings(suppressMessages(lme4::glmer(y ~ pm25 + ses_sd + age_decades + female + (1 | county), data = data,
                                                       family = binomial(), nAGQ = 1,
                                                       control = lme4::glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5)))))
  s <- summary(fit)$coefficients
  c(beta = unname(s["pm25", "Estimate"]), se = unname(s["pm25", "Std. Error"]), se_model = NA_real_, se_cr1 = NA_real_, df = NA_real_)
}

results <- bind_rows(lapply(seq_len(nrow(truth)), function(i) {
  outcome <- truth$outcome_name[i]
  dd <- d %>% mutate(y = as.numeric(person_id %in% conditions$person_id[conditions$outcome_name == outcome]))
  est <- list(Crude = fitCluster(y ~ pm25, dd, dd$county),
              Adjusted = fitCluster(y ~ pm25 + ses_sd + age_decades + female, dd, dd$county))
  if (useGlmm) est[["Adjusted GLMM"]] <- fitGlmm(dd)
  bind_rows(lapply(names(est), function(m) tibble(outcome = outcome, model = m, cases = sum(dd$y),
                                                  beta = est[[m]][["beta"]], se = est[[m]][["se"]], se_model = est[[m]][["se_model"]], se_cr1 = est[[m]][["se_cr1"]], df = est[[m]][["df"]])))
})) %>%
  left_join(truth %>% transmute(outcome = outcome_name, truth = beta_pm25_per_ugm3, group = ifelse(is_pm25_null_outcome, "Simulated null", "Simulated effect")), by = "outcome") %>%
  mutate(crit = ifelse(is.na(df), qnorm(0.975), qt(0.975, df)), lower = beta - crit * se, upper = beta + crit * se, z_vs_truth = (beta - truth) / se,
         covers_truth = truth >= lower & truth <= upper, excludes_null = lower > 0 | upper < 0)

outcomeOrder <- truthTbl %>% arrange(is_pm25_null_outcome, desc(beta_pm25_per_ugm3), outcome_name) %>% pull(outcome_name)
table3 <- results %>%
  mutate(order = match(outcome, outcomeOrder)) %>%
  arrange(order, factor(model, c("Crude", "Adjusted", "Adjusted GLMM"))) %>%
  transmute(Outcome = outcome, Group = group, Cases = cases, Model = model, `True log-odds per ug/m3` = round(truth, 3),
            Estimate = round(beta, 3), `SE (jackknife; mixed model for GLMM)` = round(se, 3), `CR1 SE` = round(se_cr1, 3), `95% CI` = sprintf("%.3f to %.3f", lower, upper),
            `z vs truth` = round(z_vs_truth, 2), `CI covers truth` = ifelse(covers_truth, "yes", "no"), `CI excludes 0` = ifelse(excludes_null, "yes", "no"))
write_csv(table3, file.path(outDir, "continuous_model.csv"))
writeLines(c(paste0("| ", paste(names(table3), collapse = " | "), " |"), paste0("|", paste(rep("---", ncol(table3)), collapse = "|"), "|"),
             vapply(seq_len(nrow(table3)), function(i) paste0("| ", paste(as.character(unlist(table3[i, ])), collapse = " | "), " |"), "")),
           file.path(outDir, "continuous_model.md"))
print(as.data.frame(results %>% group_by(model, group) %>%
        summarise(n = n(), covered = sum(covers_truth), detected = sum(excludes_null), mean_bias = round(mean(beta - truth), 4), .groups = "drop")))
print(as.data.frame(results %>% filter(outcome == "T2DM") %>% select(model, truth, beta, se, z_vs_truth, covers_truth)), digits = 3)
