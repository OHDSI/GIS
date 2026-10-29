# File-verify of the working-group request datasets (Prompt 1.7), 2026-10-29

Evidence: `fileverify-2026-10-29.csv` (17 rows), `schemas/*.txt` (13), `proposed-rows-2026-10-29.csv` (3). Nothing merged into the inventory.

> **This assumes:** (1) one small file per product represents the whole product; (2) "verified" means the file opened and its columns, key, geometry and years were read, not that the licence was re-read; (3) the page-verified inventory fields are the baseline being tested.

## Contrary to expectation (read first)

- **Census ACS needs a key even for a tiny API call.** `api.census.gov/data/2024/acs/acs5?get=...` redirects to `missing_key.html`. The prompt expected no key. I did not register; the row is "partly", verified through the open bulk `.dat` file instead.
- **DHS is not gated for what #34 needs.** `api.dhsprogram.com` returns sub-national indicators and boundary polygons (WKT) with no key or login, and the region ids match. Only the SDR website's own shapefile downloads are untested.
- **UN SDG has no sub-national data.** Location is only ALLAREA / URBAN / RURAL; the area list is countries and aggregates. It does not meet #34's premise.
- **UCMR dates are later than the inventory says.** UCMR 3 collection dates run to 2016-12-14 (inventory: 2015). UCMR 5 runs to 2026-06-17 (inventory: 2023-2025, "final August 2026"). The zip URL path says 2023-08 but holds a 2026-10-15 refresh.
- **UCMR does have a ZIP file** (`UCMR3_ZIPCodes.txt`, `UCMR5_ZIPCodes.txt`, PWSID to ZIP), contrary to the generic row's "no ZIP field named". Coverage: 87% of UCMR 3 PWSIDs, all but 2 of UCMR 5.
- **EEA's download web app is stopped (403)**, but the API behind it works without login and the parquet carries no coordinates (join to the station REST layer).

## Results

| Request | Row | Status | Finding |
|---|---|---|---|
| #29 | us_cdc_eji | verified | RI 2024 CSV (247 tracts, 170 cols, GEOID) and GDB (MultiPolygon, ESRI:102003). Tool lists 49 states + US, no AK/HI |
| #35 | us_epa_tri | verified | RI 2024: 233 rows x 122 cols, TRIFD, lat/lon, pounds, datum empty. data.epa.gov endpoint, HEAD fails |
| #32 | us_epa_aqs_sites_monitors | verified | 20,994 sites, 370,090 monitors; key = state+county+site; 867 sites at lat 0; mixed datums |
| #32 | us_epa_aqs_data_mart_api | partly | Bulk `daily_88101_2024` (740,924 rows) joins 1,035/1,035 sites. API not called (key) |
| #38 | us_epa_ucmr3_occurrence | verified | 1.07M rows, 6,190 PWSID, ZIP file present; dates 2013-2016 |
| #38 | us_epa_ucmr | verified | Generic row; opened UCMR 5 (1.99M rows, 10,313 PWSID, dates to 2026-06). Recommend one row per cycle |
| #38 | UCMR 5 (new) | proposed | See `proposed-rows-2026-10-29.csv` |
| #23 | global_nasa_cyan | gated | Listing open (70 files for 2026-10-28; CONUS tiles 0.2-0.4 MB). `/getfile` 302s to Earthdata Login |
| #30 | us_brandeis_coi | verified | 2020 tracts, 1,090,333 rows = 83,959 tracts x 2012-2024, `geoid20`, no geometry. Old access URL now 301s; files on public Globus |
| #37 | us_census_acs_5year | partly | API key-gated. Bulk B19013: 543,579 rows incl. 242,297 block groups; GEO_ID like `1500000US...`; no geometry |
| #41 | eu_eea_air_quality_ereporting | verified | Parquet, 6,943 hourly PM2.5 rows (to 2026-10-29), `Samplingpoint` joins to station point layer (6,990 stations) |
| #36 | us_ahrq_sdoh_database | failed | ahrq.gov 403 (CloudFront) to this client; openICPSR page loads, download not attempted |
| #27 | global_cred_emdat | gated | Login / Register confirmed |
| #34 | global_gdl_shdi | gated | "Free-of-charge registration necessary" confirmed |
| #34 | global_un_sdg_global_database | verified | Open API; country-level only (see above) |
| #34 | global_dhs_spatial_data_repository | partly | Open API with sub-national data + WKT polygons; SDR site downloads untested |
| #28 | us_census_mdi | no_file | One PDF link, 0 tables, no csv/xlsx |
| #31 | global_diva_gis | verified | LUX adm0-4 shapefiles, EPSG:4326, 116 adm3. **GADM 2.5 (2015), non-commercial, no redistribution** |

Status counts (17 rows): verified 9, partly 3, gated 3, failed 1, no_file 1.

**Requests with a file-verified source: 9 of 13** (#29, #30, #31, #32, #35, #38, #41 clean; #34 and #37 partly). Not: #23 (gated), #27 (gated), #28 (no file), #36 (failed).

## Other mismatches with the page reads

- EJI: inventory had no year or format; file gives 2024 edition, CSV + GDB, dictionary included.
- AQS: no single site id; 3-part code, and the column is `Site Num` in data files but `Site Number` in the site file.
- COI: access URL redirects; licence is "agree to Terms and Conditions" (not read). ZIP and county files also exist.
- DIVA: licence blank in inventory; the file says non-commercial, no redistribution. Vintage 2015, one admin level for Malta.
- EEA: requested 2023 but the file started 2026-01-01 (date filter did not apply to the URL list).
- TRI: datum not stated in the data.

## What is gated, and what it would take

| Gate | Rows | What it takes |
|---|---|---|
| Earthdata Login | CyAN | free account; downloads then possible (listing already open) |
| Census API key | ACS API | free key; not needed for bulk `.dat` |
| Registration | EM-DAT, GDL | free accounts, non-commercial terms |
| Bot block / login | AHRQ CLH | a browser session, or the openICPSR login |
| API key + email | AQS Data Mart API | free; not needed for the AirData bulk files |

I did none of these (rules: no sign-ins or registrations).

## Scratch downloads

Moved to `_to_delete/` for Robert to delete: `fileverify-scratch-2026-10-29` (1,703 MB including extracted copies, of which about 267 MB were downloaded files; well under the 3 GB cap, largest file 128 MB) and `fileverify-venv-2026-10-29` (291 MB; a Python venv holding `pyogrio`, `pyarrow`, `pyshp` that I installed to read GDB, parquet and shapefiles; the system Python was not changed). `_scratch/` is empty and gitignored.

Not done: no commits, no inventory merge, no member-repo changes. UA header was used on every request.
