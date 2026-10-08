#!/usr/bin/env Rscript
# Recovery of the simulated PM2.5 effects for all 14 conditions (Table 2 / forest plot of the manuscript), estimated with
# the CohortMethod package.
#
# Design (a comparative cohort study, as in Exercise 4):
#   target      persons with high exposure: day-weighted mean county PM2.5 over their residences, 2014-2019 (the exposure the
#               generator uses) at or above --high (default 10 ug/m3)
#   comparator  persons with low exposure: below --low (default 8 ug/m3); persons in between are not analysed
#   outcome     any occurrence of the condition during 2014-2019, analysed with a logistic outcome model
#   crude       CohortMethod outcome model on the unadjusted cohorts
#   adjusted    CohortMethod propensity score (county SES, age, sex: the covariates of the generator's risk model),
#               stratified in --strata strata (or matched 1:1 with --design match), with a stratified outcome model;
#               --outcome-covariates adds SES, age and sex to the outcome model as well
#

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(CohortMethod)
})

args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default) {
  i <- match(paste0("--", name), args)
  if (is.na(i) || i == length(args)) default else args[i + 1]
}
dataDir <- arg("data-dir", "syntheticDataGIS/data")
exposureFile <- arg("exposure", file.path(dataDir, "external_exposure_fallback.csv.gz"))
outDir <- arg("out", "syntheticDataGIS/benchmark/output")
highCut <- as.numeric(arg("high", "10"))
lowCut <- as.numeric(arg("low", "8"))
nStrata <- as.integer(arg("strata", "5"))
design <- arg("design", "stratify")                    # stratify (default) or match: how the propensity score is used
outcomeCovariates <- "--outcome-covariates" %in% args  # also adjust for SES, age and sex in the outcome model
dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
pm25Source <- arg("pm25-source", NA_character_)   # exposure_source_value (variable_source_id) of the PM2.5 variable to use; NA = all rows of the concept
sesSource <- arg("ses-source", NA_character_)
sourceFilter <- c(`2052499839` = pm25Source, `2052497744` = sesSource)
keepSource <- function(rows, conceptId) {
  s <- sourceFilter[[as.character(conceptId)]]
  if (is.na(s)) rows else rows %>% filter(exposure_source_value == s)
}
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)

# ---- person-level data -------------------------------------------------------------------------------------------
truth <- read("generator_truth.csv")
person <- read("person.csv") %>% select(person_id, gender_concept_id, year_of_birth)
obsPeriod <- read("observation_period.csv") %>%
  transmute(person_id, obsStart = as.Date(observation_period_start_date), obsEnd = as.Date(observation_period_end_date))

exposureRows <- read_csv(exposureFile, show_col_types = FALSE, progress = FALSE,
                         col_select = c(person_id, exposure_concept_id, exposure_source_value, exposure_start_date, exposure_end_date, value_as_number)) %>%
  filter(!is.na(value_as_number)) %>%
  mutate(days = as.numeric(as.Date(exposure_end_date) - as.Date(exposure_start_date)) + 1,
         exposure_source_value = as.character(exposure_source_value))
dayWeighted <- function(rows, conceptId, name) {
  rows %>%
    filter(exposure_concept_id == conceptId) %>%
    keepSource(conceptId) %>%
    group_by(person_id) %>%
    summarise(value = sum(value_as_number * days) / sum(days), .groups = "drop") %>%
    rename(!!name := value)
}
exposure <- dayWeighted(exposureRows, 2052499839, "pm25")   # PM2.5 as derived by gaiaDB
ses <- dayWeighted(exposureRows, 2052497744, "ses")         # county SES index as derived by gaiaDB through the same index

conditions <- read("condition_occurrence.csv") %>%
  distinct(person_id, outcome_name = condition_source_value, onset = as.Date(condition_start_date))

