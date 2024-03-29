% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dbUtils.R
\name{importLocationTable}
\alias{importLocationTable}
\title{Import a geocoded cohort table to gaiaDB}
\usage{
importLocationTable(gaiaConnectionDetails, location, overwrite = FALSE)
}
\arguments{
\item{gaiaConnectionDetails}{(list) For connecting to gaiaDB. An object of class
connectionDetails as created by the
createConnectionDetails function}

\item{location}{(data.frame) A table with OMOP location_ids, an address
string, and POINT geometry column named geometry}

\item{overwrite}{(boolean) Overwrite existing tables in the cohort schema?}
}
\value{
A new geom_omop_location table in the gaiaDB omop schema
}
\description{
Import a geocoded cohort table to gaiaDB
}
\examples{
\dontrun{
importLocationTable(gaiaConnectionDetails = gaiaConnectionDetails,
                    location = geocodedLocation,
                    overwrite = FALSE)
}

}
