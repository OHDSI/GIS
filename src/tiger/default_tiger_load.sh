set -e
mkdir -p /gisdata/temp
mkdir -p /tmp/gisdata/temp

# zcta510 can be set to false, others are needed for loading state data and geocoder
PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" -h gis_postgis -tA <<-EOSQL
  UPDATE tiger.loader_lookuptables SET load = true
  WHERE table_name IN('zcta510', 'county', 'state');
  DO
  \$do\$
  BEGIN
  LOOP
    -- first try to update the key
    UPDATE tiger.loader_platform SET
      declare_sect = '
        TMPDIR="\${staging_fold}/temp/"
        UNZIPTOOL=unzip
        WGETTOOL=wget
        export PGBIN=/bin
        export PGPORT=5432
        export PGHOST=gis_postgis
        export PGUSER=\${POSTGRES_USER}
        export PGPASSWORD=\$(cat \$POSTGRES_PASSWORD_FILE)
        export PGDATABASE=\${POSTGRES_DB}
        PSQL=\${PGBIN}/psql
        SHP2PGSQL=shp2pgsql
        cd \${staging_fold}
      ',
      pgbin = '',
      wget = 'wget',
      unzip_command = '
        rm -f \${TMPDIR}/*.*
        \${PSQL} -c "DROP SCHEMA IF EXISTS \${staging_schema} CASCADE;"
        \${PSQL} -c "CREATE SCHEMA \${staging_schema};"
        for z in *.zip; do \$UNZIPTOOL -o -d \$TMPDIR \$z; done
        cd \$TMPDIR;
      ',
      psql = '\${PSQL}',
      path_sep = '/',
      loader = '\${SHP2PGSQL}',
      environ_set_command = 'export',
      county_process_command = '
        for z in *\${table_name}*.dbf; do
        \${loader} -D -s 4269 -g the_geom -W "latin1" \$z \${staging_schema}.\${state_abbrev}_\${table_name} | \${psql}
        \${PSQL} -c "SELECT loader_load_staged_data(lower(''\${state_abbrev}_\${table_name}''), lower(''\${state_abbrev}_\${lookup_name}''));"
        done
      '
    WHERE os = 'gis_loader';
    IF found THEN
      RETURN;
    END IF;
    -- not there, so try to insert the key
    -- if someone else inserts the same key concurrently,
    -- we could get a unique-key failure
    BEGIN
      INSERT INTO tiger.loader_platform(
        os, declare_sect, pgbin, wget, unzip_command, psql, path_sep, loader,
        environ_set_command, county_process_command
      )
      VALUES (
        'gis_loader',
        '
          TMPDIR="\${staging_fold}/temp/"
          UNZIPTOOL=unzip
          WGETTOOL=wget
          export PGBIN=/bin
          export PGPORT=5432
          export PGHOST=gis_postgis
          export PGUSER=\${POSTGRES_USER}
          export PGPASSWORD=\$(cat \$POSTGRES_PASSWORD_FILE)
          export PGDATABASE=\${POSTGRES_DB}
          PSQL=\${PGBIN}/psql
          SHP2PGSQL=shp2pgsql
          cd \${staging_fold}
        ',
        '',
        'wget',
        '
          rm -f \${TMPDIR}/*.*
          \${PSQL} -c "DROP SCHEMA IF EXISTS \${staging_schema} CASCADE;"
          \${PSQL} -c "CREATE SCHEMA \${staging_schema};"
          for z in *.zip; do \$UNZIPTOOL -o -d \$TMPDIR \$z; done
          cd \$TMPDIR;
        ',
        '\${PSQL}',
        '/',
        '\${SHP2PGSQL}',
        'export',
        '
          for z in *\${table_name}*.dbf; do
          \${loader} -D -s 4269 -g the_geom -W "latin1" \$z \${staging_schema}.\${state_abbrev}_\${table_name} | \${psql}
          \${PSQL} -c "SELECT loader_load_staged_data(lower(''\${state_abbrev}_\${table_name}''), lower(''\${state_abbrev}_\${lookup_name}''));"
          done
        '
      );
      RETURN;
    EXCEPTION WHEN unique_violation THEN
      -- do nothing, and loop to try the UPDATE again
    END;
  END LOOP;
  END;
  \$do\$;
EOSQL

PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" -h gis_postgis -tA -c "SELECT Loader_Generate_Nation_Script('gis_loader');" > /tmp/nation_script_load.sh

chmod +x /tmp/nation_script_load.sh

sh /tmp/nation_script_load.sh

PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" -h gis_postgis -tA -c "SELECT Loader_Generate_Nation_Script('gis_loader');" > /tmp/nation_script_load.sh

# tract, bg, tabblock can be set to false, the rest are needed for geocoding
PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" -h gis_postgis -tA <<-EOSQL
  UPDATE tiger.loader_lookuptables SET load = true
  WHERE table_name IN('tract', 'tabblock10', 'bg', 'place', 'cousub', 'faces', 'featnames', 'edges', 'addr');
EOSQL

PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" -h gis_postgis -tA -c "SELECT Loader_Generate_Script( ARRAY(SELECT DISTINCT stusps FROM tiger.state), 'gis_loader');" > /tmp/state_script_load.sh

#PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" -h gis_postgis -tA -c "SELECT Loader_Generate_Script( ARRAY['MA'], 'gis_loader');" > /tmp/state_script_load.sh

chmod +x /tmp/state_script_load.sh

sh /tmp/state_script_load.sh

PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" --dbname "$POSTGRES_DB" -h gis_postgis -tA <<-EOSQL
  SELECT install_missing_indexes();
  vacuum (analyze, verbose) tiger.addr;
  vacuum (analyze, verbose) tiger.edges;
  vacuum (analyze, verbose) tiger.faces;
  vacuum (analyze, verbose) tiger.featnames;
  vacuum (analyze, verbose) tiger.place;
  vacuum (analyze, verbose) tiger.cousub;
  vacuum (analyze, verbose) tiger.county;
  vacuum (analyze, verbose) tiger.state;
  vacuum (analyze, verbose) tiger.zip_lookup_base;
  vacuum (analyze, verbose) tiger.zip_state;
  vacuum (analyze, verbose) tiger.zip_state_loc;
EOSQL