d <- person %>%
  inner_join(obsPeriod, by = "person_id") %>%
  inner_join(exposure, by = "person_id") %>%
  inner_join(ses, by = "person_id") %>%
  mutate(female = as.numeric(gender_concept_id == 8532),
         age_decades = (2016 - year_of_birth) / 10,
         ses_sd = (ses - 50) / 15)
stopifnot(nrow(d) == nrow(person))

# exposure groups: target = high, comparator = low; persons in between are left out
d <- d %>% mutate(treatment = case_when(pm25 >= highCut ~ 1L, pm25 < lowCut ~ 0L, TRUE ~ NA_integer_)) %>%
  filter(!is.na(treatment))
message(sprintf("%d persons analysed: %d high (>= %g ug/m3, mean %.2f), %d low (< %g ug/m3, mean %.2f)",
                nrow(d), sum(d$treatment == 1), highCut, mean(d$pm25[d$treatment == 1]),
                sum(d$treatment == 0), lowCut, mean(d$pm25[d$treatment == 0])))
message(sprintf("mean PM2.5 difference, high minus low: %.3f ug/m3 (%d of %d persons are between the cut points and not analysed)",
                mean(d$pm25[d$treatment == 1]) - mean(d$pm25[d$treatment == 0]), nrow(person) - nrow(d), nrow(person)))

# ---- CohortMethodData ----------------------------------------------------------------------------------------------
# Same layout as getDbCohortMethodData() (and CohortMethod's own simulator): cohorts, outcomes, covariates and their
# references in an Andromeda object. Cohort entry is the start of observation, follow-up runs to the end of observation.
targetId <- 1; comparatorId <- 2
cohorts <- d %>%
  transmute(rowId = as.integer(person_id), treatment = treatment, personId = as.integer(person_id),
            personSeqId = as.integer(person_id), cohortStartDate = obsStart, daysFromObsStart = 0,
            daysToCohortEnd = as.numeric(obsEnd - obsStart), daysToObsEnd = as.numeric(obsEnd - obsStart))
outcomes <- conditions %>%
  inner_join(truth %>% select(outcome_name, condition_concept_id), by = "outcome_name") %>%
  inner_join(d %>% select(person_id, obsStart), by = "person_id") %>%
  transmute(rowId = as.integer(person_id), outcomeId = as.numeric(condition_concept_id),
            daysToEvent = as.numeric(onset - obsStart))
covariateIds <- c(ses = 1001, age = 1002, female = 1003)
covariates <- bind_rows(
  d %>% transmute(rowId = as.integer(person_id), covariateId = covariateIds[["ses"]], covariateValue = ses_sd),
  d %>% transmute(rowId = as.integer(person_id), covariateId = covariateIds[["age"]], covariateValue = age_decades),
  d %>% transmute(rowId = as.integer(person_id), covariateId = covariateIds[["female"]], covariateValue = female))
covariateRef <- tibble(covariateId = unname(covariateIds),
                       covariateName = c("county SES index (per 15 points, centred at 50)", "age in 2016 (per decade)", "female"),
                       analysisId = 1, conceptId = 0)
analysisRef <- tibble(analysisId = 1, analysisName = "PersonCovariates", domainId = "Person",
                      startDay = NA_real_, endDay = NA_real_, isBinary = "N", missingMeansZero = "N")

cmData <- Andromeda::andromeda(outcomes = outcomes, cohorts = cohorts, covariates = covariates,
                               covariateRef = covariateRef, analysisRef = analysisRef)
attr(cmData, "metaData") <- list(
  populationSize = nrow(cohorts), cohortId = -1, targetId = targetId, comparatorId = comparatorId,
  studyStartDate = "", studyEndDate = "",
  attrition = tibble(description = "Original cohorts", targetPersons = sum(cohorts$treatment == 1),
                     comparatorPersons = sum(cohorts$treatment == 0), targetExposures = sum(cohorts$treatment == 1),
                     comparatorExposures = sum(cohorts$treatment == 0)),
  outcomeIds = unique(outcomes$outcomeId))
