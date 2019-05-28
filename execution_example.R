# Sandbox for execution testing/demonstration

library(Gaia)

# Load configuration settings
load_config()

# Create tables
load_ddl(connectionDetails)




# ---- AREA ----

# DATA_SOURCE , POLYGON_FILE , AREA


# Import TIGER Shapefiles


# state
import_tiger_data(connectionDetails = connectionDetails
                  ,area_type_identifier = "22" # state - character string instead of int (1 vs. 01)
                  ,year = 2018
                  ,layer_name = NULL # Optional - defaults to file name
)

# county
import_tiger_data(connectionDetails = connectionDetails
                  ,area_type_identifier = "23" # county
                  ,year = 2018)

# tract
import_tiger_data(connectionDetails = connectionDetails
                  ,area_type_column = "area_type_name" # which column ID is from, defaults to area_type_id
                  ,area_type_identifier = "Census Tract"
                  ,year = 2018
                  ,states = c("23") # if dataset is state dependent, which to consider. if null then all
                  )


# zcta
import_tiger_data(connectionDetails = connectionDetails
                  ,area_type_column = "ACS_name" # which column ID is from, defaults to area_type_id
                  ,area_type_identifier = "ZCTA" # zip code tabulation area
                  ,year = 2018


)




# ---- AREA ATTRIBUTE ----




# View available ACS attributes
acs_vars <- get_acs_vars(connectionDetails = connectionDetails)



# Import ACS data

# state
add_acs_data(connectionDetails = connectionDetails
             ,area_type_identifier = "22"
             ,year = "2017"
             ,aggregation = "acs5"
             ,variable = "B01001_001E"
             ,by_state = FALSE

)

# tract
add_acs_data(connectionDetails = connectionDetails
             ,area_type_column = "area_type_name"
             ,area_type_identifier = "Census Tract"
             ,year = "2017"
             ,aggregation = "acs5"
             ,variable = "B25101_010E"
             ,by_state = TRUE
             ,states = "01"
)








# --------LOCATION TO AREA-------------



# Populate LTA using point-in-polygon calculation
populate_LTA_pip(connectionDetails = connectionDetails)


# Populate LTA using zip code / ZBTA match
populate_LTA_zcta_match(connectionDetails = connectionDetails)


# Populate LTA using string match on (state + county name) -> county concept
populate_lta_string_county(connectionDetails = connectionDetails)




