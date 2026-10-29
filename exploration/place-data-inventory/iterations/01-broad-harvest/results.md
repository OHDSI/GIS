# First-pass harvest of public place-based datasets: summary (2026-10-20)

**This assumes:** (1) the brief in `harvest-prompt-2026-10-20.md` is the plan for this pass, which reverses the 2026-10-01 "curated first" decision for a first broad grab; (2) breadth matters more than field completeness, so blanks are expected; (3) nothing here has been verified beyond reading a landing page or catalog listing. No files were downloaded.

**Output:** `harvest-2026-10-20.csv`, 646 rows, 21 columns (the column set in the brief; it lines up with `inventory.csv` for a later mechanical merge). One row per dataset; releases are in `versions` and `temporal`.

**How it was done.** Seeds came first: the 23 `gaiaCatalog/datastore/data/` folders and the 107 `ohdsi-gis-metadata-template` records, collapsed to 58 rows (one row per underlying dataset, so ten yearly VIIRS records became one, seven SVI records became one, and so on). Eight parallel web sweeps then covered the source groups in the brief. Fragments were merged by `id`; when two sweeps hit the same product under different ids, 30 alias pairs were folded by hand. Rows that still share a landing page (TIGER county vs the TIGER family, EnviroAtlas national vs community, the four GHSL layers, the NaNDA measure families) are deliberate: they are distinct products.

## Row counts

**By theme**

| theme | rows | high | medium | low |
|---|---|---|---|---|
| environment | 133 | 75 | 38 | 20 |
| climate_hazard | 94 | 57 | 24 | 13 |
| sdoh | 81 | 33 | 38 | 10 |
| built_environment | 80 | 29 | 41 | 10 |
| demographics | 67 | 32 | 24 | 11 |
| boundaries | 58 | 33 | 25 | 0 |
| health_outcome | 44 | 23 | 10 | 11 |
| other (elevation, hydrography, catalogs, cohorts, project-internal layers) | 44 | 14 | 23 | 7 |
| toxics | 32 | 17 | 6 | 9 |
| food_access | 13 | 3 | 9 | 1 |
| **total** | **646** | **316** | **238** | **92** |

**By coverage**

| class | rows | notes |
|---|---|---|
| US | 278 | 152 national, 20 CONUS-only, 26 Miami-Dade County (metadata-template seeds), 12 other sub-national (NYC, Chicago, Florida, California, Maryland, Lake County IL, Philadelphia, Connecticut) |
| global | 213 | |
| international (not US, not global) | 155 | EU/Europe 25, GB 17, PE 12 (Huayhuash seeds), CA 11, AU 5, NZ 4, BR 4, MX 4, NL 4, DE 3, CN 3, and one or two each for about 30 more countries (AR AT BD BE CH CL CO DK ES FI FR GH ID IE IL IN IT JP KE KR MA NG NO PH PK PL PT SA SE TR TZ UG ZA) |

**By confidence:** high 316 (publisher page read), medium 238 (catalog listing, search snippet or local record only), low 92 (page down, blocked, withdrawn, or secondary mention).

**By access type:** open_download 434, registration 80, api 31, api_key 22, restricted 20, request 12, blank 47.

**Field fill:** every row has id, name, organization, theme, coverage, source, confidence and date. Blank counts: license 288, versions 250, sub_organization 216, update_cadence 194, access_url 157, temporal 87, variables_examples 60, geography_units 58, access_type 47, format 24, site_url 1 (the DORMIR study layer, which has no URL in its record).

**Sources of listing** (first token): publisher_site 259, metadata_template 43, earthdata 31, literature 30, google_earth_engine 28, epa 24, data.gov 22, census 19, copernicus 18, noaa 14, planetary_computer 14, cdc 13, aws_open_data 12, who 11, gaia_catalog 9, usgs 9, icpsr 9, usda 8, worldbank 8, hdx 8, nso_portal 8, hud 7, un 7, eurostat 7, fema 6, esa 4, and smaller groups. The 58 seed rows are tagged `gaia_catalog` or `metadata_template`; 15 of them were met again on the web and merged, with the web sweep's source prepended.

## Sources swept

**Workspace seeds (read only).** All 23 gaiaCatalog folders (one, `tz_2022_nbs`, has no metadata locally) and all 107 template records.

