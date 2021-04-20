mkdir -p /tmp

DATAFILES=$(echo *.zip | sed 's/\.zip//g')
for datafile in $DATAFILES
do
	unzip ${datafile}.zip -d /tmp/${datafile}
	EPSG=$(gdalsrsinfo -V -e -o epsg /tmp/${datafile} | sed -n 's/.*EPSG:\(.*\)/\1/p')
	SHAPEFILES=$(echo /tmp/${datafile}/*.shp | sed 's/\.shp//g')
	for shapefile in $SHAPEFILES
	do
		shp2pgsql -s $EPSG -I ${shapefile}.shp > ${shapefile}.sql
		PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE) psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -h gis_postgis -tA -f ${shapefile}.sql
	done
	rm -rf /tmp/${datafile}
done
