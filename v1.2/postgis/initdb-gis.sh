#!/bin/bash
set -e

mkdir -p /tmp/gisdata/temp

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  UPDATE tiger.loader_variables SET staging_fold = '/tmp/gisdata';
  UPDATE tiger.loader_platform SET pgbin = '/usr/bin' WHERE os = 'sh';
  UPDATE tiger.loader_platform SET declare_sect = '
    TMPDIR="\${staging_fold}/temp/"
    UNZIPTOOL=unzip
    WGETTOOL="/usr/bin/wget"
    export PGBIN=/usr/lib/postgresql/13/bin
    export PGUSER=$POSTGRES_USER
    export PGDATABASE=$POSTGRES_DB
    PSQL=\${PGBIN}/psql
    SHP2PGSQL=shp2pgsql
    cd \${staging_fold}
  '
  WHERE os = 'sh';
EOSQL
