#!/usr/bin/env Rscript
# Builds the ARES network-level index files (index.json, data quality, performance, ...) for an ARES
# data folder written by run_ares_pipeline.R, using the OHDSI AresIndexer package.
#
# Usage: Rscript index_ares_data.R <ares data folder>
args <- commandArgs(trailingOnly = TRUE)
aresPath <- args[1]
suppressMessages(library(AresIndexer))

sourceFolders <- list.dirs(aresPath, recursive = FALSE, full.names = TRUE)
step <- function(label, expr) {
  cat("AresIndexer:", label, "\n")
  tryCatch(force(expr), error = function(e) cat("  skipped:", conditionMessage(e), "\n"))
}

for (sourceFolder in sourceFolders) {
  step(paste("history indexes for", basename(sourceFolder)), {
    AresIndexer::buildDataQualityHistoryIndex(sourceFolder)
    AresIndexer::buildDataSourceHistoryIndex(sourceFolder)
  })
  for (releaseFolder in list.dirs(sourceFolder, recursive = FALSE, full.names = TRUE)) {
    step(paste("concept files for", basename(releaseFolder)), AresIndexer::augmentConceptFiles(releaseFolder))
  }
}
step("network index", AresIndexer::buildNetworkIndex(sourceFolders, aresPath))
step("data quality index", AresIndexer::buildDataQualityIndex(sourceFolders, aresPath))
step("unmapped source code index", AresIndexer::buildNetworkUnmappedSourceCodeIndex(sourceFolders, aresPath))
step("performance index", AresIndexer::buildNetworkPerformanceIndex(aresPath))
step("export query index", AresIndexer::buildExportQueryIndex(aresPath))
