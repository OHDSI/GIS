require(DatabaseConnector)
require(readr)

omop <- connect(dbms=Sys.getenv("OMOP_DBMS"),
                connectionString=Sys.getenv("OMOP_JDBC_CONNECTION_STRING"))

loc <- querySql(omop,"SELECT * FROM location")

disconnect(omop)

postgis <- connect(dbms="postgresql",
                   server=paste0("gis_postgis/", Sys.getenv("POSTGRES_DB")),
		   user=Sys.getenv("POSTGRES_USER"),
		   password=read_lines(Sys.getenv("POSTGRES_PASSWORD_FILE")))

executeSql(postgis,"TRUNCATE TABLE location")

insertTable(connection = postgis,
	    tableName = "location",
	    data = loc,
	    dropTableIfExists = FALSE,
	    createTable = FALSE,
	    tempTable = FALSE,
	    useMppBulkLoad = FALSE)

disconnect(postgis)
