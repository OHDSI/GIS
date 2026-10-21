#!/usr/bin/env Rscript
# Usage: Rscript tower/tower_figure.R [--data DIR] [--results CSV] [--out PNG]
suppressPackageStartupMessages({ library(readr); library(jsonlite) })
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default) { i <- match(paste0("--", name), args); if (is.na(i) || i == length(args)) default else args[i + 1] }
here <- tryCatch(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))), error = function(e) ".")
dataDir <- arg("data", file.path(here, "data")); resFile <- arg("results", file.path(here, "output", "floor_misclassification.csv"))
out <- arg("out", file.path(here, "..", "..", "rmd", "images", "tower_pm25_and_floor_error.png"))
blue <- "#2a78d6"; orange <- "#eb6834"; ink <- "#0b0b0b"; ink2 <- "#52514e"; grid <- "#e3e2de"; surface <- "#fcfcfb"
ref <- read_csv(file.path(dataDir, "floor_reference.csv"), show_col_types = FALSE)
sens <- read_csv(file.path(dataDir, "tower_sensors.csv"), show_col_types = FALSE)
sens$annual <- vapply(sens$pm25_sensor, function(j) mean(unlist(fromJSON(j))), numeric(1))
res <- read_csv(resFile, show_col_types = FALSE)
res <- res[res$outcome == "COPD" & grepl("^(true_floor|shift_sd)", res$scenario), ]
res$sd <- suppressWarnings(ifelse(res$scenario == "true_floor", 0, as.numeric(sub("shift_sd", "", res$scenario))))
res <- res[order(res$sd), ]

png(out, width = 2000, height = 820, res = 200, type = "cairo", bg = surface)
par(mfrow = c(1, 2), mar = c(4.4, 4.6, 3.2, 1.2), family = "sans", col.axis = ink2, col.lab = ink2, col.main = ink, las = 1, cex.axis = 0.9)
plot(NA, xlim = c(1, 100), ylim = c(4, 19), xlab = "Floor", ylab = expression("Annual mean PM2.5 ("*mu*"g/m"^3*")"), bty = "n", xaxt = "n")
abline(h = seq(5, 20, 5), col = grid, lwd = 1)
axis(1, at = c(1, 25, 50, 75, 100), col = grid, col.ticks = grid)
points(sens$floor_number, sens$annual, pch = 16, cex = 0.45, col = adjustcolor(ink2, 0.35))
lines(ref$floor_number, ref$pm25_annual_mean, col = blue, lwd = 2.4)
legend("topleft", legend = c("floor mean", "individual sensors (4 per floor)"), col = c(blue, adjustcolor(ink2, 0.5)), lwd = c(2.4, NA), pch = c(NA, 16), pt.cex = 0.7, bty = "n", cex = 0.85, text.col = ink2)
title(main = "Particle levels rise with height", adj = 0, cex.main = 1.05, font.main = 2)
plot(NA, xlim = c(0, 30), ylim = c(0.4, 1.02), xlab = "Floor error (SD, floors)", ylab = "Share of the effect recovered", bty = "n")
abline(h = seq(0.4, 1, 0.2), col = grid, lwd = 1)
lines(res$sd, res$predicted_share, col = orange, lwd = 2, lty = 2)
lines(res$sd, res$share_recovered, col = blue, lwd = 2.4); points(res$sd, res$share_recovered, pch = 21, bg = blue, col = surface, cex = 1.5, lwd = 1.5)
legend("bottomleft", legend = c("simulated (200 replicates)", "regression-dilution prediction"), col = c(blue, orange), lwd = c(2.4, 2), lty = c(1, 2), bty = "n", cex = 0.85, text.col = ink2)
title(main = "A few floors of error cost little", adj = 0, cex.main = 1.05, font.main = 2)
invisible(dev.off())
message("wrote ", out)
