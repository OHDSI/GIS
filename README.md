# OHDSI GIS Workgroup

## Introduction

Welcome to the **OHDSI Geographic Information Systems (GIS) Working Group** – the central hub for integrating geospatial and person-level health data within the OHDSI ecosystem.

**Mission**: Improve the health of populations by generating reliable evidence from integrated geospatial and person-level health data.

Please visit our [webpage](https://ohdsi.github.io/GIS/index.html) for more details and the most **up-to-date information** and **software documentation**.

For **project management**, see the [GIS Project Page](https://github.com/orgs/OHDSI/projects/26)

[Click here](https://github.com/OHDSI/GIS/issues/new?assignees=&labels=Use+Case&projects=&template=use-case.yaml&title=%5BUse+Case%5D%3A+) to propose a new **Use Case**.

## GIS Working Group Ecosystem

The OHDSI GIS Working Group maintains and develops several interconnected repositories that together form the **Gaia toolchain**:

### Core Infrastructure Repositories

**[OHDSI/GIS](https://github.com/OHDSI/GIS)** (this repository)
- Central documentation and coordination hub
- OMOP GIS schema extensions
- Use case tracking and project management
- Developer guidelines and contribution workflows

**[OHDSI/gaiaDb](https://github.com/OHDSI/gaiaDb)**
- PostgreSQL/PostGIS database serving as the core data repository
- Geospatial data ingestion, management, and analysis
- SQL routines and PostGIS functionality
- OMOP CDM integration
- LinkML/JSON-LD metadata support

**[OHDSI/gaiaCore](https://github.com/OHDSI/gaiaCore)**
- R package for working with gaiaDB, connecting directly through DatabaseConnector
- Runs the Gaia pipeline from R: ingestion, location loading, the spatial-temporal join
- Quality checks on derived exposure and copy into the OMOP CDM
- Exposure analytics (day-weighted windows, cluster-robust effect estimates)
- Docker image `ohdsi/gaia-core` (HADES with gaiaCore and the extension packages)

**[OHDSI/gaiaCatalog](https://github.com/OHDSI/gaiaCatalog)**
- Metadata catalog for geospatial data sources
- Schema.org-compliant data discovery
- Federated metadata sharing

**[OHDSI/gaiaDocker](https://github.com/OHDSI/gaiaDocker)**
- Containerized deployment of Gaia toolchain
- Coordinated image builds and versioned releases
- Docker Compose orchestration
- Complete GIS stack deployment

### Vocabulary Resources

**[TuftsCTSI/CVB](https://github.com/TuftsCTSI/CVB)**
- OMOP GIS Vocabulary Package delta files
- OMOP Exposome Vocabulary
- OMOP SDoH (Social Determinants of Health) Vocabulary
- Toxins and environmental exposure vocabularies

Find the Delta Vocabulary files for the Vocabulary Package [here](https://github.com/TuftsCTSI/CVB/tree/main/GIS/Ontology)

## Our Work

### [OMOP GIS Vocabulary Package](https://ohdsi.github.io/GIS/vocabulary.html)
The OMOP GIS (Geographic Information System) Vocabulary Package is designed to elevate data-driven healthcare research by enabling the integration of spatial, environmental, behavioral, socioeconomic, phenotypic, and toxin-related determinants of health into standardized data structures.
Features:
- OMOP GIS Vocabulary
- OMOP Exposome Vocabulary
- OMOP SDoH (Social Determinants of Health) Vocabulary

### Gaia Toolchain
The Gaia toolchain provides end-to-end support for integrating geospatial data with OMOP CDM:
- **[gaiaDB](https://github.com/ohdsi/gaiaDB)**: PostgreSQL/PostGIS database with geospatial data processing, SQL routines, and OMOP integration
- **[gaiaCore](https://github.com/ohdsi/gaiaCore)**: R package that runs the Gaia pipeline against gaiaDB, checks the derived exposure and provides exposure analytics
- **[gaiaCatalog](https://github.com/ohdsi/gaiaCatalog)**: Data discovery and metadata management
- **[gaiaDocker](https://github.com/ohdsi/gaiaDocker)**: Containerized deployment with coordinated image builds and versioned releases

## Quick Start

Instructions to quickly install and start using Gaia are [here](https://ohdsi.github.io/GIS/getting-started.html)

### Docker Quick Start
> Prerequisite: this solution requires that you have Docker and Docker Compose installed. See [here](https://docs.docker.com/engine/install/).

The whole stack (gaiaDB, the catalog and the `gaia-core` RStudio image with the gaiaCore R package) is deployed with [gaiaDocker](https://github.com/OHDSI/gaiaDocker):

```bash
git clone https://github.com/OHDSI/gaiaDocker.git
cd gaiaDocker
docker compose --profile gaia up -d
```

Then connect from R with the gaiaCore package (also available as the image `ohdsi/gaia-core`); see the [gaiaCore documentation](https://ohdsi.github.io/gaiaCore/).

```bash
docker compose --profile gaia down
```

## Support

-   Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
-   Please use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements

## Contributing

We are eager to engage with interested developers with interest or experience in frontend, backend, and geospatial development.

If you are interested in contributing and don't know where to begin, please join the OHDSI GIS WG or email at zollovenecek[at]ohdsi[dot]org

See [Developer Resources](https://ohdsi.github.io/GIS/developer.html) for detailed contributing guidelines.

## Building Documentation

This repository uses RMarkdown to generate documentation hosted on GitHub Pages. To build the site locally:

```bash
# Quick start
Rscript build-site.R

# Or using R console
setwd("rmd")
rmarkdown::render_site(encoding = "UTF-8")
```

For detailed build instructions, see [BUILD.md](BUILD.md)
