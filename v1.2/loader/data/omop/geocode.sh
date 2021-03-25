PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -h gis_postgis --dbname "$POSTGRES_DB" -tA <<-EOSQL
  call geocode(500);
EOSQL
