#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tA <<-EOSQL
  CREATE EXTENSION address_standardizer;
EOSQL

# Run all init create scripts (IS THIS NECESSARY?? seems to take place in gaiaCore::initializeDatabase(connectionDetails) )
cat /inst/sql/*.sql | psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tA -1