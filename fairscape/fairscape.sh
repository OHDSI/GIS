# Fairscape for Gaia

## STEP 1: BOILERPLATE
# These steps are performed for every end-to-end creation of gaiaOHDSI data products
# The ROCrate is created, the gaiaDB tables, gaiaCOre, and gaiaOHDSI are added to the ROCrate
# (The physical objects/contents that are added to the ROCrate will changed as software changes version)

echo "Installing Fairscape CLI..."
pip install fairscape-cli
echo "Done!"

echo "Initializing a new RO Crate..."
fairscape-cli rocrate init \
--name "gaia_rocrate" \
--description "Gaia RO Crate" \
--organization-name "OHDSI GIS Workgroup" \
--keywords "GIS" \
--keywords "gaia" \
--keywords "ohdsi" \
--project-name "OHDSI GIS Gaia" 
echo "Done!"

echo "Registering gaiaCore as a software application..."
fairscape-cli rocrate add software \
--name "gaiaCore" \
--author "OHDSI GIS Workgroup" \
--version "0.1.0" \
--description "An R Package for gaiaDB relatd operations" \
--keywords "GIS" \
--keywords "gaia" \
--file-format "zip" \
--url "https://github.com/OHDSI/gaiaCore/archive/refs/tags/v0.1.0.zip" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/gaiaCore-0.1.0.zip" \
--destination-filepath "./gaia_rocrate/gaiaCore.zip" \
--date-modified "2024-11-15" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering gaiaDB's data_source as a dataset..."
# This should source version from gaiaDB repository
# Perhaps both registering data_source, variable_source, and all of the tabular metadata can be a helper function in either gaiaCore or gaiaDB
fairscape-cli rocrate add dataset \
--name "data_source" \
--author "OHDSI GIS Workgroup" \
--version "0.1.0" \
--date-published "2024-11-15" \
--description "Data Source" \
--keywords "GIS" \
--keywords "gaia" \
--data-format "csv" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/data_source.csv" \
--destination-filepath "./gaia_rocrate/data_source.csv" \
--additional-documentation "https://ohdsi.github.io/GIS/" \
"./gaia_rocrate" # (ROCRATE PATH)

echo "  Creating tabular schema..."
fairscape-cli schema create-tabular \
--name "data_source schema" \
--description "Tabular format for the gaiaDB data_source table" \
--separator "," \
--header True \
"./gaia_rocrate/schema_data_source.json" # (SCHEMA PATH)

echo "  Populating tabular schema..."
## HOW TO generate these commands from the CSV file SSoT?
fairscape-cli schema add-property integer \
--name "data_source_uuid" \
--index 0 \
--description "Unique identifier for the data source" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "org_id" \
--index 1 \
--description "Organization identifier" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property integer \
--name "org_set_id" \
--index 2 \
--description "Organization Set ID" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "dataset_name" \
--index 3 \
--description "Name of the dataset" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "dataset_version" \
--index 4 \
--description "Version of the dataset" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "geom_type" \
--index 5 \
--description "Type of the geometry" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "geom_spec" \
--index 6 \
--description "JSON-encoded transformation logic for the source dataset to the harmonized geom_X data format" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "boundary_type" \
--index 7 \
--description "Type of boundary" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property boolean \
--name "has_attributes" \
--index 8 \
--description "0 or 1 representation of whether the dataset contains attribute data" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "download_method" \
--index 9 \
--description "Whether the dataset is downloaded from the internet (file) or accessed on disk (local)" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "download_subtype" \
--index 10 \
--description "Compressed format of the download (e.g. zip, tar.gz)" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "download_data_standard" \
--index 11 \
--description "File format of the uncompressed dataset (e.g. csv, shp)" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "download_filename" \
--index 12 \
--description "Filename of the uncompressed dataset (e.g. SVI2012.csv)" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "download_url" \
--index 13 \
--description "The URL where the dataset is available for download, or if local, the name of the compressed file" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "download_auth" \
--index 14 \
--description "Authentication details" \
./gaia_rocrate/schema_data_source.json

