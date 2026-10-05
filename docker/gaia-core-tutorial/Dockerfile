# Tutorial image for the OHDSI GIS tutorial: HADES (RStudio) plus the extension packages.
# Build:  docker build --platform linux/amd64 -t ohdsi/gaia-core-tutorial:1 docker/gaia-core-tutorial
# ohdsi/broadsea-hades:1.19.0 (R 4.4.1, Capr 2.1.0, CohortMethod 5.5.1, FeatureExtraction 3.11.0, DatabaseConnector 7.0.0)
FROM ohdsi/broadsea-hades@sha256:95ade14db0acc2dd25d46e82b937399598b547fcec109e7255b61ab6ecf6868e

# Pinned commits of the two extension packages (the exercises need these fixes)
ARG CAPR_EXT_REF=76b958db9697f7c6e08a01458d24767bb3daddc6
ARG FE_EXT_REF=c339850bf6a4f54beec66f26cc9ad8b4fcec2468

RUN Rscript -e "options(Ncpus = 2); remotes::install_github('OHDSI/CaprForExtensions', ref = '${CAPR_EXT_REF}', upgrade = 'never')"
RUN Rscript -e "options(Ncpus = 2); remotes::install_github('OHDSI/FeatureExtractionForExtensions', ref = '${FE_EXT_REF}', upgrade = 'never')"


# Build-time smoke test: the packages load and the PostgreSQL JDBC driver is present
RUN Rscript -e "library(CaprForExtensions); library(FeatureExtractionForExtensions); library(CohortMethod); library(DatabaseConnector); stopifnot(length(list.files(Sys.getenv('DATABASECONNECTOR_JAR_FOLDER'), pattern = '^postgresql')) > 0)"
