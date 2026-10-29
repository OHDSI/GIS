# PROMPT 1.7: file-verify the working-group request datasets

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet (`/model sonnet`). It can run while Prompt 2 is still going, because it writes only to its own folder. Time box: about 1 to 1.5 hours.

## Purpose

The working-group request rows are **page-verified**: licence, years, unit, access and format were read from the publisher's pages. This run makes them **file-verified**. For each row, download one small, representative file, open it, and record what is actually in it: columns, place key, geometry, row count and the years present. The result lets the comments on the gaiaCatalog request issues say "file-verified" with evidence.

## Rules

- **Downloads are allowed in this run only, and only for the files below.**
  - Use the smallest file that represents the product: one state, one year or one tile rather than the national bundle, where the publisher offers that.
  - **Cap: 500 MB per file and 3 GB in total.** Skip anything larger, and record why.
- **Keep files out of the repo and the workspace docs.** Download into a scratch folder outside `docs/` (for example `D:\workspace\gaia\_scratch\fileverify\`; create it, and make sure `.gitignore` covers `_scratch/`).
  - **Don't delete the downloads yourself.** Deleting isn't allowed in this workspace. When done, move the scratch folder into `_to_delete/`, and list its size in the report so Robert can delete it.
- **No sign-ins, no registrations, no bot-protection workarounds, no CAPTCHAs.** If a download needs an account or accepting terms behind a login, don't do it: record "gated" and what the gate is.
- **Writes:** `docs/discovery/fileverify/` only. Don't touch the inventory CSVs, `landscape/` or `round2/`; Prompt 2 may still be running. Member repos are read-only. Don't commit.
- One process, no sub-agents. User-agent: `OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)`.
- If a usage limit stops you, don't retry. Write the report with what exists.

## Rows (from `inventory-combined-2026-10-29.csv`, column `wg_request`)

| Request | Row id | Suggested file to open |
|---|---|---|
| gaiaCatalog#29 | `us_cdc_eji` | EJI 2024 CSV for one state (download page: eji.cdc.gov/dfe/eji_data_download_dfe.html); note the GDB option |
| gaiaCatalog#35 | `us_epa_tri` | TRI Basic Data file, one recent year, US or one state |
| gaiaCatalog#32 | `us_epa_aqs_sites_monitors` | `aqs_sites.zip` (and `aqs_monitors.zip` only if small) |
| gaiaCatalog#32 | `us_epa_aqs_data_mart_api` | Covered by the sites file plus one pre-generated daily file (e.g. a small annual or daily PM2.5 zip from the AirData download page). Record how daily records key to sites |
| gaiaCatalog#38 | `us_epa_ucmr3_occurrence` | `ucmr3-occurrence-data.zip`: list its files, and look for a ZIP-codes-served file |
| gaiaCatalog#38 | `us_epa_ucmr` | Same as above. Note the row is generic |
| gaiaCatalog#38 (extra) | UCMR 5 (not yet a row) | `ucmr5-occurrence-data.zip`: same checks. Propose a new row (see the output) |
| gaiaCatalog#23 | `global_nasa_cyan` | One CONUS tile, one recent day or week, from the CyAN file search. If the download needs an Earthdata Login, record "gated: Earthdata Login" and stop |
| gaiaCatalog#30 | `us_brandeis_coi` | COI 3.0 tract file (or its smallest download) from data.diversitydatakids.org |
| gaiaCatalog#37 | `us_census_acs_5year` | One small API call (e.g. one table for one county's tracts) from api.census.gov; no key needed for a small call. Don't store any key |
| gaiaCatalog#41 | `eu_eea_air_quality_ereporting` | One station's file for one pollutant and year from the EEA download service |
| gaiaCatalog#36 | `us_ahrq_sdoh_database` (now CLH) | The AHRQ CLH Database file on ahrq.gov if it is open. If it is only on openICPSR behind a login, record "gated" |
| gaiaCatalog#27 | `global_cred_emdat` | Expected "gated: registration". Confirm and record |
| gaiaCatalog#34 | `global_gdl_shdi`, `global_un_sdg_global_database`, `global_dhs_spatial_data_repository` | GDL: expected "gated: registration, non-commercial". UN SDG: try the public SDG API for one indicator and one country (sub-national dimensions present?). DHS: expected "gated" (403 or registration) |
| gaiaCatalog#28 | `us_census_mdi` | Expected "no data file (PDF only)". Confirm whether any table exists |
| gaiaCatalog#31 | `global_diva_gis` | One country's administrative-areas shapefile |

## For each file opened, record

- **The file:** URL, size and file type; for an archive, the list of files inside.
- **Columns:** count, names (the first 40 is fine), and any data dictionary present.
- **The place key:** which column (GEOID/FIPS, ZIP, ZCTA, PWS ID, site id, NUTS, ISO, lat/lon) and a sample value.
- **Geometry:** embedded or not; type (point / line / polygon / raster); CRS, if readable (GDAL, geopandas or rasterio, where available).
- **Row count** (or the raster size and resolution).
- **Years present** in the data, and the most recent date.
- **Match:** does it agree with the page-verified fields in the inventory (unit, years, format)? Note every mismatch.
- **Gated or failed:** what the gate or error is.

## Outputs (in `docs/discovery/fileverify/`)

1. `fileverify-2026-10-29.csv`: one row per inventory row checked. Columns: `id`, `wg_request`, `file_verified` (date, or blank), `status` (verified / partly / gated / no_file / failed), `file_url`, `file_type`, `columns_found` (count; names), `place_key_found`, `geometry_found`, `crs`, `row_count`, `years_found`, `latest_date`, `mismatches`, `notes`.
2. `schemas/<id>.txt`: column names, dtypes and 5 sample rows (or the raster metadata). Keep these small.
3. `proposed-rows-2026-10-29.csv`: UCMR 5, and any other new row worth adding, with the inventory's columns filled where known.
4. `fileverify-report-2026-10-29.md`, about 1 page:
   - a table of request · row · status · the one-line finding;
   - how many requests now have a file-verified source;
   - mismatches with the page reads;
   - what is gated, and what it would take;
   - the size of the scratch downloads now in `_to_delete/`.

Don't merge into the inventory. That happens after Prompt 2 finishes.
