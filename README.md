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

1.  See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including RTools and Java.

2.  You can install the development version of gaiaCore from [GitHub](https://github.com/) with:

    ``` r
    # install.packages("devtools")
    devtools::install_github("OHDSI/GIS/packages/gaiaCore")
    ```

3.  See the example_execution vignette for information on creating a backbone schema, loading data source and variable information, and creating indices in a Postgres/PostGIS instance.

# User Documentation

# Support

-   Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
-   We use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements

# Contributing

Read [here](https://ohdsi.github.io/Hades/contribute.html) how you can contribute to this package.

# License

GIS is licensed under Apache License 2.0

# Development

GIS is being developed in R Studio.

### Development status

Under development

# Acknowledgements
