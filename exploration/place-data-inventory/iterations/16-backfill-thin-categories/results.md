# Prompt 1.8 backfill report, 2026-10-29

**This assumes:** (1) the five category definitions in `scripts/categories_2026_10_29.py`; (2) the tier rule from `scripts/refine_2026_10_28.py`, applied to what one landing page showed; (3) the US federal licence rule from 1.5, applied to NOAA only. Nothing was merged into the inventory.

**Contrary evidence first.** The `candidates-2026-10-29.csv` pool is poor for these categories. Of the 18 drinking-water and 18 algal-bloom rows still unmatched, almost all are one-off research datasets (Australian pilot rows, small lake or site studies), and the policy and sub-national rows are mostly papers' supplements. I used the pool only where a row was a real product, and filled the rest from scripted DataCite and data.europa.eu searches. Heat (about 240 rows) is mostly MODIS and VIIRS product versions. So "found" below is mostly search-found, not pool-found.

## Per category

| Category | Chosen and read | Gold | Silver | Bronze | Browser needed | Source of candidates |
|---|---|---|---|---|---|---|
| Health policy | 12 | 0 | 9 | 1 | 2 | DataCite (publisher search) |
| Sub-national development | 9 | 1 | 5 | 2 | 1 | DataCite; data.europa.eu returned nothing usable |
| Water quality | 9 | 1 | 5 | 1 | 2 | DataCite; data.europa.eu returned only national portals |
| Heat and temperature | 12 | 6 | 3 | 1 | 2 | pool (5) and DataCite (7) |
| Deprivation and vulnerability indices | 9 | 2 | 2 | 2 | 3 | pool (7) and DataCite (2) |
| **Total** | **51** | **10** | **24** | **7** | **10** | cap was 60; fewer than 12 distinct products turned up for three categories |

Reading: the 10 "Browser needed" rows were blocked by HTTP 403 or a JavaScript-only page (ICPSR, DataLumos, figshare, Iowa State, UIC, CSIRO, EDI, Eurostat); no workaround was tried. Dataverse landing pages return empty to scripts, so for six Harvard/Climateverse records I read the Dataverse **metadata API** (JSON, not a file download); the evidence column says so.

## Three strongest additions per category