fairscape-cli schema add-property string \
--name "documentation_url" \
--index 15 \
--description "The URL where documentation for the dataset can be found" \
./gaia_rocrate/schema_data_source.json

echo "Done!"

echo "Registering gaiaDB's variable_source as a dataset..."
# This should source version from gaiaDB repository
fairscape-cli rocrate add dataset \
--name "variable_source" \
--author "OHDSI GIS Workgroup" \
--version "0.1.0" \
--date-published "2024-11-15" \
--description "Variable Source" \
--keywords "GIS" \
--keywords "gaia" \
--data-format "csv" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/variable_source.csv" \
--destination-filepath "./gaia_rocrate/variable_source.csv" \
--additional-documentation "https://ohdsi.github.io/GIS/" \
"./gaia_rocrate" # (ROCRATE PATH)

echo "  Creating tabular schema..."
fairscape-cli schema create-tabular \
--name "variable_source schema" \
--description "Tabular format for the gaiaDB variable_source table" \
--separator "," \
--header True \
"./gaia_rocrate/schema_variable_source.json" # (SCHEMA PATH)

echo "  Populating tabular schema..."
## HOW TO generate these commands from the CSV file SSoT?
fairscape-cli schema add-property integer \
--name "variable_source_id" \
--index 0 \
--description "Unique identifier for the variable source" \
./gaia_rocrate/schema_variable_source.json

fairscape-cli schema add-property integer \
--name "geom_dependency_uuid" \
--index 1 \
--description "Foreign key link to the geom_X on which this variable depends" \
./gaia_rocrate/schema_variable_source.json

fairscape-cli schema add-property string \
--name "variable_name" \
--index 2 \
--description "Name of the variable" \
./gaia_rocrate/schema_variable_source.json

fairscape-cli schema add-property string \
--name "variable_desc" \
--index 3 \
--description "Description of the variable" \
./gaia_rocrate/schema_variable_source.json

fairscape-cli schema add-property integer \
--name "data_source_uuid" \
--index 4 \
--description "Unique identifier of the data_source record from where the variable is sourced" \
./gaia_rocrate/schema_variable_source.json

fairscape-cli schema add-property string \
--name "attr_spec" \
--index 5 \
--description "JSON-encoded transformation logic for the source dataset to the harmonized attr_X data format" \
./gaia_rocrate/schema_variable_source.json

echo "Done!"

echo "Registering gaiaOHDSI as a software application..."
fairscape-cli rocrate add software \
--name "gaiaOHDSI" \
--author "OHDSI GIS Workgroup" \
--version "0.1.0" \
--description "Gaia OHDSI: facilitating spatiotemporal joins between harmonized geospatial data and patient-level OMOP data" \
--keywords "GIS" \
--keywords "gaia" \
--keywords "ohdsi" \
--file-format "zip" \
--url "https://github.com/OHDSI/gaiaOHDSI/archive/refs/tags/v0.1.0.zip" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/gaiaOHDSI-0.1.0.zip" \
--destination-filepath "./gaia_rocrate/gaiaOHDSI.zip" \
--date-modified "2024-11-15" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"


## STEP 2: HARMONIZATION
# These steps vary depending on the desired source data to be transformed
# The verbatim source data, the harmonized geom_X and attr_X data, and the relevant computations are added to the ROCrate

