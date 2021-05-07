require(DBI)
require(RPostgreSQL)

# make db connection
# TODO: verify that we want to use the default 'postgres' maintenance database
db_con <- function() {
    con <- dbConnect(RPostgreSQL::PostgreSQL(),
        dbname = Sys.getenv("POSTGRES_DB"),
        host = Sys.getenv("POSTGRES_HOST"),
        port = Sys.getenv("POSTGRES_PORT"),
        user = Sys.getenv("POSTGRES_USER"),
        password = readLines(Sys.getenv("POSTGRES_PASSWORD_FILE"), warn=FALSE)
    )
    return(con)
}

# create geom table with id sequences and constraints
# TODO: geom_index and data_source
instantiate_geom <- function(con,geom_tablename,geom_type,local_epsg=NULL) {
    
    # create id sequence and geom table
    instantiate_table(con,geom_tablename,"geom",geom_type,local_epsg)

}

# create attr table with id sequences and constraints
# TODO: geom_index and data_source
instantiate_attr <- function(con,attr_tablename,geom_tablename) {
    
    # create id sequence and attr table
    instantiate_table(con,attr_tablename,"attr")

    #attr table add keys and relations
    sql_alterattr <- paste0(
        "ALTER TABLE ",attr_tablename,
        " ADD CONSTRAINT ",attr_tablename,"_geo_record_id_fkey FOREIGN KEY (geom_record_id)
        REFERENCES ",geom_tablename," (geom_record_id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION"
    )
    req <- dbSendQuery(con,sql_alterattr)
    dbClearResult(req)
    
}

# instantiate generic table
instantiate_table <- function(con,tablename,table_template,geom_type=NULL,local_epsg=NULL) {

    # create table as clone with no data
    sql_createtable <- paste0(
        "CREATE TABLE ",tablename," ()
         INHERITS (",table_template,")")
    req <- dbSendQuery(con,sql_createtable)
    dbClearResult(req)

    # set pkey constraint
    sql_altertable <- paste0(
        "ALTER TABLE ",tablename,
        " ADD CONSTRAINT ",tablename,"_id_pkey PRIMARY KEY (",table_template,"_record_id)"
    )

    # add geom constraints
    if (!is.null(geom_type)) 
        sql_altertable <- paste0(sql_altertable,
	    ", ADD CONSTRAINT enforce_geotype_geom_wgs84 CHECK
	      (geometrytype(geom_wgs84) = '",geom_type,"'::text)
	     , ADD CONSTRAINT enforce_geotype_geom_local CHECK
	      (geometrytype(geom_local) = '",geom_type,"'::text)")

    if (!is.null(local_epsg)) 
        sql_altertable <- paste0(sql_altertable,
	    ", ADD CONSTRAINT enforce_srid_geom_local CHECK
	      (st_srid(geom_local) = ",local_epsg,")")
        
    req <- dbSendQuery(con,sql_altertable)
    dbClearResult(req)
    
}