- **Health policy:** `us_lawatlas_pdmp_laws_2014_2023` (all states plus DC, valid 2014 to 2023-12-31); `us_lawatlas_buprenorphine_prescribing_laws` (2023-03 to 2024-09; fits GIS#338); `us_lawatlas_gabapentin_scheduling_pdmp_laws` (2016 to 2024-12-31). All are Silver only because the licence page was not read (see below).
- **Sub-national development:** `global_worldbank_national_poverty_line_subnational` (Gold: CC BY 4.0, admin1, 1992 to 2016); `global_ciesin_povmap_small_area_poverty_inequality` (shapefiles, about 20 countries, 1990 to 2002); `in_climateverse_national_mpi_state_district` (CC0, state and district, 2015 to 2023, but the record lists only the codebook).
- **Water quality:** `au_nsw_beachwatch_swim_sites_live` (Gold, daily feed, CC BY 4.0, outside the US); `us_noaa_ncei_greatlakes_cyano_hab_satellite` (CC0, 2000 to 2024, CSV and GeoTIFF); `au_jcu_gbr_catchment_riverine_water_quality_v2` (466 sites, 1986 to 2023). None adds US drinking-water coverage.
- **Heat and temperature:** `us_noaa_nclimgrid_daily` (Gold via the federal rule, 1951 to present, about 5 km, netCDF); `us_gridex_extreme_heat_cold_events` (Gold, CC0, tract/county/state, 2008 to 2022); `eu_zenodo_era5land_weekly_air_temperature_1km` (Gold, 1 km, weekly, 2016 to 2020).
- **Deprivation and vulnerability:** `global_ciesin_grdi_v1` (Gold, CC BY 4.0, 1 km, 2010 to 2020); `br_glasgow_small_area_deprivation_2010` (Gold, 310,120 census sectors; complements the IVS row); `us_harvard_svi_percentiles_block_group` (Silver, a third-party block-group derivation of CDC SVI; check against CDC).

## Health policy: are usable policy datasets reachable in these channels?

**Yes, in DataCite, but only one publisher.** DataCite returns 76 datasets for the publisher "Center for Public Health Law Research" (Temple), which is LawAtlas, each with a DOI under 10.60541 and a lawatlas.org landing page. Nine of the 12 policy rows are from it. Outside that publisher, the DataCite and data.europa.eu title searches found only ICPSR studies (State Firearm Law Database, tobacco policies; both blocked at 403) and the BU COVID-19 policy database. data.europa.eu found nothing usable for state health policy (national portals, pay-policy statements).

So **Prompt 2.1's sources are not the only route for LawAtlas**: its datasets can be enumerated through DataCite. They do still need Prompt 2.1 for what DataCite does not carry (PDAPS, APIS, CDC STATE System, KFF, Guttmacher). **Overlap warning:** if 2.1 also proposes LawAtlas rows, merge by DOI; my ids are `us_lawatlas_*`.

Limits of what I confirmed: LawAtlas pages say "create a free account" to download; they name no licence (Terms of Use and Data Licensing pages are linked and unread); no file format and no key column are stated. `us_lawatlas_state_retail_marijuana` says "Dataset coming soon!" and is Bronze. The remaining 67 LawAtlas datasets in the DataCite list are not read.

## Tier caveats (read before merging)

- **Silver is weaker than it looks for 10 rows:** the rule allows a Silver when the licence check is `not_checked`. That is true of the 8 LawAtlas rows, the BU CUSP database, and `us_cehi_ndi_2010_tract`. They are listed by that name in `proposed-rows-2026-10-29.csv` (`chk_license` = `not_checked`).
- **Seven hand overrides to Bronze** (column `rule_tier` holds the rule's answer): LawAtlas marijuana (no data yet); two Climateverse catalogue pointers to HDX (licence "Other", no files); the EPA ORD cyanobacteria record (says "not publicly accessible"); NASA VNP21A1D V001 (page says DEPRECATED); EDI-PT 2021 (access by request); the Meghalaya SECC pointer (no files, one Indian state).
- **Federal rule:** applied to two NOAA NCEI rows only (nClimGrid-Daily; Lake Erie HAB bulletin). NASA pages state "openly shared, without restriction" and SEDAC/CIESIN is not a federal agency, so neither used the rule.
- **Not full checks:** the A-checks (redirect, TLS, archive, machine metadata) were not run; `chk_link_live` and `chk_soft404` are "page read today". `partB/BRIEF.md` allows one documentation page; I read only the landing page for each candidate.
- Possible duplicate: the SEDAC UHE-Daily row also exists on Harvard Dataverse (10.7910/DVN/ABDLCD); I kept the SEDAC one. HadISDH.extremes is marked "Superseded" on its CEDA page, so it is Silver, not Gold.

## What remains thin

- **Drinking water (US):** nothing new. No candidate gave public water-system-level data beyond what is in the inventory (SDWIS, UCMR, lead service lines). Water-system service-area geometry is still the gap.
- **Sub-national development:** nothing recent. The best rows end in 2016 or earlier (Poverty Mapping Project is 1990 to 2002). Current DHS/SDG sub-national products (DHS Spatial Data Repository was blocked) need a browser pass; the GDL SHDI row already exists.
- **Health policy:** county or city policy is absent (only state level). Retail marijuana, and the ICPSR firearm and tobacco studies, need a browser pass.
- **Deprivation:** three US rows (NaNDA ADI, UIC NDI 2018, Eurostat NUTS2 material deprivation) are blocked; the national indices for the UK, Canada and New Zealand are already in the inventory.
- **Browser-needed queue from this run (10):** `us_icpsr_state_firearm_law_database`, `us_icpsr_population_weighted_tobacco_policies`, `global_usaid_dhs_spatial_data_repository`, `us_edi_ny_lakes_hab_reports`, `us_iastate_pfas_iowa_drinking_water_sources`, `global_figshare_urban_heat_island_intensity`, `au_csiro_lst_uhi_capital_cities_2018_19`, `us_nanda_adi_block_group`, `us_uic_ndi_2018_tract`, `eu_eurostat_severe_material_deprivation_nuts2`.

## Files (all in `docs/discovery/backfill/`)

`candidates-chosen-2026-10-29.csv` (51 rows), `proposed-rows-2026-10-29.csv` (51 rows in the inventory's columns, plus `rule_tier`; `category`, `categories`, `round = 1.8-backfill`), this report, and the scripts that built them (`search.py`, `chosen.py`, `dv.py`, `data1.py`, `data2.py`, `build.py`, `chosen.json`). No inventory, `landscape/` or `fileverify/` file was touched; nothing was committed.