**US publishers.** EPA (AirData, AQS, AirNow, EnviroAtlas, TRI, Superfund/SEMS, FRS, ECHO, SDWIS, UCMR, RSEI, ATTAINS, NEI, AirToxScreen, FAQSD Downscaler, Envirofacts, GHGRP, RMP, Brownfields, Smart Location Database, Walkability Index, EJScreen status); CDC/ATSDR (SVI, EJI, PLACES, 500 Cities, WONDER, USALEEP, BRFSS SMART, Tracking Network, Heat & Health Tracker, heart-disease and diabetes atlases, NCHS urban-rural); Census (ACS, Decennial, TIGER/Line, cartographic boundaries, Gazetteer, ZCTA, CBP, LODES, PEP, SAIPE, SAHIE, CRE, Planning Database, Geocoder, relationship files); NOAA NCEI (Normals, nClimGrid, GHCNd, Storm Events, sea level, LCD, Atlas 14, C-CAP, HMS smoke); USGS (NLCD, 3DEP, NHD, PAD-US, National Map, LCMAP, NSHM, pesticide use, Water Quality Portal); FEMA (NRI, NFHL, FIRM, OpenFEMA, Hazus); HUD (LIHTC, Public Housing, USPS crosswalk, FMR, Picture of Subsidized Households, CHAS, QCT/DDA, Location Affordability); USDA ERS (seven products), FNS SNAP retailers, NAIP, Forest Service tree canopy; DOT/BTS (NTAD, HPMS, Noise Map, NTD), FAA noise; HRSA (AHRF, HPSA/MUA, FQHC); CMS (MMD, POS, hospital and nursing-home files); NCI (SEER, State Cancer Profiles, GIS portal); AHRQ SDOH Database; Treasury Opportunity Zones; HIFLD status; research groups (ADI, COI, SDI, DCI, Opportunity Insights, Eviction Lab, NaNDA, LTDB, NHGIS, County Health Rankings, City Health Dashboard, Dartmouth Atlas, IHME US county, WUSTL ACAG, CACES, Stanford ECHO smoke, PRISM, Daymet, gridMET/MACA, NLDAS, NEX-GDDP, MTBS, LANDFIRE, Wildfire Risk to Communities, ParkServe, Mapping Inequality, CalEnviroScreen, Walk Score, Zillow, Redfin, First Street, CoreLogic).

**Catalogs of catalogs.** data.gov (via targeted search, see problems), AWS Open Data Registry, Microsoft Planetary Computer STAC, Google Earth Engine catalog and community catalog, Esri Living Atlas (partial), Geofabrik, Overture, Google Open Buildings, Microsoft building footprints.

**Global agencies.** NASA Earthdata DAACs (LP DAAC, GES DISC, NSIDC, PO.DAAC, LAADS, ORNL), SEDAC (via Earthdata and Harvard Dataverse), Copernicus (CDS/ADS, CLMS, CEMS, Marine, Data Space), ESA (WorldCover, CCI, WorldCereal), DLR WSF, JRC (GHSL, GSW, INFORM, flood maps), WorldPop, LandScan, Meta Data for Good, GRID3, Africapolis, WorldClim, CHELSA, TerraClimate, CHIRPS, CRU, Berkeley Earth, GPCC, ISIMIP, GFED, FIRMS, WRI (Aqueduct, Global Forest Watch), ThinkHazard, HydroSHEDS, Global Mangrove Watch, EM-DAT, DesInventar, GEM, Global Flood Database, Yale SUHI, TEMIS, SoilGrids, HWSD, OpenAQ, WAQI, Malaria Atlas Project, IHME GBD and LBD, Pure Earth, GRIP, UNDRR GAR, Smithsonian GVP.

**Global health, development and boundaries.** WHO (GHO, Ambient Air Quality Database, GHE, Mortality Database, malaria, TB, HEAT, GHFD, AFRO, Europe, JMP WASH, Urban Health Index); World Bank (catalog, WDI, GSAP, Microdata, LSMS, CCKP, electrification, Solar Atlas, AICD); AidData; UN (UNdata, SDG database, WPP, WUP, UNEP WESR, SALB, UN-Habitat); FAO (FAOSTAT, GAUL, GLW, Hand-in-Hand, WaPOR, AQUASTAT, GAEZ); UNICEF MICS; UNHCR; WFP; OCHA HDX (COD-AB, COD-PS, healthsites, Kontur, HRSL, ACLED, INFORM, IPC, HOT exports); GLIDE; Global Data Lab; IOM DTM; DHS Program; Global Fund; Gavi; UCDP; GTD; GADM, geoBoundaries, Natural Earth, GeoNames, Who's On First, OpenAddresses, Overture, GeoPostcodes; Eurostat GISCO and regional statistics; EEA (air quality e-Reporting, EAQI, noise, bathing water, Natura 2000, E-PRTR); ECDC; data.europa.eu; ESPON; OECD regions; Our World in Data.