echo "Adding the NASA SEDAC PM2.5 dataset to the RO Crate..."
# An outstanding question is - do we need to "add" and "register"
# the data object? Or is one or the other sufficient?
fairscape-cli rocrate add dataset \
--name "NASA SEDAC PM2.5" \
--author "NASA SEDAC group" \
--version "1" \
--date-published "2021-04-05" \
--description "The Annual PM2.5 Concentrations for Countries and Urban Areas, 1998-2016, consists of mean concentrations of particulate matter (PM2.5) for countries and urban areas. The PM2.5 data are from the Global Annual PM2.5 Grids from MODIS, MISR and SeaWiFS Aerosol Optical Depth (AOD) with GWR, 1998-2016. The urban areas are from the Global Rural-Urban Mapping Project, Version 1 (GRUMPv1): Urban Extent Polygons, Revision 02, and its time series runs from 1998 to 2016. The country averages are population-weighted such that concentrations in populated areas count more toward the country average than concentrations in less populated areas, and its time series runs from 2008 to 2015." \
--keywords "air" \
--keywords "air quality" \
--data-format "zip" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/sdei-annual-pm2-5-concentrations-countries-urban-areas-v1-1998-2016-urban-areas-shp.zip" \
--destination-filepath "./gaia_rocrate/sdei-annual-pm2-5-concentrations-countries-urban-areas-v1-1998-2016-urban-areas-shp.zip" \
--additional-documentation "https://sedac.ciesin.columbia.edu/downloads/docs/sdei/sdei-annual-pm2-5-concentrations-countries-urban-areas-v1-1998-2016-documentation.pdf" \
"./gaia_rocrate" # (ROCRATE PATH)
# --url TEXT \
# --used-by TEXT \
# --derived-from TEXT \
# --schema TEXT \
# --associated-publication TEXT \
echo "Done!"

echo "Registering the derived geom_nasa_sedac dataset..."
# Next, the source dataset is transformed internally into a "harmonized" data format
fairscape-cli rocrate add dataset \
--name "geom_nasa_sedac" \
--author "gaiaCore" \
--version "1" \
--date-published "2025-01-29" \
--description "A geometry dataset derived from NASA SEDAC group's NASA SEDAC PM2.5 dataset " \
--keywords "Gaia" \
--keywords "air" \
--keywords "air quality" \
--data-format "csv" \
--derived-from "NASA SEDAC PM2.5" \
--derived-from "gaiaCore::loadVariable" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/nasa_sedac.csv" \
--destination-filepath "./gaia_rocrate/nasa_sedac.csv" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the derived attr_nasa_sedac dataset..."
fairscape-cli rocrate add dataset \
--name "attr_nasa_sedac" \
--author "gaiaCore" \
--version "1" \
--date-published "2025-01-29" \
--description "An attribute dataset derived from NASA SEDAC group's NASA SEDAC PM2.5 dataset that can be linked to geom_nasa_sedac" \
--keywords "Gaia" \
--keywords "air" \
--keywords "air quality" \
--data-format "csv" \
--derived-from "NASA SEDAC PM2.5" \
--derived-from "gaiaCore::loadVariable" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/nasa_sedac.csv" \
--destination-filepath "./gaia_rocrate/nasa_sedac.csv" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the loadGeometry computation..."
fairscape-cli rocrate register computation \
--name "loadGeometry" \
--run-by "gaiaCore User" \
--command "gaiaCore::loadGeometry(connectionDetails, 51500)" \
--date-created "2025-01-29" \
--description "A gaiaCore function that leverages gaiaDB data_source tables to generate a harmonized-format version of some source geospatial data" \
--keywords "Gaia" \
--used-software "gaiaCore" \
--used-dataset "NASA SEDAC PM2.5" \
--used-dataset "data_source" \
--generated "geom_nasa_sedac" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the loadVariable computation..."
fairscape-cli rocrate register computation \
--name "loadVariable" \
--run-by "gaiaCore User" \
--command "gaiaCore::loadVariable(connectionDetails, 51500)" \
--date-created "2025-01-29" \
--description "A gaiaCore function that leverages gaiaDB data_source and variable_source tables to generate a harmonized-format version of some source geospatial data" \
--keywords "Gaia" \
--used-software "gaiaCore" \
--used-dataset "NASA SEDAC PM2.5" \
--used-dataset "data_source" \
--used-dataset "variable_source" \
--generated "attr_nasa_sedac" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

## STEP 3: TRANSFORMATION

