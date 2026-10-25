#!/usr/bin/env bash
# Regenerates syntheticDataGIS/ares/demo-data: the tutorial dataset run through Achilles, the Data
# Quality Dashboard and Achilles::exportToAres() (including the geographic export), plus the
# AresIndexer network indexes. The result is what the GitHub Pages ARES demo publishes.
#
#   run_pipeline.sh [path/to/Achilles]
#
# With a path, that Achilles checkout is installed and used (needed for the geographic export until
# it is in a release); without one the Achilles in the image is used.
# Needs Docker and an image with R, DatabaseConnector, duckdb, CommonDataModel and
# DataQualityDashboard (default ohdsi/gaia-core:main, override with IMAGE=...).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
gis="$(cd "$here/../.." && pwd)"
image="${IMAGE:-ohdsi/gaia-core:main}"
achilles="${1:-}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mounts=(-v "$gis:/gis:ro" -v "$work:/work")
install_achilles=""
if [ -n "$achilles" ]; then
  mounts+=(-v "$(cd "$achilles" && pwd):/achilles:ro")
  install_achilles='mkdir -p /tmp/src && cp -r /achilles/. /tmp/src/ && R CMD INSTALL --no-docs --no-test-load -l /work/rlib /tmp/src >/work/achilles-install.log'
fi

docker run --rm --entrypoint "" "${mounts[@]}" "$image" bash -euc "
  mkdir -p /work/rlib
  $install_achilles
  export R_LIBS=/work/rlib
  Rscript -e 'if (!requireNamespace(\"AresIndexer\", quietly = TRUE)) remotes::install_github(\"OHDSI/AresIndexer\", lib = \"/work/rlib\", upgrade = \"never\")'
  Rscript /gis/syntheticDataGIS/ares/build_cdm.R /gis/syntheticDataGIS/data /gis/inst/ddl/5.4/duckdb /work/cdm.duckdb
  Rscript /gis/syntheticDataGIS/ares/run_ares_pipeline.R /work/cdm.duckdb /work/out
  Rscript /gis/syntheticDataGIS/ares/index_ares_data.R /work/out/ares
"
rm -rf "$here/demo-data"
mkdir -p "$here/demo-data"
cp -R "$work/out/ares/." "$here/demo-data/"
echo "wrote $here/demo-data ($(du -sh "$here/demo-data" | cut -f1))"
