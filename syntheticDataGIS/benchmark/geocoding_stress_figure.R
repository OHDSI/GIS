#!/usr/bin/env Rscript
# Figure for the geocoding stress tests: attenuation and coverage against correlation length, and the road scenario.
#   Rscript benchmark/geocoding_stress_figure.R --stress <dir with stress_test_summary.csv> [--roads <dir with roads_scenario_summary.csv>] --errors <dir> --out <dir>
suppressPackageStartupMessages({ library(dplyr); library(readr); library(ggplot2) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NA_character_) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
stressDir <- arg("stress"); roadsDir <- arg("roads"); errDir <- arg("errors"); outDir <- arg("out", "."); dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
labels <- c(nominatim = "Nominatim", arcgis = "ArcGIS Pro", degauss = "DeGAUSS", postgis = "PostGIS TIGER")
lab <- function(x) factor(labels[x], levels = labels)
stress <- read_csv(file.path(stressDir, "stress_test_summary.csv"), show_col_types = FALSE) %>% mutate(geocoder = lab(geocoder))
theory <- bind_rows(lapply(names(labels), function(g) { e <- read_csv(file.path(errDir, paste0("errors_", g, ".csv")), show_col_types = FALSE)$error_m
  tibble(geocoder = lab(g), scale_m = 10^seq(log10(30), log10(30000), length.out = 120)) %>% rowwise() %>% mutate(attenuation = mean(exp(-e / scale_m))) %>% ungroup() }))
theme_set(theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "bottom"))
breaks <- c(100, 1000, 10000)
pA <- ggplot() + geom_line(data = theory, aes(scale_m, attenuation, colour = geocoder), linewidth = 0.6) +
  geom_point(data = stress, aes(scale_m, attenuation, colour = geocoder), size = 2.6) +
  scale_x_log10(breaks = breaks, labels = c("100 m", "1 km", "10 km")) + scale_y_continuous(limits = c(0.4, 1)) +
  labs(x = "Correlation length of the exposure surface", y = "Share of the true effect recovered", colour = NULL, title = "A. Attenuation (points: simulation; lines: E[exp(-d/L)])")
free <- mean(stress$coverage_effects_error_free)
pB <- ggplot(stress, aes(scale_m, coverage_effects_displaced, colour = geocoder)) + geom_line(linewidth = 0.6) + geom_point(size = 2.6) +
  geom_hline(yintercept = free, linetype = 2, colour = "grey40") + annotate("text", x = 110, y = free + 0.025, label = "no geocoding error", colour = "grey40", hjust = 0, size = 3) +
  scale_x_log10(breaks = breaks, labels = c("100 m", "1 km", "10 km")) + scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(x = "Correlation length of the exposure surface", y = "Coverage of the true effect (95% interval)", colour = NULL, title = "B. Interval coverage")
plots <- list(pA, pB)
if (!is.na(roadsDir)) {
  roads <- read_csv(file.path(roadsDir, "roads_scenario_summary.csv"), show_col_types = FALSE) %>% mutate(geocoder = lab(geocoder),
    component = factor(ifelse(component == "road", "Near-road increment", "Tract PM2.5"), levels = c("Near-road increment", "Tract PM2.5")))
  plots[[3]] <- ggplot(roads, aes(geocoder, attenuation, fill = component)) + geom_col(position = "dodge") + geom_hline(yintercept = 1, colour = "grey40") +
    scale_y_continuous(limits = c(0, 1.05)) + scale_fill_manual(values = c("#b2182b", "#2166ac")) +
    labs(x = NULL, y = "Share of the true effect recovered", fill = NULL, title = "C. Road-proximity scenario (real roads)")
}
fig <- do.call(gridExtra::arrangeGrob, c(plots, list(ncol = length(plots))))
png(file.path(outDir, "geocoding_stress_test.png"), width = 5 * length(plots) + 1, height = 4.8, units = "in", res = 200); grid::grid.draw(fig); invisible(dev.off())
pdf(file.path(outDir, "geocoding_stress_test.pdf"), width = 5 * length(plots) + 1, height = 4.8); grid::grid.draw(fig); invisible(dev.off())