**National statistics offices (43 countries).** UK (ONS, MHCLG IoD, SIMD, WIMD, NIMDM, Defra UK-AIR, Environment Agency, OS, CDRC/GeoDS, OHID Fingertips, NHS ODS, Met Office HadUK-Grid); Canada (StatCan, CANUE, ECCC, PHO ON-Marg, INSPQ, NRCan, open.canada.ca); INSEE, BKG/Destatis/RKI GISD, CBS NL, CSO/Pobal, INE ES, ISTAT, SCB, SSB, Statistics Finland, GUS, INE PT, Statbel, FSO, Statistik Austria, DST; ABS, Geoscience Australia, Stats NZ, NZDep, NZ IMD; IBGE, IPEA IVS, DATASUS, INEGI, CONAPO, DANE, INEI, INE Chile, INDEC; KNBS, NBS Tanzania, UBOS, GRID3 Nigeria, GSS, Stats SA, HCP; ORGI India, e-Stat, SGIS, NBS China, BPS, PSA, Israel CBS, TurkStat, GASTAT, BBS, PBS.

**Literature.** Cui et al. 2022 (Toxics, NIEHS geospatial data workshop), the 2025 C-HER exposome-dataset preprint (arXiv 2511.03750), Lakerveld et al. 2020 (Int J Health Geogr, GECCO), Cook et al. 2021 (JAMIA, SDOH data quality), de Hoogh et al. 2018 (ELAPSE), Xiao et al. 2022 (TAP), Dey et al. 2020 (SAANS), Childs et al. 2022 (smoke PM2.5), the Environmental Exposome Gateway user guide, and NIH All of Us notices on environmental linkage. Exposome programs: EXPANSE, ELAPSE/ESCAPE, Exposome-NL, LongITools, ATHLETE, HELIX, European Human Exposome Network, PEGS, CHORDS, HHEAR, CANUE.

**Skipped, and why.** Eurostat was done once (not by the NSO sweep). NSOs not reached in the time budget: Ethiopia, Malawi, Zambia, Mozambique, Senegal, Egypt, Rwanda (certificate error), Ecuador, Guatemala, Vietnam, Thailand. Scene-level imagery (Landsat, Sentinel, GEDI, ECOSTRESS, EMIT) got one listing row each at most, since raw scenes are not residence-linkable without processing. Restricted cohorts with no public surface (MESA Air, Agricultural Health Study, UK Biobank linkages, Danish registries) were noted in passing or skipped. Source Cooperative, Harvard Dataverse and Zenodo listings are JavaScript-only and were not swept. Household Pulse and other non-place-based surveys were skipped by design.

## Known gaps

- **Food access** is thin (13 rows) and mostly US. Outside the US only WFP and IPC appear.
- **Health outcomes outside the US** rest on DHS, MICS, GBD subnational, WHO HEAT and a few NSO products. No sub-national health-outcome source was found for most countries.
- **Africa and South Asia** NSO rows are largely PDF-only census volumes. Small-area boundaries and tables for those countries come from GRID3, HDX, geoBoundaries and WorldPop instead.
- **Residential noise:** only the BTS noise map (US), FAA airport noise, EEA END (Europe) and the HowLoud seed. No global layer.
- **Heat-health indices** beyond Yale SUHI and the (down) CDC tracker are thin; SEDAC heat products and Trust for Public Land heat layers were not inventoried.
- **Lead:** system-level drinking water data only; no address-level lead service line inventory was found.
- **Pipelines and wells:** PHMSA national GIS is restricted; well data is commercial (Enverus) or state-by-state.
- **ELAPSE / de Hoogh European LUR surfaces** and the India SAANS portal have no verified public download.
- **Most climate grids** (PRISM, Daymet, gridMET, ERA5, CHIRPS) need an aggregation step to tract or admin units; only nClimGrid ships tract/county tables.
- **Licence** is blank for 288 rows, mostly NSO and catalog-listed products.
- **Versions filled from product knowledge** rather than a page: several CLMS and JRC rows and a few US rows say so in notes; treat them as unverified.

## Problems hit

