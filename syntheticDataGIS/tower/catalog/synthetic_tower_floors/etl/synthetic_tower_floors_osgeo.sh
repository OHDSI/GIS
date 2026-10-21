#!/bin/bash

export POSTGRES_PASSWORD=$(cat $PG_PASSWORD_FILE)

mkdir -p /data/synthetic_tower_floors/download -p /data/synthetic_tower_floors/etl
chmod -R 777 /data/synthetic_tower_floors
cd /data/synthetic_tower_floors

do_update=0
[[ -e datestamp ]] || do_update=1

if [[ $do_update = 1 ]]; then
  attempts=0
  until (
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 10 -O download/synthetic_tower_floors.csv 'https://raw.githubusercontent.com/OHDSI/GIS/main/syntheticDataGIS/tower/data/tower_floors.csv' 2>&1
  ); do
    ((attempts++))
    if (( attempts > 3 )); then echo $?; break; fi
  done
  echo $(date '+%F %T') > datestamp
fi

ogr2ogr -f PostgreSQL PG:"dbname=$POSTGRES_DB port=$POSTGRES_PORT user=$POSTGRES_USER password=$POSTGRES_PASSWORD host='gaia-db'" download/synthetic_tower_floors.csv -oo GEOM_POSSIBLE_NAMES=wkt -oo KEEP_GEOM_COLUMNS=NO -a_srs EPSG:4269 -nln synthetic_tower_floors_raw -lco GEOMETRY_NAME=geom -overwrite
echo success: synthetic_tower_floors.csv loaded with ogr2ogr
