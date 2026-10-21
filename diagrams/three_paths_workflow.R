suppressPackageStartupMessages({ library(ggplot2); library(grid) })
args <- commandArgs(trailingOnly = TRUE); out <- if (length(args)) args[1] else "."; dpi <- if (length(args) > 1) as.numeric(args[2]) else 200
fam <- "Helvetica"; W <- 160; H <- 150
pal <- list(clin = c("#2166ac", "#e3edf7"), loc = c("#1b7837", "#e1f1e3"), geo = c("#b35806", "#fbebd5"), merge = c("#5e3c99", "#ebe5f4"), ev = c("#33333a", "#efefef"))
g <- ggplot() + coord_fixed(xlim = c(0, W), ylim = c(0, H), expand = FALSE) + theme_void() + theme(plot.background = element_rect(fill = "white", colour = NA))
box <- function(g, x0, y0, x1, y1, fill, col = NA, lwd = 0.5) g + annotate("rect", xmin = x0, xmax = x1, ymin = y0, ymax = y1, fill = fill, colour = col, linewidth = lwd)
txt <- function(g, x, y, label, size = 3.8, face = "plain", col = "#222222", hjust = 0, vjust = 1, lineheight = 1.15)
  g + annotate("text", x = x, y = y, label = label, size = size, fontface = face, colour = col, hjust = hjust, vjust = vjust, family = fam, lineheight = lineheight)
arr <- function(g, x0, y0, x1, y1, col = "#555555", lwd = 1.2) g + annotate("segment", x = x0, y = y0, xend = x1, yend = y1, colour = col, linewidth = lwd, arrow = arrow(length = unit(3.2, "mm"), type = "closed"))
stack <- function(g, x, y, items, size = 3.7, step = 1.95, col = "#222222") {
  for (it in items) { if (nzchar(it[2])) g <- txt(g, x, y, it[2], size, if (it[1] == "b") "bold" else "plain", if (it[1] == "b") col else "#222222"); y <- y - step }
  g
}
cols <- list(clin = c(3, 52), loc = c(55.5, 104.5), geo = c(108, 157))
g <- txt(g, 80, 149.2, "Three data paths, one exposure record, reliable health evidence", 7.6, "bold", hjust = 0.5)
g <- txt(g, 80, 144.6, "Worked example with real rows from the synthetic tutorial dataset: person 9 moves from Fauquier County, VA to Lamar County, MS while pregnant", 3.5, "plain", "#444444", hjust = 0.5)

path <- function(g, key, num, title, sub, source, std, ex_title, ex) {
  x0 <- cols[[key]][1]; x1 <- cols[[key]][2]; col <- pal[[key]][1]; lt <- pal[[key]][2]; xm <- (x0 + x1) / 2
  g <- box(g, x0, 131.5, x1, 141, col)
  g <- txt(g, x0 + 2, 140, paste0(num, "  ", title), 5.0, "bold", "white"); g <- txt(g, x0 + 2, 135.4, sub, 3.7, "plain", "white")
  g <- box(g, x0, 114, x1, 129.5, lt, col, 0.6); g <- txt(g, x0 + 2, 128.6, "SOURCE", 3.0, "bold", col); g <- txt(g, x0 + 2, 125.3, source, 3.75)
  g <- arr(g, xm, 114, xm, 111.2, col)
  g <- box(g, x0, 95.5, x1, 111.2 - 0.0, lt, col, 0.6); g <- txt(g, x0 + 2, 110.3, "STANDARDIZED AS", 3.0, "bold", col); g <- txt(g, x0 + 2, 107, std, 3.75)
  g <- arr(g, xm, 95.5, xm, 92.7, col)
  g <- box(g, x0, 67, x1, 92.5, "white", col, 1.1); g <- txt(g, x0 + 2, 91.5, ex_title, 3.0, "bold", col)
  stack(g, x0 + 2, 88, ex, 3.7, 2.0, col)
}
g <- path(g, "clin", "1", "CLINICAL PATH", "what happened to the person",
  "EHR or claims data at the data partner,\nstandardized to the OMOP CDM: PERSON,\nOBSERVATION_PERIOD, EPISODE and\nCONDITION_OCCURRENCE",
  "A person_id with clinical time windows:\nan index date, a pregnancy, a diagnosis.\nStandard concepts, e.g. Pregnancy 4299535,\nCOPD 255573",
  "EXAMPLE: PERSON 9 (SYNTHETIC)",
  list(c("b", "PERSON"), c("p", "female, born 1981"), c("b", "OBSERVATION_PERIOD"), c("p", "2014-01-01 to 2019-12-31"), c("b", "EPISODE (pregnancy)"), c("p", "2016-05-20 to 2017-02-10 (267 days)"), c("p", ""), c("b", "Whole dataset"), c("p", "10,000 persons; 1,086 with a COPD diagnosis")))