- **Withdrawn or moved (kept, flagged):** EPA EJScreen (epa.gov/ejscreen 404; PEDP mirror recorded), CEQ CEJST (removed January 2025; screening-tools.com mirror, URL unverified), HIFLD Open (deactivated 2025-08-26; DataLumos mirror), NOAA Billion-Dollar Disasters (retired May 2025; Climate Central continues), NASA SEDAC (CIESIN contract ended 2025-04-30; ~350 collections frozen on Earthdata Cloud behind Earthdata Login; CIESIN rescued 234+ to a Harvard Dataverse collection in October 2025), CDC heart and stroke atlas moved, CDC diabetes surveillance URLs 404, 500 Cities page 404 (data still on data.cdc.gov), Minority Health SVI rebranded as Minority Health Index (county only), COVID community levels discontinued, GDL Area Database withdrawn March 2025, NHD retired 2023, LCDv1/ISD ended August 2025, OpenFEMA NFIP claims v2 deprecated, Canadian CIMD superseded (2025).
- **Blocked fetches (rows kept at medium or low):** 403 or JavaScript-only on about 55 rows, including HDX (every page), DHS, IHME/GHDx, UNHCR, MICS, CCKP, ESPON, OECD, WFP, AHRQ, openICPSR, Eviction Lab, diversitydatakids, FCC, HUD User (empty render), BTS, TPL, Zillow, StatCan, IBGE, NHS Digital, Otago, data.gov.in, BPS, PSA, LandScan, Meta, figshare, PreventionWeb, Harvard Dataverse, GRID3, Africapolis, GloFAS/EFAS, MAP, Statbel (CAPTCHA). epa.gov fails TLS in the fetcher (worked around with curl). DNS failures: nomisweb, BKG, geodane, stats.gov.cn, globio.info, noggateway.org. TLS errors: KNBS, UBOS, GSS, censusindia, BBS, NISR, WHO Europe, TAP, heat.gov, HHEAR. HTTP 418 from gob.pe.
- **Down for maintenance on the day:** CDC Tracking Data Explorer and API help; CDC Heat & Health Tracker; SDWIS lead-service-line report (502).
- **data.gov** CKAN API returned 404 for every query and the HTML search ignored filters, so data.gov rows came from targeted web searches instead of a tag sweep.
- **AWS Open Data** slugs changed or removed for Daymet, Ookla, Allen Coral Atlas, ERA5, Overture.
- **Registration walls:** all Earthdata, CDS/ADS, EM-DAT, LandScan, IHME, DHS, UK Data Service, NHGIS, PCCF (licensed). **API keys:** FIRMS, OpenAQ v3, WAQI (no-archiving terms), AirNow, Socrata (CDC).
- **Licence conflicts noted:** FAO GAUL (CC BY vs non-commercial), GISCO NUTS (Eurostat CC BY vs EuroGeographics clause); non-commercial: Berkeley Earth, GEM, IHME, GRanD, E-OBS, Relative Wealth Index.
- **Rate limits:** the run itself hit the Claude session limit once; three sweeps paused and resumed, and one (global earth observation) restarted from its notes. No rows were lost from saved fragments.

## Suggested next pass

1. **Verification.** Re-check the 92 low rows and the 55 fetch-blocked medium rows from a browser, not the fetcher: most blocks were bot protection, not dead data. Resolve the two "possible duplicate" families that share landing pages and decide whether sub-national seeds (26 Miami-Dade, 12 Huayhuash) stay as rows or fold into their parent products.
2. **Enrichment.** Fill license, versions, update_cadence and access_url first (the emptiest useful fields). Read the Datasets tab for CLMS/JRC products and the HUD User pages whose vintages are unconfirmed.
3. **Health-relevance scoring.** Add a score column (for example 0-3) for plausible linkage to patient residence, and a resolution column (finest unit) so the 2026-10-01 open question "county-only in scope?" can be answered from data.
4. **Map to `inventory.csv`.** The columns correspond one to one (`dataset_name`→`title`, `organization`→`publisher`, `theme`→`domain`, `site_url`→`landing_url`, `access_type`→`access`, `geography_units`→`geography`, `evidence_url`→`evidence`); `in_gaia` comes from the `gaia_catalog` tag and `recipe_health` from the deployment logs. Promote curated rows after verification, not before.
5. **Fill the gaps above:** food access outside the US, sub-national health outcomes, SEDAC heat, TPL heat, Esri Living Atlas, state cancer registries (Utah, Iowa IBIS portals), Chicago Health Atlas, the unreached NSOs.

## Pass 2 (2026-10-20, later the same day): scripted catalog-API listing

**This assumes:** Robert's follow-up asked to expand via APIs, built environment and civic point data, highways, clinic locations, historical fires and international sources. Seven themed web sweeps were launched for those and then stopped at Robert's request to protect usage before any had saved rows. Only the scripted part completed.

