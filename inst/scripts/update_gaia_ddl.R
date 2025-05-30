# This script generates DDL SQL for all supported dialects for a given CDM version.
# It assumes the GIS package is loaded via devtools::load_all() or installed.

cdmVersion <- "5.4"
for (dialect in listSupportedDialects()) {
  writeDdl(dialect, cdmVersion)
  writePrimaryKeys(dialect, cdmVersion)
  writeForeignKeys(dialect, cdmVersion)
}
