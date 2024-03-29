% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/loadGeometry.R
\name{loadGeometry}
\alias{loadGeometry}
\title{Loads a geometry from a registered source into PostGIS as geom_X}
\usage{
loadGeometry(connectionDetails, dataSourceUuid)
}
\arguments{
\item{connectionDetails}{(list) An object of class connectionDetails as created by the createConnectionDetails function}

\item{dataSourceUuid}{(UUID) The UUID for the data source that is registered in the backbone.data_source table}
}
\value{
A table (geom_X) in PostGIS
}
\description{
Loads a geometry from a registered source into PostGIS as geom_X
}
\examples{
\dontrun{

variableSourceId <- 157

variableTable <- DatabaseConnector::dbGetQuery(conn, paste0("SELECT * FROM backbone.variable_source WHERE variable_source_id = ", variableSourceId))

dataSourceRecord <- getDataSourceRecord(conn, variableTable$data_source_uuid)

geomIndex <- getGeomIndexByDataSourceUuid(conn, dataSourceRecord$geom_dependency_uuid)

if (!DatabaseConnector::existsTable(conn, geomIndex$database_schema, paste0("geom_",geomIndex$table_name))) {
  message("Loading geom table dependency")
  loadGeomTable(conn, connectionDetails, dataSourceRecord$geom_dependency_uuid)
}
}

}
