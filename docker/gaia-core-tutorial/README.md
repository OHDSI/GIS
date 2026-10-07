# Tutorial R image

An RStudio image for Exercises 3 and 4: the HADES base image (`ohdsi/broadsea-hades`, with Capr, CirceR, CohortMethod, FeatureExtraction, DatabaseConnector and the PostgreSQL JDBC driver) plus [CaprForExtensions](https://github.com/OHDSI/CaprForExtensions) and [FeatureExtractionForExtensions](https://github.com/OHDSI/FeatureExtractionForExtensions), both pinned to a commit.

The image is built and pushed to Docker Hub as `ohdsi/gaia-core-tutorial` by the CI workflow on every push to `main`, so participants pull it instead of building anything:

```sh
docker pull --platform linux/amd64 ohdsi/gaia-core-tutorial:main
```

Start it next to the Gaia stack from [Get Started](https://ohdsi.github.io/GIS/get-started.html), on the same Docker network so it can reach the database as `gaia-db` (stop the `gaia-core` service first if you started it: both use port 8787). On Apple Silicon keep `--platform linux/amd64`:

```sh
docker run -d --name gaia-core-tutorial --platform linux/amd64 --network gaiadocker_default -p 8787:8787 \
  -e USER=ohdsi -e PASSWORD=<choose a password> ohdsi/gaia-core-tutorial:main
```

Then open <http://localhost:8787> and sign in with `ohdsi` and that password. In R, connect with `server = "gaia-db/gaiacore"` and the Postgres password from `gaiaDocker/secrets/gaia/POSTGRES_PASSWORD`; `DATABASECONNECTOR_JAR_FOLDER` is already set, so `pathToDriver` is optional. (`gaiadocker_default` is the network docker compose creates for a checkout in a folder called `gaiaDocker`; list yours with `docker network ls`.)

To build the image yourself instead (for example to test a change), run `docker build --platform linux/amd64 -t ohdsi/gaia-core-tutorial:local docker/gaia-core-tutorial`.

## What was tested

With this image, against the tutorial dataset restored into PostgreSQL 16, the code in Exercises 3 and 4 runs end to end: Capr cohort generation (cohort counts match SQL exactly), the FeatureExtractionForExtensions covariates, and the CohortMethod analysis.

## Package versions

Exercises 3 and 4 use the fixed versions of the two extension packages (custom-domain queries accepted by `entry()`/`atLeast()`, a working `dateRange()`, the registered `end_date_field` used as the event end date, schema-qualified target tables, and, in FeatureExtractionForExtensions, `conceptSet` row filtering, `valueAggregation`, `endDateField`, a working `isBinary`, covariate ids encoded as `id * 1000 + analysisId`, and aggregated covariates). The Dockerfile pins both to the commits that contain these fixes (`CAPR_EXT_REF`, `FE_EXT_REF`); update the pins together with the exercises if the packages change.

## Other notes

- **CohortMethod:** the base image has CohortMethod 5.5, so the exercise uses the 5.x function signatures (the 6.x `create...Args()` objects do not exist). Update both together if you move to a newer base.
- **Propensity model:** with the SDOH covariates the default cross-validated prior shrinks every coefficient to zero, so the exercise passes a fixed ridge prior and a higher iteration limit to `createPs`.
