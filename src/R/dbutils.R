# make db connection
db_con <- function() {
    # realy only need Sys.getenv, reletive path is for development in jupyter
    pwfile <- ifelse(
        Sys.getenv('POSTGRES_PASSWORD_FILE')=='',
        '../../docker/postgis/postgres-passwd', 
        Sys.getenv('POSTGRES_PASSWORD_FILE')
    )
    pg_passwd <- pg_passwd <- readLines( pwfile, warn=FALSE )
    con <- dbConnect(RPostgres::Postgres(),
        dbname = 'postgres',
        host = 'localhost',
        port = 5433,
        user = 'postgres',
        password = pg_passwd$V1
    )
    return(con)
}

# create geom and attr table with id sequences and contraints
# TODO: geom_index, attr_index, and data_source
instantiate_geom <- function(con,geom_tablename,geom_type,attr_tablename) {
    
    # create id sequence and geom table
    instantiate_table(con,geom_tablename,paste0("geom_",geom_type))
    
    # geom table add keys and relations
    sql_altergeom <- paste0(
        "ALTER TABLE ",geom_tablename,
        " ADD CONSTRAINT ",geom_tablename,"_id_pkey PRIMARY KEY (geom_record_id), 
        ALTER COLUMN geom_record_id SET DEFAULT nextval('",geom_tablename,"_id_seq'::regclass)")
    req <- dbSendQuery(con,sql_altergeom)
    dbClearResult(req)
    
    # create id sequence and attr table
    instantiate_table(con,attr_tablename,"attr")

    #attr table add keys and relations
    sql_alterattr <- paste0(
        "ALTER TABLE ",attr_tablename,
        " ADD CONSTRAINT ",attr_tablename,"_id_pkey PRIMARY KEY (attr_record_id),
        ALTER COLUMN attr_record_id SET DEFAULT nextval('",attr_tablename,"_id_seq","'::regclass), 
        ADD CONSTRAINT ",attr_tablename,"_geo_record_id_fkey FOREIGN KEY (geom_record_id)
        REFERENCES ",geom_tablename," (geom_record_id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION"
    )
    req <- dbSendQuery(con,sql_alterattr)
    dbClearResult(req)
    
}

instantiate_table <- function(con,tablename,table_template) {
    
    # table id sequence
    sql_createidseq <- paste0(
        "CREATE SEQUENCE ",tablename,"_id_seq 
         INCREMENT 1 START 1 
         MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1"
    )
    req <- dbSendQuery(con,sql_createidseq)
    dbClearResult(req)

    # table as clone
    sql_createtable <- paste0(
        "CREATE TABLE ",tablename," AS 
         SELECT * FROM ",table_template," WITH NO DATA")
    req <- dbSendQuery(con,sql_createtable)
    dbClearResult(req)
    
}