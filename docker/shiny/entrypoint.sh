#!/bin/bash
set -e

mkdir -p $(pg_config --sysconfdir)

cat << EOF > $(pg_config --sysconfdir)/pg_service.conf
[gis_postgis]
host=gis_postgis
port=5432
user=$POSTGRES_USER
dbname=$POSTGRES_DB
password=$(cat $POSTGRES_PASSWORD_FILE)
EOF

exec "$@"
