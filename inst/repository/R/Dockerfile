FROM ubuntu:latest

# get necessary system utilties
RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    default-jre \
    default-jdk

# add needed repository for GIS tools
RUN add-apt-repository ppa:ubuntugis/ppa
RUN apt update && apt upgrade -y

# get libraries for GIS tools
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y \
    libgdal-dev gdal-bin \
    libproj22 \
    libproj-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libudunits2-dev \
    libsodium-dev \
    r-base

# install all known dependencies for gaiaCore
RUN R -e "install.packages(c( \
    'devtools', \
    'bit', \
    'bit64', \
    'blob', \
    'checkmate', \
    'class', \
    'classInt', \
    'DatabaseConnector', \
    'DBI', \
    'dbplyr', \
    'dplyr', \
    'e1071', \
    'generics', \
    'hms', \
    'KernSmooth', \
    'lattice', \
    'MASS', \
    'plyr', \
    'plumber', \
    'progress', \
    'proxy', \
    'raster', \
    'readr', \
    'rgeos', \
    'rJava', \
    'rjson', \
    'rpostgis', \
    'RPostgreSQL', \
    'sf', \
    'sp', \
    'SqlRender', \
    'terra', \
    'tidyr', \
    'tidyselect', \
    'triebeard', \
    'tzdb', \
    'units', \
    'urltools', \
    'usethis', \
    'vroom' \
    ))"

# install gaiaCore
RUN R -e "library('devtools'); devtools::install_github('OHDSI/GIS')"

# copy DatabaseConnector jar file for postgres
RUN mkdir /ohdsi-gis && mkdir /ohdsi-gis/dbJars
COPY ./dbJars /ohdsi-gis/dbJars
ENV DATABASECONNECTOR_JAR_FOLDER /ohdsi-gis/dbJars

# copy api app for gaiaCore
COPY ./R /ohdsi-gis
WORKDIR /ohdsi-gis

CMD ["sh", "-c", "Rscript gaia.R"]