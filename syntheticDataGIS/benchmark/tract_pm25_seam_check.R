#!/usr/bin/env Rscript
# Level-shift check at the 2015/2016 seam of the two CDC tract PM2.5 releases, against the single-release county series.
#   Rscript benchmark/tract_pm25_seam_check.R --data-dir <tract data dir> [--out DIR]
suppressPackageStartupMessages({ library(dplyr); library(readr); library(tidyr) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
dataDir <- arg("data-dir"); outDir <- arg("out", "syntheticDataGIS/benchmark/output/seam"); stopifnot(!is.na(dataDir)); dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
read <- function(f, ...) read_csv(file.path(dataDir, f), show_col_types = FALSE, progress = FALSE, ...)

pop <- read("tract_reference.csv", col_types = cols(tract_geoid = col_character())) %>% select(tract_geoid, population)
tract <- read("tract_pm25_monthly.csv.gz", col_types = cols(.default = col_character())) %>%
  transmute(tract_geoid, month = substr(start_date, 1, 7), v = as.numeric(pm25_mean_pred)) %>% mutate(county = substr(tract_geoid, 1, 5)) %>% left_join(pop, by = "tract_geoid")
county <- read("county_pm25_monthly.csv.gz", col_types = cols(.default = col_character())) %>% transmute(county = county_fips, month = substr(start_date, 1, 7), county_v = as.numeric(pm25_mean_pred))

agg <- tract %>% group_by(county, month) %>%
  summarise(simple = mean(v), weighted = ifelse(sum(population, na.rm = TRUE) > 0, sum(population * v, na.rm = TRUE) / sum(population, na.rm = TRUE), mean(v)), .groups = "drop") %>%
  inner_join(county, by = c("county", "month")) %>% mutate(period = ifelse(month < "2016-01", "2014-2015", "2016-2019"))
cat(n_distinct(agg$county), "counties in both series\n")

monthly <- agg %>% group_by(month, period) %>% summarise(simple_diff = mean(simple - county_v), weighted_diff = mean(weighted - county_v), .groups = "drop") %>% arrange(month)
write_csv(monthly %>% mutate(across(where(is.numeric), ~ round(.x, 4))), file.path(outDir, "seam_monthly_difference.csv"))
cat("\nMean difference (tract aggregate minus county series, ug/m3) around the seam:\n")
print(as.data.frame(monthly %>% filter(month >= "2015-09", month <= "2016-04") %>% mutate(across(where(is.numeric), ~ round(.x, 3)))))

step <- function(col) {
  per <- agg %>% mutate(d = .data[[col]] - county_v) %>% group_by(county, period) %>% summarise(d = mean(d), .groups = "drop") %>% pivot_wider(names_from = period, values_from = d) %>%
    mutate(step = `2016-2019` - `2014-2015`)
  tibble(aggregate = col, mean_2014_2015 = mean(per$`2014-2015`), mean_2016_2019 = mean(per$`2016-2019`), step = mean(per$step), step_se = sd(per$step) / sqrt(nrow(per)), counties = nrow(per),
         correlation_2014_2015 = cor(agg[[col]][agg$period == "2014-2015"], agg$county_v[agg$period == "2014-2015"]),
         correlation_2016_2019 = cor(agg[[col]][agg$period == "2016-2019"], agg$county_v[agg$period == "2016-2019"]))
}
steps <- bind_rows(step("simple"), step("weighted")) %>% mutate(across(where(is.numeric), ~ round(.x, 4)))
write_csv(steps, file.path(outDir, "seam_step.csv")); cat("\nStep between the two release periods:\n"); print(as.data.frame(steps))

multi <- tract %>% group_by(county, month) %>% mutate(n = n(), dev = v - mean(v)) %>% ungroup() %>% filter(n >= 3)
spread <- multi %>% group_by(county, month) %>% summarise(sd = sd(v), .groups = "drop") %>% group_by(month) %>% summarise(sd = mean(sd), .groups = "drop") %>% mutate(year = substr(month, 1, 4))
cat("\nMean within-county SD of tract values by year (ug/m3):\n"); print(as.data.frame(spread %>% group_by(year) %>% summarise(sd = round(mean(sd), 3))))
adj <- function(a, b) { d <- multi %>% filter(month %in% c(a, b)) %>% select(tract_geoid, month, dev) %>% pivot_wider(names_from = month, values_from = dev) %>% drop_na(); tibble(from = a, to = b, correlation = round(cor(d[[a]], d[[b]]), 3)) }
pairs <- bind_rows(lapply(2015:2019, function(y) adj(paste0(y - 1, "-12"), paste0(y, "-01"))))
write_csv(pairs, file.path(outDir, "seam_deviation_correlation.csv")); cat("\nCorrelation of within-county tract deviations across each December-January transition:\n"); print(as.data.frame(pairs))
