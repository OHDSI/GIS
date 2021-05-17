require(DBI)
require(RPostgreSQL)

# make db connection
# TODO: verify that we want to use the default 'postgres' maintenance database
db_con <- function() {
    con <- dbConnect(
        RPostgreSQL::PostgreSQL(),
        dbname = Sys.getenv("POSTGRES_DB"),
        host = Sys.getenv("POSTGRES_HOST"),
        port = Sys.getenv("POSTGRES_PORT"),
        user = Sys.getenv("POSTGRES_USER"),
        password = readLines(Sys.getenv("POSTGRES_PASSWORD_FILE"), warn=FALSE)
    )
    return(con)
}

# create geom table with id sequences and constraints
# TODO: data_source
instantiate_geom <- function(con,geom_meta) {
    
    # instantiate geom table
    instantiate_table(
        con,
        geom_meta$table_name,
        "geom",
        geom_meta$data_type_name,
        geom_meta$epsg_local
    )

    geom_index_id <- update_index(con,"geom",geom_meta)
    return (geom_index_id)

}

# create attr table with id sequences and constraints
# TODO: data_source
instantiate_attr <- function(con,attr_meta,geom_tablename) {
    
    # create id sequence and attr table
    instantiate_table(con,attr_meta$table_name,"attr")

    # attr table add keys and relations
    sql_alterattr <- paste0(
        "ALTER TABLE ",attr_meta$table_name,
        " ADD CONSTRAINT ",attr_meta$table_name,"_geom_record_id_fkey FOREIGN KEY (geom_record_id)
        REFERENCES ",geom_tablename," (geom_record_id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION"
    )

    # add column for foreign key to metadata table
    # TODO: populate this column and link to foreign table
    if ( "attr_meta_id" %in% names(attr_meta) ) {
      sql_alterattr <- paste0(sql_alterattr,
        ", ADD COLUMN attr_meta_id VARCHAR")
    }

    res <- dbSendQuery(con,sql_alterattr)
    dbClearResult(res)

    attr_index_id <- update_index(con,"attr",attr_meta)
    
}

# instantiate generic table
instantiate_table <- function(con,tablename,table_template,geom_type='',local_epsg=0) {

    # create table as clone with no data
    sql_createtable <- paste0(
        "CREATE TABLE ",tablename," ()
         INHERITS (",table_template,")")
    res <- dbSendQuery(con,sql_createtable)
    dbClearResult(res)

    # set pkey constraint
    sql_altertable <- paste0(
        "ALTER TABLE ",tablename,
        " ADD CONSTRAINT ",tablename,"_id_pkey PRIMARY KEY (",table_template,"_record_id)"
    )

    # add geom constraints
    if ( geom_type != '' ) 
        sql_altertable <- paste0(sql_altertable,
      ", ADD CONSTRAINT enforce_geotype_geom_wgs84 CHECK
        (geometrytype(geom_wgs84) = '",geom_type,"'::text)
       , ADD CONSTRAINT enforce_geotype_geom_local CHECK
        (geometrytype(geom_local) = '",geom_type,"'::text)")

    if ( local_epsg != 0 ) 
        sql_altertable <- paste0(sql_altertable,
      ", ADD CONSTRAINT enforce_srid_geom_local CHECK
        (st_srid(geom_local) = ",local_epsg,")")
        
    res <- dbSendQuery(con,sql_altertable)
    dbClearResult(res)
    
}

# create row in index table (geom or attr, based on index_type)
update_index <- function(con,index_type,meta) {

  if ('attr_meta_id' %in% names(meta)) meta <- within(meta, rm(attr_meta_id)) 

  column_list <- paste0("(",paste0(names(meta),collapse=","),")")
  value_list <- paste0("(",paste0("$",1:length(meta),collapse=","),")")
  values <- unlist(meta,use.names=F)

  sql_insert_index <- paste0(
      "INSERT INTO ",index_type,"_index ",
      column_list,
      " VALUES ",value_list,
      " RETURNING ",index_type,"_index_id")

  res <- dbSendQuery(con,sql_insert_index,values)
  index_id <- dbFetch(res)[[paste0(index_type,"_index_id")]]
  dbClearResult(res)

  return (index_id)

}