class(cmData) <- "CohortMethodData"
attr(class(cmData), "package") <- "CohortMethod"

# ---- CohortMethod: crude and propensity-score-stratified outcome models --------------------------------------------
noPrior <- createPrior("none")
quiet <- createControl(noiseLevel = "silent")
pm25ByRow <- setNames(d$pm25, d$person_id)

# difference in mean PM2.5 between the groups; for a stratified analysis, the average of the within-stratum differences
deltaPm25 <- function(pop) {
  pop$pm25 <- pm25ByRow[as.character(pop$rowId)]
  if (!"stratumId" %in% names(pop)) {
    return(mean(pop$pm25[pop$treatment == 1]) - mean(pop$pm25[pop$treatment == 0]))
  }
  pop %>%
    group_by(stratumId) %>%
    filter(any(treatment == 1), any(treatment == 0)) %>%
    summarise(n = n(), delta = mean(pm25[treatment == 1]) - mean(pm25[treatment == 0]), .groups = "drop") %>%
    summarise(delta = sum(n * delta) / sum(n)) %>% pull(delta)
}
estimate <- function(model, population) {
  e <- model$outcomeModelTreatmentEstimate
  delta <- deltaPm25(population)
  tibble(logRr = e$logRr, seLogRr = e$seLogRr, delta = delta,
         cases = sum(population$outcomeCount > 0), n = nrow(population))
}

fitAll <- function() suppressMessages(bind_rows(lapply(seq_len(nrow(truth)), function(i) {
  outcomeId <- truth$condition_concept_id[i]
  population <- createStudyPopulation(cmData, outcomeId = outcomeId, removeSubjectsWithPriorOutcome = FALSE,
                                      riskWindowStart = 0, startAnchor = "cohort start",
                                      riskWindowEnd = 0, endAnchor = "cohort end", minDaysAtRisk = 1)
  crudeModel <- fitOutcomeModel(population, modelType = "logistic", stratified = FALSE, useCovariates = FALSE,
                                prior = noPrior, control = quiet)
  # SES is strongly associated with the high/low PM2.5 contrast in some datasets: do not stop at the correlation check
  ps <- createPs(cmData, population, prior = noPrior, control = quiet, errorOnHighCorrelation = FALSE)
  analysed <- if (design == "match") matchOnPs(ps, caliper = 0.2, caliperScale = "standardized logit", maxRatio = 1)
              else stratifyByPs(ps, numberOfStrata = nStrata)
  adjustedModel <- fitOutcomeModel(analysed, cohortMethodData = if (outcomeCovariates) cmData else NULL, modelType = "logistic",
                                   stratified = TRUE, useCovariates = outcomeCovariates, prior = noPrior, control = quiet)
  bind_rows(
    estimate(crudeModel, population) %>% mutate(model = "Crude"),
    estimate(adjustedModel, analysed) %>% mutate(model = "Adjusted")
  ) %>% mutate(outcome = truth$outcome_name[i])
})))
invisible(capture.output(fits <- fitAll()))   # CohortMethod prints its progress; keep the console readable
message(sprintf("per-outcome mean PM2.5 difference used for scaling (crude / PS-stratified): %.3f to %.3f / %.3f to %.3f ug/m3",
                min(fits$delta[fits$model == "Crude"]), max(fits$delta[fits$model == "Crude"]),
                min(fits$delta[fits$model == "Adjusted"]), max(fits$delta[fits$model == "Adjusted"])))