echo "Registering the cohort_location_history dataset..."
# derived-from is tricky here...
fairscape-cli rocrate add dataset \
--name "cohort_location_history" \
--author "OMOP CDM Maintainer" \
--version "1" \
--date-published "2025-01-29" \
--description "A slice of an OMOP CDM LOCATION_HISTORY table, fit to the address history for a patient cohort of interest" \
--keywords "Gaia" \
--keywords "OMOP" \
--keywords "location history" \
--data-format "csv" \
--derived-from "LOCATION_HISTORY" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/cohort_location_history.csv" \
--destination-filepath "./gaia_rocrate/cohort_location_history.csv" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the create_external_exposure computation..."
fairscape-cli rocrate register computation \
--name "create_external_exposure" \
--run-by "gaiaOHDSI User" \
--command "gaiaOHDSI::create_external_exposure(connectionDetails, 51500)" \
--date-created "2025-01-29" \
--description "A gaiaOHDSI function that generates the OHDSI GIS extension table EXTERNAL_EXPOSURE" \
--keywords "Gaia" \
--keywords "OMOP" \
--used-software "gaiaOHDSI" \
--used-dataset "geom_nasa_sedac" \
--used-dataset "attr_nasa_sedac" \
--used-dataset "cohort_location_history" \
--used-dataset "omop_gis_vocabulary" \
--generated "EXTERNAL_EXPOSURE" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the create_delta_vocabulary computation..."
fairscape-cli rocrate register computation \
--name "create_delta_vocabulary" \
--run-by "gaiaOHDSI User" \
--command "gaiaOHDSI::create_delta_vocabulary("external_exposure")" \
--date-created "2025-01-29" \
--description "A gaiaOHDSI function that generates a set of OMOP Vocabulary tables containing custom concepts" \
--keywords "Gaia" \
--keywords "OMOP" \
--used-software "gaiaOHDSI" \
--used-dataset "EXTERNAL_EXPOSURE" \
--used-dataset "omop_gis_vocabulary" \
--generated "EXTERNAL_EXPOSURE" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the omop_gis_vocabulary dataset..."
fairscape-cli rocrate add dataset \
--name "omop_gis_vocabulary" \
--author "OHDSI GIS Workgroup" \
--version "1" \
--date-published "2025-01-29" \
--description "The OHDSI GIS authored OMOP GIS Vocabulary tables" \
--keywords "Gaia" \
--keywords "OMOP" \
--keywords "vocabulary" \
--data-format "csv" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/gis_omop_vocabulary.csv" \
--destination-filepath "./gaia_rocrate/gis_omop_vocabulary.csv" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the external_exposure dataset..."
fairscape-cli rocrate add dataset \
--name "EXTERNAL_EXPOSURE" \
--author "gaiaOHDSI User" \
--version "1" \
--date-published "2025-01-29" \
--description "The OHDSI GIS Extension table representing the patient cohort's relationship to the NASA SEDAC PM2.5 dataset" \
--keywords "Gaia" \
--keywords "OMOP" \
--keywords "external exposure" \
--data-format "csv" \
--derived-from "cohort_location_history" \
--derived-from "omop_gis_vocabulary" \
--derived-from "geom_nasa_sedac" \
--derived-from "attr_nasa_sedac" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/external_exposure.csv" \
--destination-filepath "./gaia_rocrate/external_exposure.csv" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"

echo "Registering the delta_vocabulary dataset..."
fairscape-cli rocrate add dataset \
--name "delta_vocabulary" \
--author "gaiaOHDSI User" \
--version "1" \
--date-published "2025-01-29" \
--description "A set of OMOP Vocabulary tables containing custom concepts pertinent to the exposure variables and geospatial relationships in the generated EXTERNAL_EXPOSURE table" \
--keywords "Gaia" \
--keywords "OMOP" \
--keywords "external exposure" \
--data-format "csv" \
--derived-from "EXTERNAL_EXPOSURE" \
--derived-from "omop_gis_vocabulary" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/fairscape/delta_vocabulary.csv" \
--destination-filepath "./gaia_rocrate/delta_vocabulary.csv" \
"./gaia_rocrate" # (ROCRATE PATH)
echo "Done!"