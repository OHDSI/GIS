FROM postgis/postgis:13-3.1

COPY ./csv /inst/csv

COPY ./ddl/001/gaia_schema.sql /docker-entrypoint-initdb.d/11_create_schema.sql

COPY ./ddl/001/gaiadb_001_ddl.sql /docker-entrypoint-initdb.d/12_ddl.sql

COPY ./ddl/001/gaiadb_001_sequences.sql /docker-entrypoint-initdb.d/13_sequences.sql

COPY ./ddl/001/gaia_csv_load.sql /docker-entrypoint-initdb.d/14_csv.sql

COPY ./ddl/001/gaia_fill_index_tables.sql /docker-entrypoint-initdb.d/15_index_tables.sql