# covariate balance of the analysed population for the first outcome: standardised mean difference of SES, age and sex,
# before and after the propensity score design (strata-size weighted within-stratum differences)
balance <- local({
  pop <- suppressMessages(createStudyPopulation(cmData, outcomeId = truth$condition_concept_id[1], removeSubjectsWithPriorOutcome = FALSE,
                                                 riskWindowStart = 0, startAnchor = "cohort start", riskWindowEnd = 0, endAnchor = "cohort end"))
  ps <- suppressMessages(createPs(cmData, pop, prior = noPrior, control = quiet, errorOnHighCorrelation = FALSE))
  an <- suppressMessages(if (design == "match") matchOnPs(ps, caliper = 0.2, caliperScale = "standardized logit", maxRatio = 1) else stratifyByPs(ps, numberOfStrata = nStrata))
  cov <- d %>% transmute(rowId = as.integer(person_id), SES = ses_sd, age = age_decades, female = female)
  smd <- function(p, weighted) {
    p <- p %>% inner_join(cov, by = "rowId")
    vapply(c("SES", "age", "female"), function(v) {
      sdAll <- sd(p[[v]])
      if (!weighted) return((mean(p[[v]][p$treatment == 1]) - mean(p[[v]][p$treatment == 0])) / sdAll)
      p %>% group_by(stratumId) %>% filter(any(treatment == 1), any(treatment == 0)) %>%
        summarise(n = n(), dm = mean(.data[[v]][treatment == 1]) - mean(.data[[v]][treatment == 0]), .groups = "drop") %>%
        summarise(x = sum(n * dm) / sum(n) / sdAll) %>% pull(x)
    }, numeric(1))
  }
  list(before = smd(pop, FALSE), after = smd(an, TRUE), n_before = nrow(pop), n_after = nrow(an))
})
message(sprintf("design: %s%s | persons %d -> %d | standardised mean difference before: SES %.2f, age %.2f, female %.2f; after: SES %.2f, age %.2f, female %.2f",
                design, if (outcomeCovariates) " + covariates in the outcome model" else "", balance$n_before, balance$n_after,
                balance$before[["SES"]], balance$before[["age"]], balance$before[["female"]],
                balance$after[["SES"]], balance$after[["age"]], balance$after[["female"]]))
results <- fits %>%
  left_join(truth %>% transmute(outcome = outcome_name, category, truth = beta_pm25_per_ugm3,
                                effect = factor(ifelse(is_pm25_null_outcome, "Simulated null", "Simulated effect"),
                                                levels = c("Simulated effect", "Simulated null"))),
            by = "outcome") %>%
  mutate(beta = logRr / delta, se = seLogRr / delta,                 # log-odds per ug/m3
         lower = beta - qnorm(0.975) * se, upper = beta + qnorm(0.975) * se,
         bias = beta - truth,
         covers_truth = truth >= lower & truth <= upper,
         excludes_null = lower > 0 | upper < 0,
         or = exp(beta), or_lower = exp(lower), or_upper = exp(upper), truth_or = exp(truth),
         contrast_or = exp(logRr), contrast_lower = exp(logRr - qnorm(0.975) * seLogRr),
         contrast_upper = exp(logRr + qnorm(0.975) * seLogRr), expected_contrast_or = exp(truth * delta))

# order: outcomes with an effect (largest true effect first), then nulls; label with the number of cases
order <- truth %>% arrange(is_pm25_null_outcome, desc(beta_pm25_per_ugm3), outcome_name) %>% pull(outcome_name)
results <- results %>% mutate(outcome = factor(outcome, levels = rev(order)))

# ---- table -------------------------------------------------------------------------------------------------------
table2 <- results %>%
  arrange(desc(outcome), model) %>%
  transmute(Outcome = as.character(outcome), Group = as.character(effect), Cases = cases, Model = model,
            `True log-odds per ug/m3` = round(truth, 3), `Estimate` = round(beta, 3),
            `95% CI` = sprintf("%.3f to %.3f", lower, upper),
            `OR per ug/m3 (95% CI)` = sprintf("%.2f (%.2f to %.2f)", or, or_lower, or_upper),
            `OR high vs low (95% CI)` = sprintf("%.2f (%.2f to %.2f)", contrast_or, contrast_lower, contrast_upper),
            `Expected OR high vs low` = sprintf("%.2f", expected_contrast_or),
            `CI covers truth` = ifelse(covers_truth, "yes", "no"),
            `CI excludes 0` = ifelse(excludes_null, "yes", "no"))
