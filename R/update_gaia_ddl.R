source("R/createDdl.R")
source("R/writeDdl.R")
source("R/listSupportedVersions.R")
cdmVersion <- "5.4"
for (dialect in listSupportedDialects()) {
    writeDdl(dialect, cdmVersion)
    writePrimaryKeys(dialect, cdmVersion)
    writeForeignKeys(dialect, cdmVersion)
}

