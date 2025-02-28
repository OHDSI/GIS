# OHDSI GIS Workgroup

## Introduction

Please visit our [webpage](https://ohdsi.github.io/GIS/index.html) for more details and the most **up-to-date information** and **software documentation**. 

For **project management**, see the [GIS Project Page](https://github.com/orgs/OHDSI/projects/26)

[Click here](https://github.com/OHDSI/GIS/issues/new?assignees=&labels=Use+Case&projects=&template=use-case.yaml&title=%5BUse+Case%5D%3A+) to propose a new **Use Case**.

## Our Work

### [OMOP GIS Vocabulary Package](https://github.com/OHDSI/GIS/tree/main/vocabularies)
The OMOP GIS (Geographic Information System) Vocabulary Package is designed to elevate data-driven healthcare research by enabling the integration of spatial, environmental, behavioral, socioeconomic, phenotypic, and toxin-related determinants of health into standardized data structures.
Features:
- OMOP GIS Vocabulary
- OMOP Exposome Vocabulary
- OMOP SDoH (Social Determinants of Health) Vocabulary

### [gaiaDB](https://github.com/ohdsi/gaiaDB)
A staging database and collection of transformation recipes for public place-based datasets

### [gaiaCore](https://github.com/ohdsi/gaiaCore)
An R Package for interacting with gaiaDB - part of the OHDSI GIS Gaia toolchain

## Quick Start

Instructions to quickly install and start using Gaia are [here](https://ohdsi.github.io/GIS/getting-started.html)

### Docker Quick Start
> Prerequisite: this solution requires that you have Docker and Docker Compose installed. See [here](https://docs.docker.com/engine/install/).

Containerized instances of gaiaDB (geospatial data store) and the gaiaCore R package (built in to Broadsea Hades and wrapped with an HTTP API via Plumber) can quickly be deployed and connected using Docker Compose

```bash
git clone git@github.com:OHDSI/GIS.git

cd GIS

docker compose -f ./docker/docker-compose.yaml up -d
```

Configure database connection details and HTTP API port in the .env file in the docker directory.

At this time, images are *not* published and are built when docker compose is run:

The gaiaDB image is **built** from the Dockerfile in the [gaiaDB repository](https://github.com/ohdsi/gaiaDB).

The gaiaCore image is **built** from the Dockerfile in the docker directory in this repository.

## Support

-   Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
-   Please use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements

## Contributing

We are eager to engage with interested developers with interest or experience in frontend, backend, and geospatial development.

If you are interested in contributing and don't know where to begin, please join the OHDSI GIS WG or email at zollovenecek[at]ohdsi[dot]org
