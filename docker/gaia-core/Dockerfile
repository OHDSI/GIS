FROM ohdsi/broadsea-hades:4.2.1

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        libpq-dev \
        libudunits2-dev \
        libgdal-dev \
        libgeos-dev \
        libproj-dev

RUN Rscript -e 'remotes::install_github("OHDSI/GIS")'

#ENTRYPOINT ["/app/entrypoint.sh"]
