# render_gaia_site.R
# This script rebuilds the OHDSI GIS website and documentation using pkgdown and rmarkdown.

# Run from the root of the repository
if (!file.exists("DESCRIPTION")) {
  stop("Please run this script from the root folder of the GIS repository.")
}

required_packages <- c("devtools", "rmarkdown", "pkgdown")
missing <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
if (length(missing)) {
  stop("Missing required packages: ", paste(missing, collapse = ", "))
}

library(devtools)
library(rmarkdown)
library(pkgdown)

# Step 1: Update Roxygen documentation (.Rd)
document()

# Step 2: Render the website content from ./rmd into ./docs
setwd("rmd")
render_site()
setwd("..")

# Step 3: Generate the pkgdown site into ./docs/gaiaCore
pkgdown::build_site(
  override = list(destination = "docs/gaiaCore"),
  new_process = FALSE
)
