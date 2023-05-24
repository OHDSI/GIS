#' A function to render RMD site and embed R package docs
render_gaia_site <- function() {
  devtools::document('packages/gaiaCore')
  rmarkdown::render_site('rmd')
  pkgdown::build_site('packages/gaiaCore')
}

render_gaia_site()