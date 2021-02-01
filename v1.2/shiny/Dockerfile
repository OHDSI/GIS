FROM rocker/shiny-verse:4.0.3

# TODO: only install needed components for release,
#   geospatial takes a while to install and rstudio
#   probably isn't needed

RUN /rocker_scripts/install_geospatial.sh

RUN /rocker_scripts/install_rstudio.sh
