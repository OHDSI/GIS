FROM ohdsi/broadsea-hades:4.2.1

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        libpq-dev \
        libudunits2-dev \
        libgdal-dev \
        libgeos-dev \
        libproj-dev

# Temporary workaround for bug in sf -> https://forum.posit.co/t/sf-wont-install-for-anyone-on-posit-cloud/191242/2
RUN Rscript -e 'remotes::install_github(repo = "r-spatial/sf", ref = "93a25fd8e2f5c6af7c080f92141cb2b765a04a84")'

RUN Rscript -e 'remotes::install_github("OHDSI/GIS")'

# This provides an API to gaiaCore, could be moved to the package DESCRIPTION
RUN Rscript -e 'install.packages("plumber")'

# copy api app for gaiaCore
COPY ./docker/gaia-core/R /ohdsi-gis
WORKDIR /ohdsi-gis

# CMD ["sh", "-c", "Rscript gaia.R"]

#ENTRYPOINT ["/app/entrypoint.sh"]
