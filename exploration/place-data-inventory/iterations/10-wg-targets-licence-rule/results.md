# Exploration 1.5: working-group targets and the federal licence rule (2026-10-29)

> **This assumes:** (1) the WG rule of 2026-10-28 holds: a US federal work is public domain (17 U.S.C. 105) unless a page says otherwise (R, Robert's decision); (2) "federal" was decided by publisher plus a `.gov`/`.mil` landing page, list in `federal-publishers-2026-10-29.csv` for review; (3) a licence `pass` from the rule rests on the rule, not on a statement on the page, and the tier counts below inherit that.

Files: `inventory-combined-2026-10-29.csv` (601 rows; column `wg_request` added), `place-data-inventory-2026-10-29.xlsx`, `inventory.csv` (275 Gold+Silver), `federal-publishers-2026-10-29.csv`, `federal-rule-rows-2026-10-29.csv`, `scripts/licence_rule_2026_10_29.py`, `scripts/build_workbook_2026_10_29.py`.

## 1. The licence rule

- **Federal rows examined:** 132 rows have a federal publisher and a licence check of fail or not_checked. **124 were set to pass** (`license_class = public_domain_us_federal`), including 4 of the new WG rows; 19 of the 124 are rows whose page was never read for content (their detail line says so). **8 were not changed:** 5 kept back because a page or the listing states other terms (SEER data use agreement, All of Us/N3C restricted, NIEHS PEGS by request, NASA NEX-GDDP "CMIP6 Terms of Use", EIA/GWPC co-publication), 2 where the landing domain is not federal (ECHO, HHEAR), and DIVA-GIS (not federal).
- **Not federal, rule not applied:** PEDP mirrors (stay Bronze), NASA SEDAC/CIESIN, DataLumos/Data Rescue copies, NaNDA/ICPSR, universities and non-profits, state and city `.gov`. Left for review: Smithsonian, Oak Ridge (Daymet), the Water Quality Portal.
- **Rows already `warn` ("public domain, assumed") were not touched**, as the rule covers fail and not_checked only.

Round 1 tiers (571 rows):

| Tier | Before | After |
|---|---|---|
| Gold | 33 | 77 |
| Silver | 156 | 195 |
| Bronze | 192 | 109 |
| Browser needed | 150 | 150 |
| Failed | 40 | 40 |

Moves: Bronze → Gold 43, Bronze → Silver 40, Silver → Gold 1. All 28 federal Browser-needed or Failed rows stay put (the rule changes licence only). With the WG rows and the round 2 pilot, the whole file is Gold 77, Silver 198, Bronze 132, Browser needed 154, Failed 40 (601).

**Two things to look at.** (a) 43 new Golds came from one assumption, so Gold now means "federal, and nothing contradicts it" for many rows, not "licence read". (b) `us_epa_ucmr` became Gold although its unit is "state; results are per water system, which is not a geographic unit"; the existing unit check passes it, and that check deserves a second look. A row never read for content cannot become Silver through the rule (B_done is taken from before the change).

## 2. The nine targets (page reads 2026-10-29; 24 of 60 fetches used, 9 of them issues)

| Request | What was asked | Row(s) | Tier | Key fields | Evidence |
|---|---|---|---|---|---|
| #28 Multidimensional Deprivation Index | The issue links only a Census working paper, so it means the Census MDI (not UNDP's MPI; not added) | `us_census_mdi` (new) | Bronze (capped by hand) | State-level comparisons; 2017 estimates; **PDF only, no data files**; federal rule | census.gov/library/working-papers/2021/demo/SEHSD-WP2021-03.html |
| #23 CyAN | NASA OB.DAAC CyAN v5 GeoTIFF tiles | `global_nasa_cyan` (new) | Silver | 300 m tiles, CONUS + Alaska; 2002-2012 and 2016-present; now Version 6; GeoTIFF; login not stated | earthdata.nasa.gov/data/projects/cyan (old URL redirects) |
| #31 DIVA-GIS | Country and global geometry for the SDG data | `global_diva_gis` (new) | Bronze | Admin areas (from GADM), levels vary; shapefiles; **no licence stated**; page dated ("old") | diva-gis.org/data.html (the `www` host does not resolve) |
| #26 Suicide-risk repository | A dataset repository (ORNL, with the VA) | none | n/a | Report ORNL/TM-2023/3027 names themes only (air quality, financial, social connectivity, transport/food access, homelessness); "may be shared upon agreement" | osti.gov/biblio/1997699 |
| #29 Environmental Justice Index | EJI 2022 files | `us_cdc_eji` | Silver (was Bronze) | Tract; 36 factors, 3 modules; download page rendered empty, so vintage and formats unconfirmed | atsdr.cdc.gov/place-health/php/eji/index.html |
| #35 TRI Basic Data | tri_us_2021 csv | `us_epa_tri` | Gold (was Bronze) | Point; 1987-2024; csv with lat/lon; no stated cadence | epa.gov/toxics-release-inventory-tri-program/tri-basic-data-files-calendar-years-1987-present |
| #32 AQS sites | aqs_sites.zip, the geom dependency for EPA daily data | `us_epa_aqs_sites_monitors` (new) | Silver | 20,994 sites and 370,090 monitors; csv zip; updated twice a year; columns not listed on page | aqs.epa.gov/aqsweb/airdata/download_files.html |
| #38 UCMR 3 | 2013-2015 occurrence data | `us_epa_ucmr3_occurrence` (new) | Silver | 2013-2015; zip text files; keyed to water system; ZIP codes only per the issue | epa.gov/dwucmr/occurrence-data-unregulated-contaminant-monitoring-rule |
| #34 SDG indicators | Ingest the UN SDG database; needs sub-national data | `global_un_sdg_global_database`; `global_gdl_shdi`; `global_dhs_spatial_data_repository` (new) | Browser needed; Bronze; Browser needed | SDG portal is a JS shell (title only); GDL SHDI: free registration, **non-commercial** terms, CSV/Excel; DHS: 403 | unstats.un.org/sdgs/dataportal; globaldatalab.org/termsofuse/; spatialdata.dhsprogram.com/home/ |

Also tagged: ACS 5-year #37 (Gold), AHRQ CLH #36 (Silver, now by rule), COI #30 (Silver), EM-DAT #27 (Silver, non-commercial), EEA e-Reporting #41 (Gold).

## 3. Coverage of the WG's dataset requests

Of the 14 requests (9 targets + 5 already covered), **10 now have a Silver-or-better row**: #23, #27, #29, #30, #32, #35, #36, #37, #38, #41. #28 and #31 are Bronze, #34 is Bronze (GDL) or Browser needed, and #26 has no row.

## 4. What remains

- **Needs the WG to define:** #26 (the ORNL repository is a report with themes, not a downloadable dataset; add rows once the WG names the component datasets, e.g. from the SEDH-SDOH candidates spreadsheet on the issue); #34 (which indicators, which countries; the sub-national candidates are non-commercial or unreadable); #28 (confirm the Census MDI is wanted, and whether Census publishes tables).
- **Needs a person at a browser:** the UN SDG portal, DHS Spatial Data Repository, and the EJI download page (years, formats).
- **Open checks:** AQS site file columns (open one file); CyAN login requirement and its Data Use page; UCMR 3 ZIP-code file; DIVA-GIS is dated and its geometry overlaps `global_gadm_boundaries` and `global_geoboundaries`, so boundaries belong to the place-identifiers backlog (`backlog-place-identifiers-2026-10-28.md`).
- **The workbook's About sheet still carries the 28 October wording** (571 rows, "built 20-28 October"); its 276 Summary formulas all evaluate to the Python counts. The 28 October numbers check was not re-run on the new files; the counts above come from the script's own printout and were checked against the CSV and workbook (Gold + Silver = 275 in both).