**Output:** `harvest-2026-10-20-api-catalogs.csv`, 2691 rows, same 21 columns, kept separate from the curated harvest because every row is a catalog listing (confidence=medium) produced by keyword queries, not a page read by a person or agent. Theme is inferred from the query keyword or title and should be treated as a hint.

Rows by source: google_earth_engine 658, aws_open_data 445, hdx 381, data.europa.eu 209, earthdata_cmr 197, socrata_us 175, planetary_computer 128, data.gouv.fr 101, data.gov.ie 93, data.gov.au 80, socrata_colombia 78, open.canada.ca 53, opendevelopmentmekong 46, data.gov.uk 38, earth_search_aws 9.
Rows by theme (inferred): environment 959, built_environment 516, climate_hazard 504, health_outcome 138, sdoh 136, demographics 119, other 84, toxics 81, boundaries 81, food_access 73.
Coverage class: blank 1473, international 1037, US 181 (blank coverage is common for NASA CMR, STAC, Earth Engine and AWS listings; it was not inferred).

**How:** themed keyword queries (air quality, flood, deprivation, roads, health facilities, boundaries, and so on) against CKAN (HDX, data.gov.uk, open.canada.ca, data.gov.au, data.gov.ie, Open Development Mekong), data.europa.eu, Socrata discovery (US portals and datos.gov.co), data.gouv.fr; full collection listings from NASA CMR (SEDAC provider plus themed searches), Planetary Computer and Earth Search STAC, the Earth Engine STAC catalog (non-deprecated) and the AWS Open Data registry (geospatial, climate, health and sustainability tags). Rows were filtered to geospatial formats or geo-typed columns where the API exposed them, deduplicated by title, and titles already in the main harvest were dropped. No data files were downloaded. Scripts: `scripts/api_harvest.py` (the catalog queries) and `scripts/merge.py` (fragment merge, id aliases, duplicate flags).

**Caveats:** Earth Engine (658) and AWS (445) listings include many scene-level and model products of low residence-linkage value; the per-source caps did not apply to them. HDX rows (381) are mostly per-country administrative, population, health-facility and settlement layers, which is the international breadth Robert asked for. Socrata rows carry the portal domain in `sub_organization` or notes; many are city or state agency layers (clinics, crime, 311, parcels).

**Not done (stopped for usage):** the themed sweeps for transport and highways, health facility registries (US CMS/NPPES/SAMHSA and national master facility lists), historical wildfire and hazard event records, industry/energy/civic point layers, US state agency data, non-US environment and mapping agencies, and member-layer enumeration of NaNDA, EnviroAtlas, GHSL, CLMS, TIGER, OS Open Data and GISCO. The briefs for all seven exist in this session's transcript and can be rerun one at a time; each cost roughly 180-270k tokens in pass 1.

**Suggested handling:** score the API file for health relevance and resolution before merging any of it into the main harvest; the HDX, Socrata, data.europa.eu and national CKAN rows are the most useful, the Earth Engine and AWS rows the least.

## Aggregated file (2026-10-20, Robert's request)

Both passes are now in one file, `harvest-2026-10-20.csv`: 3337 rows. Confidence: high 316, medium 2929, low 92. Theme: environment 1092, climate_hazard 598, built_environment 596, sdoh 217, demographics 186, health_outcome 182, boundaries 139, other 128, toxics 113, food_access 86. Coverage class: blank 1473, international 1192, US 459, global 213 ("blank" is mostly Earth Engine, AWS, STAC and CMR listings whose coverage was not inferred). The `source_of_listing` column separates the two passes: pass-2 rows are those with source `hdx`, `data.europa.eu`, `socrata_us`, `socrata_colombia`, `data.gov.uk`, `open.canada.ca`, `data.gov.au`, `data.gov.ie`, `opendevelopmentmekong`, `data.gouv.fr`, `earthdata_cmr`, `planetary_computer`, `earth_search_aws`, `google_earth_engine` or `aws_open_data` and confidence medium. The separate `harvest-2026-10-20-api-catalogs.csv` was moved to `_to_delete/`.

## Duplicate sweep (2026-10-20)

After aggregation the file was swept for duplicates (`scripts/dedupe.py`; report in `harvest-2026-10-20-dedupe-report.md`). Exact duplicates were merged and removed, probable duplicates flagged in two new columns (`dup_group`, `dup_role`). The file now has 3160 rows. The Socrata rows' coverage was also corrected: the Socrata discovery API spans every Socrata portal worldwide, so coverage is now inferred from the portal domain (US, CO, AU, CA, GB, ...) or left blank, and those rows are tagged `socrata_discovery`.
