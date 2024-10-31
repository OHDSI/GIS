# FAIRSCAPE Explore

## Overview
The goal of this document is to explore and map the process for using FAIRSCAPE to transparently disclose the operations that introduce a data point derived from an external source of place-based data into the OMOP `external_exposure` extension table.

Additional goals:
- Explore FAIRSCAPE CLI
- Can a FAIRSCAPE Evidence Graph/ ROCrate/ other formal structure for representing provenance replace our current (opaque) mechanisms for executing transformations: geom_spec, attr_spec, create_exposure? Or are these just meant to document/clarify what was performed, but shouldn;t be the "vessel" for the transformation instructions?
  - Maybe this wasn't the intention of RoCrate/evidence graph, but we could refactor gaiaCore to work around it?

## General Thoughts
### Can the whole process be automated?
A given record in the data_source table should hypothetically have all of this metadata. The gaiaCore software should likely be "registered software". I could imagine us scripting this general process that: 
#### Boilerplate
This will happen, essentially the same way, for every "run"/"study" that is performed. The only changes are that gaiaCore version will change and data_source/variable_source will change as records are added, modified, deleted.
1) creates an RO Crate
2) registers gaiaCore as software
3) adds/registers data_source as dataset (copies CSV file)
4) adds/registers variable_source as dataset (copies CSV file)
#### Study-specific: Creating geom_X
  - Assuming a single variable, or even multiple variables from the same XDS_X, this set of "steps" will need to occur once.
  - In the case that variables from multiple XDS_X that specifically reference difference source geom datasets are used, this step runs multiple times
  - "This step must occur one time for each distinct geometry source that is used in the 'study'"
  - (Ideally, these steps leverage the metadata in the data_source table)
5) Locally download an external dataset (XDS_X), add/register the file as dataset (SHP, CSV, whatever data type) - metadata fields populated from the data_source record
  - The download of the external dataset is already a required step of loadGeometry()...
6) Generate the geom_X from the data_source (if applicable) by calling gaiaCore::loadGeometry()
7) add/register a CSV version of the geom_X table as a dataset
  - "derived-from" data_source (this doesnt sit well... is it derived from data_source? data_source contains a "key ingredient" for loadGeometry to function...)
  - "derived-from" XDS_X
8) Register the specific loadGeometry computation that: 
  - "name" loadGeometry X
  - "run-by" ???? how to specify some other script runs this...
  - "used-software" gaiaCore v0.1.0
  - "used-dataset" data_source
  - "used-dataset" XDS_X
  - "generated" geom_X
#### Study-specific: Creating attr_X (assume single variable)
9) Locally download an external dataset (XDS_X), add/register the file as dataset (SHP, CSV, whatever data type) - metadata fields populated from the data_source record
  - The download of the external dataset is already a required step of loadVariable()...
  - Note, this may be different or the same as the XDS_X used for geometry...
10) Generate the attr_X from the variable_source/data_source by calling gaiaCore::loadVariable()
  - This step gets a little fuzzy because multiple runs of loadVariable may alter a single final dataset.
  - attr_X is formed from 1:n "variables" from XDS_X, with crucial input from both data_source and variable_source (which contain the "key ingredient")
11) add/register a CSV version of the attr_X table as a dataset
  - "derived-from" data_source (data_source contains a "key ingredient" for downloading/reading XDS_X)
  - "derived-from" variable_source (variable_source contains a "key ingredient" for reading/transforming individual variables from XDS_X)
  - "derived-from" XDS_X
12) Register the specific loadVariable computation that: 
  - "name" loadVariable X
  - "run-by" ???? how to specify some other script runs this...
  - "used-software" gaiaCore v0.1.0
  - "used-dataset" data_source
  - "used-dataset" variable_source
  - "used-dataset" XDS_X
  - "generated" geom_X
