psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  UPDATE tiger.loader_lookuptables SET load = true WHERE lookup_name IN('tract', 'bg', 'tabblock', 'zcta510');
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tA -c "SELECT Loader_Generate_Nation_Script('sh')" > /tmp/gisdata/nation_script_load.sh

chmod +x /tmp/gisdata/nation_script_load.sh

sh /tmp/gisdata/nation_script_load.sh

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tA -c "SELECT Loader_Generate_Script( ARRAY(SELECT DISTINCT stusps FROM tiger.state), 'sh');" > /tmp/gisdata/state_script_load.sh

chmod +x /tmp/gisdata/state_script_load.sh

sh /tmp/gisdata/state_script_load.sh

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
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
