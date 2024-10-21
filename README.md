# OHDSI GIS Workgroup

# Introduction

Please visit our [webpage](https://ohdsi.github.io/GIS/index.html) for more details and the most **up-to-date information** and **software documentation**. 

For **project management**, see the [GIS Project Page](https://github.com/orgs/OHDSI/projects/26)

[Click here](https://github.com/OHDSI/GIS/issues/new?assignees=&labels=Use+Case&projects=&template=use-case.yaml&title=%5BUse+Case%5D%3A+) to propose a new **Use Case**.

# Getting Started

Two docker services, gaia-db and gaia-core, can be used to link geospatial data to EHR location histories. Follow these steps to copy or build the images, start and connect the containers, load location, and output a table of "exposures" and a delta vocabulary that can be inserted into your CDM database.

## Copy or Build Gaia Images
You can build the images locally or pull from GHCR (choose one of COPY or BUILD)
```sh
# COPY
# requires auth echo <GH_PAT> | docker login ghcr.io -u "<GH_HANDLE>" --password-stdin
docker pull ghcr.io/tuftsctsi/gaia-core:main
docker pull ghcr.io/tuftsctsi/gaia-db:main

docker tag ghcr.io/tuftsctsi/gaia-core:main gaia-core
docker tag ghcr.io/tuftsctsi/gaia-db:main gaia-db

# BUILD
# git clone https://github.com/OHDSI/GIS.git
# cd GIS
docker build -t gaia-core -f docker/gaia-core/Dockerfile .
docker build -t gaia-db -f docker/gaia-db/Dockerfile .
```

## Run and Connect Containers
Create a network to allow the gaia-core R container to interact with the gaia-db database container 
```sh
docker network create gaia
docker run -itd --rm -e USER="ohdsi" -e PASSWORD="mypass" --network gaia -p 8787:8787 --name gaia-core gaia-core
docker run -itd --rm -e POSTGRES_PASSWORD=SuperSecret -e POSTGRES_USER=postgres --network gaia -p 5432:5432 --name gaia-db gaia-db
```

## Load "local" datasets
Local datasets can be used in gaia-db by loading them to the "offline storage directory", as specified in storage.yml, in the gaia-core container. This directory can be specified in the inst/config/storage.yml file before building the image. The default offline storage directory is /opt/data.

Datasets must share the `download_url` from the data_source_record and be stored in a subdirectory that shares the `dataset_name` from the data_source record:
```sh
# Create directory as specified in config.yml/offline_storage/directory
docker exec -it gaia-core bash -c "mkdir -p /opt/data/annual_measurement_2024"
# Copy file to directory specified in config.yml, with filename specified in data_source/download_url
docker cp /path/to/local/shpfile.zip gaia-core:/opt/data/annual_measurement_2024/shpfile.zip
```

## Using gaiaCore
The gaia-core container provides an R and RStudio environment with the R Package `gaiaCore` alongside the OHDSI HADES R Packages. `gaiaCore` provides the functionality for loading cataloged geospatial datasets into gaia-db and generate "exposures" by linking geospatial data to patient addresses.

You can access `gaiaCore` from an RStudio environment, simply navigate to `localhost:8787` in your browser. Login with the USER and PASSWORD assigned on container start (default: ohdsi, mypass)

Alternatively, you can access `gaiaCore` from the R Shell:

```sh
docker exec -it gaia-core R
```

In your R environment, create a connection to the gaia-db database, import and format a table with geocoded patient addresses, and create exposures by selecting the variable ID for the exposure of interest:
```R
# Connect to gaia-db
connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "postgresql",
    server = "gaia-db/postgres",
    user="postgres",
    password = "SuperSecret",
    pathToDriver = "/opt/hades/jdbc_drivers"
)

# Import and format geocoded addresses
location_import <- read.csv('location_geocoded.csv', sep="|", header=FALSE)
location_import <- dplyr::rename(location_import, location_id=1, lat=11, lon=12)
location_import <- dplyr::mutate(location_import,
    location_id=as.integer(location_id),
    lat=as.numeric(lat),
    lon=as.numeric(gsub("[\\n]", "", lon)))
location_import <- dplyr::filter(location_import, !is.na(lat) & !is.na(lon))
location_import <- location_import_sf <- sf::st_as_sf(location_import, coords=c('lon', 'lat'), crs=4326)
location_import <- dplyr::select(location_import, location_id, geometry)
location_import <- data.frame(location_import)
location_import$geometry <-
    sf::st_as_binary(location_import$geometry, EWKB = TRUE, hex = TRUE)

# Select exposure variable of interest
variableSourceId <- 1 # Percentile Percentage of persons below poverty estimate

# Create exposure
createExposure(connectionDetails, variableSourceId, location_import)
```



# Support

-   Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
-   Please use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements

# Contributing

We are eager to engage with interested developers with interest or experience in frontend, backend, and geospatial development.

If you are interested in contributing and don't know where to begin, please join the OHDSI GIS WG or email at zollovenecek[at]ohdsi[dot]org
