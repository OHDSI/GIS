# OHDSI GIS 1.0 [under development]

## Introduction


This package is meant to serve as a testing environment for further development towards integrating GIS functionality into the OHDSI stack. This initial vertical slice is focused on a subset of the overall goals of the GIS WG but aims to lay the foundation. It is likely that the structures and functions within will be modified if not replaced in later versions. Documentation for the GIS data model extension can be found on [the Wiki](https://github.com/OHDSI/GIS/wiki/OHDSI-GIS-Version-1.0). 

### Use case

Integration of American Community Survey (ACS) data with OMOP CDM. 

### Features
1. Loads configuration settings from YML file, establishing database connection information, storage directories, and coordinate reference system preferences
2. Loads DDL for GIS specific tables (thus far only tested on SQL Server)
3. Provides GEO_CONCEPT table which contains a subset of GIS specific concepts and serves as a development placeholder for the CONCEPT table (TODO: function to load this into DB automatically) 
4. Retrieves and ingests polygons (areas) from TIGER/Line shapefile data 
5. Retrieves and ingests region statistics (area attributes) from the American Community Survey API 
6. Calculates the relationships between LOCATION and AREA and persists the result (LOCATION_TO_AREA). There are three functions to choose from:
    - Point-in-polygon (requires geocoded locations)
    - Identifier match (zip code -> zcta)
    - String match (state + county name -> geoid)

### Assumptions
- Temporal relationships between PERSON and LOCATION already established within LOCATION_HISTORY table
- To enable point-in-polygon calculations, it is assumed that the LOCATION table has been geocoded and relevant columns populated (DDL included):
    - latitude
    - longitude
    - epsg (not currently part of CDM)


### Getting started

1.  Configuration 

	Create **config.yml**. A template can be found in *conf/config_example.yml*

	```yaml
	default:
	  connection_details:
	    dbms: "sql server"
	    server: "localhost"
	    user: "user"
	    password: "pass"
	  cdm_schema: "CDM.dbo"
	  vocab_schema: "CDM.dbo"
	  gis_schema: "GIS.dbo"           #  schema where GIS data persists
	  polygon_file_dir: "C:/gis_repo"	# local gis file repo
	  temp_dir: "C:/gis_temp"         # temporary storage path
	  default_epsg: "4326"            # default desired epsg
	  convert_epsg: TRUE              # convert all to default?
	```
	
    Load configuration file into memory
    
    
   	 ```r
	load_config()  # If the config_path parameter is not specified the assumed path is conf/config.yml
	```
  	
     If needed, *unload_config()* removes the configuration settings from memory
  
  2. DDL
  
    	Create the database structures in the 'gis_schema' specified by the configuration. Thus far only SQL Server has been tested. If the tables already exists then no action is taken. 
  
	    ```r
	    load_ddl(connectionDetails)
	    ```
	
  3. Load GIS concepts
  
        As a placeholder during development we've stored new GIS related concepts in their own table, GEO_CONCEPT. The contents of the table are found in ***data-raw/geo_concept.zip*** and need to be manually imported. *TODO: import function*
  
  
  
  4. Determine area type
  
        The index table **area_type_index** is a placeholder structure that has one row per region type (county, tract, etc.) and maintains alias and API data for each. 
  	
		```r
		# To browse 
		View(area_type_index) 
		```
  	
        Functions for loading both AREA and AREA_ATTRIBUTE data require an area type specification. To specify an area type, you can reference any identifier ('area_type_identifier' parameter) within any column ('area_type_column' parameter). If 'area_type_column' is NULL it defaults to the identity *area_type_id* . Although this function is not intended to be called directly, it helps illustrate:
  	
  	

  
  
	    ```r
	    # Census Tract
	    get_area_type(area_type_identifier = "Census Tract", area_type_column = "area_type_name")
	    # Census Tract
	    get_area_type(area_type_identifier = "G5020", area_type_column = "mtfcc_id")
	    # Census Tract
	    get_area_type(area_type_identifier = "32")
	    ```
    
 

  5. Import AREA data
  
        The following function retrieves shapefiles from TIGER/Line Census data and ingests them into the AREA table. The polygons persist on disk (within *polygon_file_dir*) and have references maintained in relational tables for reuse. 
     This function inserts into three tables:
    - AREA - References and identifiers for individual polygons
    - DATA_SOURCE - Single entry for data collection. For TIGER, unique record for each year
    - POLYGON_FILE - Unique record for each data source file. If aggregated by state can be multiple for same area type
    
  
	    ```r
	    # Import STATE data
	    import_tiger_data(connectionDetails         
			      ,area_type_identifier ="22" # uniquely identifies area type
			      ,area_type_column = NULL    # if using alternative to area_type_id, specify column
			      ,year = NULL                # if NULL then '2018'              
			      ,layer_name = NULL          # optional customization 
			      ,states = NULL)             # if data is aggregated by state, list desired states 


	    # Import TRACT data for Maine only
	    import_tiger_data(connectionDetails = connectionDetails
			  ,area_type_column = "area_type_name" 
			  ,area_type_identifier = "Census Tract"
			  ,year = 2018
			  ,states = c("23") )            # lits of fips codes. If state dependent and NULL then all
	    ```
    
   
    
  6. Import AREA_ATTRIBUTE data
    
        The following function retrieves data from the American Community Survey API. Populating the AREA table is a prerequisite as the attributes are (inner) joined with the areas before ingestion. Given the size of the data and the likelihood of particular interest in certain variables, the function takes a specific ACS variable as input. 
    
    
	    ```r
	    # View available ACS attributes
	    acs_vars <- get_acs_vars(connectionDetails = connectionDetails)
	    View(acs_vars)

	    # Import attribute "B01001_001E" for all states 
	    add_acs_data(connectionDetails = connectionDetails
			 ,area_type_identifier = "22"
			 ,year = "2017"
			 ,aggregation = "acs5"
			 ,variable = "B01001_001E"
			 ,by_state = FALSE)

	    # Import attribute "B25101_010E" for all tracts in Maine
	    add_acs_data(connectionDetails = connectionDetails
			 ,area_type_column = "area_type_name"
			 ,area_type_identifier = "Census Tract"
			 ,year = "2017"
			 ,aggregation = "acs5"
			 ,variable = "B25101_010E"
			 ,by_state = TRUE
			 ,states = "23" )
	    ```
    
  7. Populate LOCATION_TO_AREA table
  
        If the data is geocoded the best option is to use point-in-polygon calculations. This will compare every location to every polygon so it is best not to have your AREA table overloaded with areas you are not interested in. 
  
	    ```r
	    # Populate LTA using point-in-polygon calculation
	    populate_LTA_pip(connectionDetails = connectionDetails)
	    ```

        There are two alternative options. The first pulls zip code from the location table and tries to match it to a zip code tabulation area identifier. The second attempts to string match on state and county names. The matching function that was performed is stored in the *LOCATION_TO_AREA.relationship_id*. 
    
	    ```r
	    # Populate LTA using zip code / ZBTA match
	    populate_LTA_zcta_match(connectionDetails = connectionDetails)

	    # Populate LTA using string match on (state + county name) -> county concept
	    populate_lta_string_county(connectionDetails = connectionDetails)
	    ```
    