g <- path(g, "loc", "2", "LOCATION PATH", "where they lived, and when",
  "Addresses stay at the data partner. They are\ngeocoded locally (DeGAUSS, PostGIS, Nominatim\nor ArcGIS) to a point; only the point and the\ndates are used downstream",
  "OMOP GIS extension: LOCATION (a point) and\nLOCATION_HISTORY (person, location, start and\nend date, relationship = Patient Residence\n2052496995)",
  "EXAMPLE: LOCATION_HISTORY OF PERSON 9",
  list(c("b", "location 9: 2014-01-01 to 2016-08-14"), c("p", "Fauquier Crossing, VA"), c("p", "Fauquier County, FIPS 51061"), c("b", "location 10009: 2016-08-15 to 2019-12-31"), c("p", "Lamar Crossing, MS"), c("p", "Lamar County, FIPS 28073"), c("p", ""), c("p", "The move falls mid-pregnancy and splits"), c("p", "one month. 955 of 10,000 persons move once.")))
g <- path(g, "geo", "3", "GEOSPATIAL PATH", "what the places were like",
  "Public datasets: CDC monthly PM2.5 (EPA\nDownscaler), Census TIGER county boundaries,\na simulated SES index. Each is described by a\ncatalog entry (JSON-LD metadata)",
  "GaiaDB geometry-attribute index: every source\nis registered the same way (geom_index,\nattr_index) with its concept, unit, period and\nsource id",
  "EXAMPLE: THE TWO COUNTIES",
  list(c("b", "PM2.5 monthly mean, ug/m3 (source id 23)"), c("p", "Fauquier: Jun 2016 7.65, Jul 2016 8.55"), c("p", "Lamar: Sep 2016 8.82, Oct 2016 10.30"), c("b", "SES index (simulated)"), c("p", "Fauquier 58.6, Lamar 68.2"), c("b", "County polygons (Census TIGER 2023)"), c("p", "Fauquier 51061, Lamar 28073"), c("p", ""), c("p", "Whole index: 2,672 counties, 72 months")))

mc <- pal$merge[1]; yo <- 6
lab <- c(clin = "person_id + clinical window", loc = "location + residence interval", geo = "polygons + monthly values")
for (k in c("clin", "loc", "geo")) { xm <- mean(cols[[k]]); g <- arr(g, xm, 67, xm, 63.6, pal[[k]][1], 1.6); g <- txt(g, xm + 1.8, 65.3, lab[[k]], 3.1, "italic", pal[[k]][1], vjust = 0.5) }

