#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tA <<-EOSQL
  CREATE EXTENSION address_standardizer;
EOSQL

# Run all DDL create scripts
cat /DDL/*.sql | psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tA -1