write_csv(table2, file.path(outDir, "pm25_effect_recovery.csv"))
md <- c(paste0("| ", paste(names(table2), collapse = " | "), " |"),
        paste0("|", paste(rep("---", ncol(table2)), collapse = "|"), "|"),
        vapply(seq_len(nrow(table2)), function(i) paste0("| ", paste(as.character(unlist(table2[i, ])), collapse = " | "), " |"), ""))
writeLines(md, file.path(outDir, "pm25_effect_recovery.md"))

summaryLines <- results %>%
  group_by(model, effect) %>%
  summarise(n = n(), covered = sum(covers_truth), detected = sum(excludes_null), mean_bias = mean(bias), .groups = "drop")
print(as.data.frame(summaryLines), digits = 3)

# ---- forest plot ---------------------------------------------------------------------------------------------------
labels <- results %>% distinct(outcome, cases = cases) %>%
  group_by(outcome) %>% summarise(cases = max(cases), .groups = "drop") %>%
  mutate(label = sprintf("%s (n = %s)", outcome, trimws(format(cases, big.mark = ","))))
results <- results %>% left_join(labels %>% select(outcome, label), by = "outcome") %>%
  mutate(label = factor(label, levels = labels$label[match(levels(outcome), labels$outcome)]),
         model = factor(model, levels = c("Crude", "Adjusted")))

dodge <- position_dodge(width = 0.6)
p <- ggplot(results, aes(y = label)) +
  geom_vline(xintercept = 1, linewidth = 0.4, colour = "grey40") +
  geom_point(aes(x = truth_or, shape = "True effect"), colour = "black", size = 3.2, stroke = 0.9) +
  geom_linerange(aes(xmin = or_lower, xmax = or_upper, colour = model), orientation = "y", linewidth = 0.7, position = dodge) +
  geom_point(aes(x = or, colour = model, fill = model), shape = 21, size = 2.2, position = dodge) +
  scale_colour_manual(values = c(Crude = "#D55E00", Adjusted = "#0072B2"), name = "CohortMethod estimate") +
  scale_fill_manual(values = c(Crude = "white", Adjusted = "#0072B2"), guide = "none") +
  scale_shape_manual(values = c("True effect" = 4), name = NULL) +
  scale_x_log10(breaks = c(0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4), labels = function(x) sprintf("%.2f", x)) +
  facet_grid(effect ~ ., scales = "free_y", space = "free_y") +
  labs(x = "Odds ratio per 1 ug/m3 of 2014-2019 mean PM2.5 (log scale)", y = NULL,
       caption = paste(sprintf("CohortMethod, high (>= %g ug/m3) versus low (< %g ug/m3) mean PM2.5, scaled to 1 ug/m3 by the mean exposure difference.", highCut, lowCut),
                       sprintf("Adjusted: propensity score on county SES, age and sex, %d strata. Points with 95%% confidence intervals; crosses mark the simulated true effect.", nStrata),
                       "The simulated PM2.5 effects are deliberately larger than epidemiologic estimates.", sep = "\n")) +
  guides(colour = guide_legend(order = 1, override.aes = list(fill = c("white", "#0072B2"), shape = 21))) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text.y = element_text(angle = 270, face = "bold"),
        legend.position = "bottom", plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"),
        plot.caption.position = "plot")

for (ext in c("png", "pdf", "svg")) {
  ggsave(file.path(outDir, paste0("pm25_effect_recovery.", ext)), p, width = 7.5, height = 7, dpi = 300)
}
message("Wrote ", normalizePath(outDir), "/pm25_effect_recovery.{csv,md,png,pdf,svg}")
