# Tutorial R image

An RStudio image for Exercises 3 and 4: the HADES base image (`ohdsi/broadsea-hades`, with Capr, CirceR, CohortMethod, FeatureExtraction, DatabaseConnector and the PostgreSQL JDBC driver) plus [CaprForExtensions](https://github.com/OHDSI/CaprForExtensions) and [FeatureExtractionForExtensions](https://github.com/OHDSI/FeatureExtractionForExtensions), both pinned to a commit.

```sh
docker build --platform linux/amd64 -t ohdsi/gaia-core-tutorial:1 docker/gaia-core-tutorial
```

Use it in place of the `gaia-core` service in gaiaDocker (same RStudio login and ports as the HADES base image). Connect to the database with `server = "gaia-db/gaiacore"`; `DATABASECONNECTOR_JAR_FOLDER` is already set, so `pathToDriver` is optional.

## What was tested

With this image, against the tutorial dataset restored into PostgreSQL 16, the code in Exercises 3 and 4 runs end to end: Capr cohort generation (cohort counts match SQL exactly), the FeatureExtractionForExtensions covariates, and the CohortMethod analysis.

## Package versions

Exercises 3 and 4 use the fixed versions of the two extension packages: custom-domain queries accepted by `entry()`/`atLeast()`, a working `dateRange()`, the registered `end_date_field` used as the event end date, schema-qualified target tables, and, in FeatureExtractionForExtensions, `conceptSet` row filtering, `valueAggregation`, `endDateField`, a working `isBinary`, covariate ids encoded as `id * 1000 + analysisId`, and aggregated covariates (`aggregated = TRUE`, computed in the database by default). After those commits are pushed, set `CAPR_EXT_REF` and `FE_EXT_REF` in the Dockerfile to them (the values in the file are the commits before the fixes and do not run the exercises as written).

## Other notes

- **CohortMethod:** the base image has CohortMethod 5.5, so the exercise uses the 5.x function signatures (the 6.x `create...Args()` objects do not exist). Update both together if you move to a newer base.
- **Propensity model:** with the SDOH covariates the default cross-validated prior shrinks every coefficient to zero, so the exercise passes a fixed ridge prior and a higher iteration limit to `createPs`.