#### Study-specific: Creating attr_X (assume multiple variables, single attr_X)
- What changes from the single variable scenario?
  - single attr_X implies that all variables are coming from the same XDS_X (not necessarily same as geom_X)
  - Step 10 will run multiple (n) times before step 11 runs once...
  - considering step 12... is this one computation or n computations?
    - This almost seems trivial... should there simply be a vectorized method of loadVariable that takes a single variable_id or list of variable_id
    - if there is a `loadVariable(<list>)` function, then this case would be easily solved. May get confusing when the same computation generates multiple different attr_Xs?
12a) Register the specific loadVariable computation that: 
  - "name" loadVariable [Xa, Xb, Xc] (?)
#### Study-specific: Creating attr_X (assume multiple variables, multiple attr_Xs)
- What changes from the above scenarios?
  - Step 9 will repeat; multiple external datasets will be downloaded and added/registered to the RO crate
  - Step 10 will run multiple (n) times before step 11...
  - Step 11 will run multiple times - once for each attr_X that was created
  - Step 12 should probably occur once for each attr_X created:
12b) Register the specific loadVariable computations that: 
  - "name" loadVariable [Xa, Xb, Xc]
  - ...
  - "used-dataset" XDS_X
  - "generated" geom_X
and...
  - "name" loadVariable [Ya, Yb, Yc]
  - ...
  - "used-dataset" XDS_Y
  - "generated" geom_Y


> The above details a "sequential" creation of an RO Crate for a specific study (stopping short before Gaia data becomes OMOP data - external_exposure table creation)

> One alternative approach to consider is one where a researcher "creates there gaia environment" (i.e. runs loadVariable() for the variables of interest) and then a single gaiaFairscape::create_ro_crate() does the work of deconstructing the database environment into the RO Crate. This approach may be significantly easier to implement.

> As I think through this, an important feature of generating the RO Crate is that the evidence graph it generates could/should serve the second purpose of recreating the exact "gaia environment" - same version of data_source/variable_source, same version of gaiaCore, same gaiadb schema, same source data etc.


## Perceived Limitations of FAIRSCAPE
After starting to map out our source data to external exposure workflow using FAIRSCAPE CLI, here is a short list of potentially limiting features.

### Dataset must reference a physical file
This is potentially limiting in a few ways. Our workflow relies on access to (generally) publicly available and machine-accessible datasets that are then automatically downloaded. 

This has implications for the PHI that may be contained in healthcare data, including personal identifiers in location and external_exposure tables.

## Process

### Install CLI
Install fairscape-cli `pip install fairscape-cli`

### Create RO Crate
Once installed, create an RO Crate:
```bash
fairscape-cli rocrate init \
--name "test gis rocrate" \
--description "GIS RO Crate" \
--organization-name "OHDSI" \
--project-name "GIS Workgroup" \
```

### Add dataset
We can "add" a dataset to our crate. Here we add what we would consider an "external" dataset. This source dataset becomes a single entry in gaia:data_source. 

(I would like this part better if I could simply reference the URL, but maybe its an RO Crate requirement to copy the entire dataset into the crate.)

This step is performed by:
```bash
fairscape-cli rocrate add dataset \
--name "NASA SEDAC PM2.5" \
--author "NASA SEDAC group" \
--version "1" \
--date-published "2021-04-05" \
--description "The Annual PM2.5 Concentrations for Countries and Urban Areas, 1998-2016, consists of mean concentrations of particulate matter (PM2.5) for countries and urban areas. The PM2.5 data are from the Global Annual PM2.5 Grids from MODIS, MISR and SeaWiFS Aerosol Optical Depth (AOD) with GWR, 1998-2016. The urban areas are from the Global Rural-Urban Mapping Project, Version 1 (GRUMPv1): Urban Extent Polygons, Revision 02, and its time series runs from 1998 to 2016. The country averages are population-weighted such that concentrations in populated areas count more toward the country average than concentrations in less populated areas, and its time series runs from 2008 to 2015." \
--keywords "air" \
--keywords "air quality" \
--data-format "SHP" \
--source-filepath "/mnt/c/Users/kzollovenecek/Downloads/sdei-annual-pm2-5-concentrations-countries-urban-areas-v1-1998-2016-urban-areas-shp.zip" \
--destination-filepath "./nasa-pm25.zip" \
"./"
```


###