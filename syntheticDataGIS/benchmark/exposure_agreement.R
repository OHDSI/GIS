#!/usr/bin/env Rscript
# Exposure-level agreement between the exposure rows Gaia derived and an independent answer key.
#   Rscript benchmark/exposure_agreement.R [--data-dir syntheticDataGIS/data] [--exposure <csv or csv.gz>]

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
resolution <- arg("resolution", "county")
pm25Source <- arg("pm25-source", NA_character_)
sesSource <- arg("ses-source", NA_character_)
dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)
pm25Concept <- 2052499839
sesConcept <- 2052497744

if (resolution == "tract") {
  tractRef <- read("tract_reference.csv", col_types = cols(tract_geoid = col_character())) %>% select(tract_geoid, ses_index)
  place <- read("location.csv", col_types = cols(tract_geoid = col_character())) %>% select(location_id, unit = tract_geoid) %>%
    inner_join(tractRef %>% rename(unit = tract_geoid), by = "unit")
  monthly <- read("tract_pm25_monthly.csv.gz", col_types = cols(tract_geoid = col_character())) %>%
    transmute(unit = tract_geoid, month_start = as.Date(start_date), month_end = as.Date(end_date), pm25 = pm25_mean_pred)
} else {
  county <- read("county_reference.csv", col_types = cols(county_fips = col_character())) %>%
    select(county_ref_id, county_fips, ses_index)
  place <- read("location.csv") %>% select(location_id, county_ref_id) %>% inner_join(county, by = "county_ref_id") %>%
    transmute(location_id, unit = county_fips, ses_index)
  monthly <- read("county_pm25_monthly.csv.gz", col_types = cols(county_fips = col_character())) %>%
    transmute(unit = county_fips, month_start = as.Date(start_date), month_end = as.Date(end_date), pm25 = pm25_mean_pred)
}
intervals <- read("location_history.csv") %>%
  inner_join(place, by = "location_id") %>%
  transmute(person_id = entity_id, location_id, unit, ses_index, res_start = as.Date(start_date), res_end = as.Date(end_date))

keyPm25 <- intervals %>%
  inner_join(monthly, by = "unit", relationship = "many-to-many") %>%
  mutate(exposure_start_date = pmax(res_start, month_start), exposure_end_date = pmin(res_end, month_end)) %>%
  filter(exposure_start_date <= exposure_end_date) %>%
  transmute(person_id, location_id, exposure_start_date, exposure_end_date, key_value = pm25)
keySes <- intervals %>%
  transmute(person_id, location_id, exposure_start_date = res_start, exposure_end_date = res_end, key_value = ses_index)

gaia <- read_csv(exposureFile, show_col_types = FALSE, progress = FALSE,
                 col_select = c(person_id, location_id, exposure_concept_id, exposure_source_value, exposure_start_date, exposure_end_date, value_as_number)) %>%
  mutate(exposure_source_value = as.character(exposure_source_value), exposure_start_date = as.Date(exposure_start_date), exposure_end_date = as.Date(exposure_end_date))

compare <- function(key, concept, label, source) {
  g <- gaia %>% filter(exposure_concept_id == concept)
  if (!is.na(source)) g <- g %>% filter(exposure_source_value == source)
  g <- g %>% select(-exposure_concept_id, -exposure_source_value)
  keys <- c("person_id", "location_id", "exposure_start_date", "exposure_end_date")
  both <- inner_join(key, g, by = keys)
  dayWeighted <- function(df, v) df %>% mutate(days = as.numeric(exposure_end_date - exposure_start_date) + 1) %>%
    group_by(person_id) %>% summarise(m = sum({{ v }} * days) / sum(days), .groups = "drop")
  personKey <- dayWeighted(key, key_value)
  personGaia <- dayWeighted(g, value_as_number)
  persons <- inner_join(personKey, personGaia, by = "person_id", suffix = c("_key", "_gaia"))
  d <- both$value_as_number - both$key_value
  tibble(
    metric = c("rows in the answer key", "rows derived by Gaia", "rows matched on person, location and interval",
               "rows only in the key (missing from Gaia)", "rows only in Gaia (not in the key)",
               "matched rows with the same value (within 1e-9)", "maximum absolute difference in value",
               "correlation of values", "persons compared", "maximum absolute difference in the person-level day-weighted mean"),
    value = c(nrow(key), nrow(g), nrow(both), nrow(anti_join(key, g, by = keys)), nrow(anti_join(g, key, by = keys)),
              sum(abs(d) <= 1e-9), max(abs(d)), cor(both$value_as_number, both$key_value),
              nrow(persons), max(abs(persons$m_gaia - persons$m_key)))
  ) %>% mutate(exposure = label, .before = 1)
}

result <- bind_rows(compare(keyPm25, pm25Concept, sprintf("PM2.5 (monthly, %s level, through the point-in-polygon join)", resolution), pm25Source),
                    compare(keySes, sesConcept, sprintf("SES index (%s level, per residence interval)", resolution), sesSource))
write_csv(result, file.path(outDir, "exposure_agreement.csv"))
fmt <- function(x) vapply(x, function(v) if (v == round(v) && abs(v) >= 1) format(v, big.mark = ",", scientific = FALSE) else format(signif(v, 4), scientific = TRUE), "")
md <- c("| Exposure | Metric | Value |", "|---|---|---|",
        sprintf("| %s | %s | %s |", result$exposure, result$metric, fmt(result$value)))
writeLines(md, file.path(outDir, "exposure_agreement.md"))
print(as.data.frame(result %>% mutate(value = fmt(value))), right = FALSE)
