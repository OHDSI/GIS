#' A function to render RMD site and embed R package docs
render_gaia_site <- function() {
  devtools::document()
  rmarkdown::render_site('rmd')
  pkgdown::build_site()
}

render_gaia_site()