g <- box(g, 3, 33.5 + yo, 157, 58 + yo, pal$merge[2], mc, 1.1)
g <- txt(g, 5, 57 + yo, "MERGE: THE SPATIAL-TEMPORAL JOIN IN GAIADB  (spatial_join_from_catalog)", 4.2, "bold", mc)
g <- stack(g, 5, 51.8 + yo, list(c("p", "1  Place: the person's point falls inside a county polygon"), c("p", "    (ST_Within)"), c("p", "2  Time: the month overlaps the residence interval and"), c("p", "    is clipped to it"), c("p", "3  Result: one EXTERNAL_EXPOSURE row per person, location"), c("p", "    and interval, carrying its concept (PM2.5 2052499839),"), c("p", "    type (Air Quality Database 2052499878), relationship"), c("p", "    (Within 2052496943) and source id (23)")), 3.7, 2.05)
g <- box(g, 74, 35 + yo, 155, 53.5 + yo, "white", mc, 0.8)
g <- txt(g, 75.5, 52.6 + yo, "EXTERNAL_EXPOSURE rows of person 9 around the move (one month, two counties, two rows)", 3.0, "bold", mc)
tx <- c(75.5, 83, 91.5, 102, 130)
hdr <- c("row id", "person", "location", "interval", "PM2.5 ug/m3")
r1 <- c("617", "9", "9", "2016-08-01 to 2016-08-14", "6.954  (Fauquier)")
r2 <- c("618", "9", "10009", "2016-08-15 to 2016-08-31", "7.998  (Lamar)")
fc <- c(mc, pal$clin[1], pal$loc[1], pal$loc[1], pal$geo[1])
for (i in 1:5) { g <- txt(g, tx[i], 48.6 + yo, hdr[i], 3.3, "bold", fc[i]); g <- txt(g, tx[i], 45.6 + yo, r1[i], 3.5, "bold", fc[i]); g <- txt(g, tx[i], 42.9 + yo, r2[i], 3.5, "bold", fc[i]) }
g <- txt(g, 75.5, 39.6 + yo, "Colors show where each field came from: clinical path, location path,\ngeospatial path. Whole dataset: 720,925 PM2.5 and 10,955 SES rows.", 3.2, "italic", "#444444")
g <- arr(g, 80, 33.5 + yo, 80, 30.7 + yo, mc, 1.6)

g <- box(g, 3, 13 + yo, 157, 30.5 + yo, "white", "#33333a", 1.1)
g <- txt(g, 5, 29.6 + yo, "RESEARCH INTEGRATION: THE EXPOSURE RECORD MEETS THE CLINICAL QUESTION", 4.2, "bold", "#33333a")
sub <- list(
  list(x = 5, t = "Align to the clinical window", b = "Pregnancy 2016-05-20 to 2017-02-10:\n11 exposure rows over 267 days give a\nday-weighted mean of 8.474 ug/m3.\nThe naive row mean, 8.331, is wrong."),
  list(x = 55.75, t = "Build cohorts and features", b = "Index 2016-01-01, exposure at index:\nhigh (10 or more ug/m3): 2,717 persons\nlow (under 8 ug/m3): 3,099 persons\nCOPD 1,086; negative control CKD 1,384"),
  list(x = 106.5, t = "Estimate the effect", b = "Adjusted for SES, age, sex; county-\nclustered intervals. COPD slope 0.108 per\nug/m3 (simulated truth 0.15); matched hazard\nratio 1.26 (1.01-1.57); CKD 0.94 (0.77-1.15)"))
for (s in sub) { g <- box(g, s$x, 14.2 + yo, s$x + 48.5, 26.8 + yo, "#f6f6f6", "#bbbbbb", 0.5); g <- txt(g, s$x + 1.5, 26 + yo, s$t, 3.7, "bold", "#33333a"); g <- txt(g, s$x + 1.5, 22.7 + yo, s$b, 3.4, lineheight = 1.2) }
g <- arr(g, 80, 13 + yo, 80, 10.8 + yo, "#33333a", 1.6)

g <- box(g, 3, 0.8, 157, 10.5 + yo, pal$ev[1])
g <- txt(g, 5, 9.8 + yo, "RELIABLE HEALTH EVIDENCE", 4.2, "bold", "white")
ev <- list(c("Traceable", "every row names its source variable (23: CDC county PM2.5)"), c("Verified", "720,925 of 720,925 rows match an independent answer key"), c("Quality-checked", "4 of 4 deliberately bad rows caught before analysis"), c("Calibrated", "negative control stays null; intervals allow for clustering"))
for (i in seq_along(ev)) { x <- 5 + (i - 1) * 38; g <- txt(g, x, 11 , ev[[i]][1], 3.6, "bold", "white"); g <- txt(g, x, 8.3, paste(strwrap(ev[[i]][2], 30), collapse = "\n"), 3.2, "plain", "white", lineheight = 1.15) }
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ggsave(file.path(out, "three_paths_workflow.png"), g, width = 16, height = 15, dpi = dpi, device = ragg::agg_png)
svglite::svglite(file.path(out, "three_paths_workflow.svg"), width = 16, height = 15); print(g); invisible(dev.off())
pdf(file.path(out, "three_paths_workflow.pdf"), width = 16, height = 15); print(g); invisible(dev.off())
