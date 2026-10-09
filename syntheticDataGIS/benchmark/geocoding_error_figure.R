#!/usr/bin/env Rscript
# Comparison figure and tables for the geocoding-error propagation analysis, one set of results per geocoder.
#   Rscript benchmark/geocoding_error_figure.R --in <dir with <geocoder>/results> --errors <geocoding_errors dir> --out <dir>
suppressPackageStartupMessages({ library(dplyr); library(readr); library(tidyr); library(ggplot2) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
inDir <- arg("in"); errDir <- arg("errors"); outDir <- arg("out", "."); dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
geocoders <- c(nominatim = "Nominatim", arcgis = "ArcGIS Pro", degauss = "DeGAUSS", postgis = "PostGIS TIGER")
geocoders <- geocoders[file.exists(file.path(inDir, names(geocoders), "results", "geocoding_error_effects.csv"))]
stopifnot(length(geocoders) > 0)
read <- function(g, f) read_csv(file.path(inDir, g, "results", f), show_col_types = FALSE) %>% mutate(geocoder = factor(geocoders[[g]], levels = geocoders))
mis <- bind_rows(lapply(names(geocoders), read, f = "geocoding_error_misclassification.csv"))
eff <- bind_rows(lapply(names(geocoders), read, f = "geocoding_error_effects.csv")) %>% mutate(kind = ifelse(truth == 0, "null outcomes", "true effects"))
err <- bind_rows(lapply(names(geocoders), function(g) read_csv(file.path(errDir, paste0("errors_", g, ".csv")), show_col_types = FALSE) %>% mutate(geocoder = factor(geocoders[[g]], levels = geocoders))))

theme_set(theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "bottom"))
res_cols <- c(tract = "#b2182b", county = "#2166ac")

pA <- err %>% filter(error_m > 0) %>% ggplot(aes(error_m, colour = geocoder)) + stat_ecdf(linewidth = 0.8) + scale_x_log10(breaks = c(1, 10, 100, 1e3, 1e4, 1e5), labels = scales::comma) +
  labs(x = "Geocoding error (m, log scale)", y = "Cumulative share of addresses", colour = NULL, title = "A. Empirical geocoding error")
pB <- mis %>% filter(stratum == "all") %>% ggplot(aes(geocoder, share_locations_reassigned, fill = resolution)) + geom_col(position = "dodge") +
  scale_fill_manual(values = res_cols) + scale_y_continuous(labels = scales::percent) +
  labs(x = NULL, y = "Locations assigned to a different unit", fill = NULL, title = "B. Reassigned tract / county")
pC <- eff %>% filter(stratum == "all") %>% ggplot(aes(geocoder, shift_vs_error_free, colour = resolution)) +
  geom_hline(yintercept = 0, colour = "grey50") + geom_boxplot(aes(group = interaction(geocoder, resolution)), position = position_dodge(0.7), width = 0.6, outlier.size = 0.8) +
  scale_colour_manual(values = res_cols) +
  labs(x = NULL, y = "Mean shift in estimate vs error-free\n(log-odds per ug/m3, 14 outcomes)", colour = NULL, title = "C. Effect estimate shift")
pD <- eff %>% filter(stratum == "all") %>% group_by(geocoder, resolution, kind) %>% summarise(coverage = mean(coverage_of_truth), .groups = "drop") %>%
  ggplot(aes(geocoder, coverage, colour = resolution, shape = kind)) + geom_point(size = 3, position = position_dodge(0.5)) +
  geom_hline(yintercept = 0.95, linetype = 2, colour = "grey50") + scale_colour_manual(values = res_cols) + scale_y_continuous(labels = scales::percent, limits = c(0.8, 1)) +
  labs(x = NULL, y = "Coverage of the true value", colour = NULL, shape = NULL, title = "D. Interval coverage")
fig <- gridExtra::arrangeGrob(pA, pB, pC, pD, ncol = 2)
png(file.path(outDir, "geocoding_error_comparison.png"), width = 11, height = 8.5, units = "in", res = 200); grid::grid.draw(fig); invisible(dev.off())
pdf(file.path(outDir, "geocoding_error_comparison.pdf"), width = 11, height = 8.5); grid::grid.draw(fig); invisible(dev.off())

summ <- mis %>% filter(stratum == "all") %>% select(geocoder, resolution, share_locations_reassigned, exposure_rmse, correlation_with_error_free, slope_on_error_free) %>%
  left_join(eff %>% filter(stratum == "all") %>% group_by(geocoder, resolution) %>%
    summarise(mean_abs_shift = mean(abs(shift_vs_error_free)), max_abs_shift = max(abs(shift_vs_error_free)), coverage_effects = mean(coverage_of_truth[truth != 0]),
              coverage_nulls = mean(coverage_of_truth[truth == 0]), .groups = "drop"), by = c("geocoder", "resolution")) %>%
  mutate(across(where(is.numeric), ~ round(.x, 4))) %>% arrange(resolution, geocoder)
write_csv(summ, file.path(outDir, "geocoding_error_summary.csv"))
print(as.data.frame(summ))
