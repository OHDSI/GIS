# TODO The purpose of this function is to execute a spatial join between a
## staged place-related variable, a staged geometry, and then to a point-address
## for a patient. 

loadExposure <- function(gaiaConnectionDetails, cdmConnectionDetails, cdmDatabaseSchema, variableSourceId) {

# Check that exposure_occurrence exists in CDM ----------------------------

  
  if (!checkTableExists(connectionDetails = cdmConnectionDetails,
                       databaseSchema = cdmDatabaseSchema,
                       tableName = "exposure_occurrence")) {
    message(paste0("Creating exposure_occurrence table in ", cdmConnectionDetails$server(), ".", cdmDatabaseSchema, "..."))
    
    message ("TODO: Create function to execute exposure_occurrence DDL with connectionDetails; https://github.com/OHDSI/GIS/issues/240")
    message("TOOD: For now, you will have to manually create exposure_occurrence using the scripts in inst/ddl/001/gaiaResults_*")
    stop("Table not found")
  }

# Check that specified variable (and geom) are both loaded to staging ---------------

  geomFullTableName <- getGeomNameFromVariableSourceId(connectionDetails = gaiaConnectionDetails,
                                                       variableSourceId = variableSourceId)
  attrFullTableName <- getAttrNameFromVariableSourceId(connectionDetails = gaiaConnectionDetails,
                                                   variableSourceId = variableSourceId)
  
  attrSchema <- strsplit(attrFullTableName, split="\\.")[[1]][[1]]
  attrTableName <- strsplit(attrFullTableName, split="\\.")[[1]][[2]]
  
  # TODO the following is a deconstruction of checkVariableExists.
  # Refactor checkVariableExists to handle this case and not break the existing use case
  
  
  if (!checkTableExists(connectionDetails = gaiaConnectionDetails,
                        databaseSchema = attrSchema,
                        tableName = attrTableName)) {
    message("# TODO: this should call loadVariable because the desired variable doesn't exist")
    # TODO: this should call loadVariable because the desired variable doesn't exist (by virtue of the entire attr table not existing)
    # NOTE: we shouldn't need to check for a geometry.. if a variable has been loaded it is assumed a geometry was loaded at the same time.
  }
  
  variableExistsQuery <- paste0("select count(*) from ", attrFullTableName,
                                " where variable_source_record_id = '", variableSourceId,"'")
  conn <-  DatabaseConnector::connect(gaiaConnectionDetails)
  variableExistsResult <- DatabaseConnector::querySql(conn, variableExistsQuery)
  DatabaseConnector::disconnect(conn)
  if (!variableExistsResult > 0){
    message("# TODO: this should call loadVariable because the desired variable doesn't exist")
    # TODO: this should call loadVariable because the desired variable doesn't exist
    # NOTE: we shouldn't need to check for a geometry.. if a variable has been loaded it is assumed a geometry was loaded at the same time.
  }
  

# Check that there is a geocoded address table ----------------------------

  if (!checkTableExists(connectionDetails = gaiaConnectionDetails,
                        databaseSchema = "omop",
                        tableName = "geom_omop_location")) {
    message(paste0("No geocoded address table detected in ", gaiaConnectionDetails$server(), ".", cdmDatabaseSchema, ".", tableName))
    message("Please ensure that you have a geocoded address table named \"geom_omop_location\" in a schema named \"omop\" within your gaiaDB instance")
    message("Full geocoding walkthrough at: https://ohdsi.github.io/GIS/geocodingFull.html")
  }
  
  

# Join all variable to geom, join all to geocoded addresses (create exp_occ in mem) --------------------------------------------

  # TODO this could be a function in dbUtils
  
  conn <-  DatabaseConnector::connect(gaiaConnectionDetails)
  
  #TODO add temporal join condition:
  # <<<
  # join omop.geom_omop_location gol 
  # on public.st_within(gol.geometry, geo.geom_wgs84)"
  # and (gol.valid_start_date < att.attr_end_date
  #      or gol.valid_end_date >att.attr_start_date)
  # >>>
  
  # TODO better exposure_*_date logic:
  # After temporal join condition is added
  # <<<
  # CASE WHEN att.attr_start_date >= gol.valid_start_date THEN att.attr_start_date
  #      ELSE gol.valid_start_date END AS exposure_start_date
  # CASE WHEN att.attr_end_date <= gol.valid_end_date THEN att.attr_end_date
  #      ELSE gol.valid_end_date END AS exposure_end_date
  # >>>
  
  # TODO how to get exposure_type_concept_id
  

  
  
  
  exposureOccurrence <- DatabaseConnector::dbGetQuery(conn, paste0(
    "select gol.location_id
      , gol.person_id AS person_id
      , CAST(NULL AS INTEGER) AS cohort_definition_id
      , CASE WHEN att.attr_concept_id IS NOT NULL THEN att.attr_concept_id ELSE 0 END AS exposure_concept_id
      , att.attr_start_date AS exposure_start_date
      , att.attr_start_date AS exposure_start_datetime
      , att.attr_end_date AS exposure_end_date
      , att.attr_end_date AS exposure_end_datetime
      , 0 AS exposure_type_concept_id
      , 0 AS exposure_relationship_concept_id
      , att.attr_source_concept_id AS exposure_source_concept_id
      , att.attr_source_value AS exposure_source_value
      , CAST(NULL AS VARCHAR(50)) AS exposure_relationship_source_value
      , CAST(NULL AS VARCHAR(50)) AS dose_unit_source_value
      , CAST(NULL AS INTEGER) AS quantity
      , CAST(NULL AS VARCHAR(50)) AS modifier_source_value
      , CAST(NULL AS INTEGER) AS operator_concept_id
      , att.value_as_number AS value_as_number
      , att.value_as_concept_id AS value_as_concept_id
      , att.unit_concept_id AS unit_concept_id
    from ", getAttrNameFromVariableSourceId(gaiaConnectionDetails, variableSourceId)," att
    inner join ", getGeomNameFromVariableSourceId(gaiaConnectionDetails, variableSourceId)," geo
    on att.geom_record_id = geo.geom_record_id 
    and att.variable_source_record_id = ", variableSourceId, "
    join omop.geom_omop_location gol 
    on public.st_within(gol.geometry, geo.geom_wgs84)"
  ))  
  
  DatabaseConnector::disconnect(conn)
  
  

# Create exposure_occurrence_id column ------------------------------------

  conn <-  DatabaseConnector::connect(cdmConnectionDetails)
  
  # get max existing exposure_occurrence_id and append the exposure_occurrence_id
  maxExposureOccurrenceId <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT max(exposure_occurrence_id) FROM ", cdmDatabaseSchema,".exposure_occurrence;"))[[1]]
  
  if (is.na(maxExposureOccurrenceId)) {
    exposureOccurrence <- cbind(exposure_occurrence_id = seq(1, nrow(exposureOccurrence)), exposureOccurrence)
  } else {
    exposureOccurrence <- cbind(exposure_occurrence_id = seq(maxExposureOccurrenceId + 1, maxExposureOccurrenceId + nrow(exposureOccurrence)), exposureOccurrence)
  }
  
  DatabaseConnector::disconnect(conn)
  
  
# Insert into CDM table ---------------------------------------------------

  conn <-  DatabaseConnector::connect(cdmConnectionDetails)
  
  
  DatabaseConnector::insertTable(connection = conn,
                                 databaseSchema = cdmDatabaseSchema,
                                 tableName = "exposure_occurrence",
                                 data = exposureOccurrence,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE)
    
  DatabaseConnector::disconnect(conn)
  
  
  
  
}