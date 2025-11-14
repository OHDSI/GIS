#!/usr/bin/env Rscript

# Build RMarkdown site for OHDSI GIS Working Group
# This script renders all .Rmd files in the rmd/ directory to HTML in docs/

# Check if rmarkdown package is installed
if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Package 'rmarkdown' is required but not installed.\n",
       "Install it with: install.packages('rmarkdown')")
}

# Set working directory to rmd/ folder
setwd("rmd")

# Render the entire site
cat("Building OHDSI GIS documentation site...\n")
rmarkdown::render_site(encoding = "UTF-8")

cat("\nSite built successfully!\n")
cat("Output directory: docs/\n")
cat("To view locally, open: docs/index.html\n")
