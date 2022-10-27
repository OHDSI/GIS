# OHDSI GIS

# Introduction

An R package and RShiny app for working with OMOP CDM data in conjunction with geospatial data in a standardized format.

# Features

-   Ability to register desired geospatial data sources.
-   Work with PHI in a local environment.

# Technology

gaiaCore is an R package created by the OHDSI GIS work group. A Postgres/PostGIS database is used to store and maintain source records.

# System Requirements

To set up the backbone schema, you must have a Postgres/PostGIS database 

# Getting Started

## Installing the gaiaCore R package

1.  See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including RTools and Java.

2.  You can install the development version of gaiaCore from [GitHub](https://github.com/) with:

    ``` r
    # install.packages("devtools")
    devtools::install_github("OHDSI/GIS/packages/gaiaCore")
    ```
## Installing the database

gaiaDB is a postgres database with PostGIS installed and a schema called "backbone" that stores source information and more.

### In an existing postgres instance

See the example_execution vignette in the gaiaCore R package for instructions on creating a backbone schema, loading data source and variable information, and creating indices in an existing Postgres/PostGIS instance.

### As a Docker Container

1. You will need to have Docker and Docker Compose installed. The easiest way to install Docker and Docker Compose is by installing [Docker Desktop]([url](https://docs.docker.com/desktop/)).

2. Download the `init` directory from this repository.

3. From a terminal (Command Prompt or Powershell on Windows), make sure the `init` directory is your working directory.

4. Run command `docker-compose up -d`. This will build a docker image, install the database, load the data and variable sources, and expose the database at port 5432.
- Note: to change the port, open the file `docker-compose.yml` and edit line 10 from `- "5432:5432"` to `- "X:5432"` where `X` is the desired port.

5. You can now connect to the database from R using localhost, port 5432 (if not changed), username "postgres", and password "mysecretpassword"
- Note: to change your password, edit line 13 of the `docker-compose.yml` file. If you've already started the container, you will need to shut down the container, remove the volumes and image that were created, and redo step 4 for the password change to take effect.

# Support

-   Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
-   Please use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements

# Contributing

Read [here](https://ohdsi.github.io/Hades/contribute.html) how you can contribute to this package.

# License

GIS is licensed under Apache License 2.0

# Development

gaiaCore is being developed in R Studio.

gaiaDB is being developed in Postgres/PostGIS

## Development status

Under development
