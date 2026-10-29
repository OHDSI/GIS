# Verification, part A: reachability and URL health (2026-10-21)

Scripted run of `scripts/verify_links.py` over 1018 inventory rows (594 curated, 424 inferred-unit leads), of which 211 are shortlist rows. No pages were read by an agent and no datasets were downloaded. Parts B (content) and C (Gaia readiness) are not done.
Run id `A-20261022T051300Z`; results also appended to `verify-log.csv`.

## Results per check

| Check | pass | warn | fail | n.a. | not_checked |
|---|---|---|---|---|---|
| `chk_link_live` | 731 | 205 | 80 | 2 | 0 |
| `chk_redirect` | 946 | 0 | 0 | 29 | 43 |
| `chk_tls` | 945 | 0 | 9 | 21 | 43 |
| `chk_soft404` | 571 | 157 | 3 | 96 | 191 |
| `chk_withdrawn` | 569 | 0 | 14 | 96 | 339 |
| `chk_access_url` | 623 | 43 | 60 | 292 | 0 |
| `chk_format_match` | 381 | 204 | 4 | 429 | 0 |
| `chk_machine_metadata` | 241 | 232 | 258 | 96 | 191 |
| `chk_persistent_id` | 103 | 631 | 0 | 0 | 284 |
| `chk_archived` | 741 | 45 | 230 | 2 | 0 |

Rows with every applicable A check passing (`all_passing_A`): 36 of 1018 (5 of 211 shortlist rows). Note that `chk_persistent_id` and `chk_archived` rarely pass for catalog records, so this is a strict bar.

## URL health

healthy = live, no soft-404, not withdrawn; moved = live but redirected to another registered domain; degraded = live but a soft-404 warning, a broken access URL or no machine metadata; dead = link fails, or the page is a generic/not-found page, or it says the dataset is withdrawn; blocked = bot protection (401/403/429, or a 202 challenge page with an empty body), robots.txt disallow, or a timeout after retry.

| Group | rows | healthy | moved | degraded | dead | blocked | n.a. |
|---|---|---|---|---|---|---|---|
| All rows | 1018 | 410 | 0 | 306 | 97 | 203 | 2 |
| Shortlist (priority set) | 211 | 103 | 0 | 56 | 22 | 30 | 0 |
| Shortlist: Verify first (curated) | 167 | 85 | 0 | 41 | 18 | 23 | 0 |
| Shortlist: Investigate (leads) | 44 | 18 | 0 | 15 | 4 | 7 | 0 |
| Tier: Curated | 594 | 260 | 0 | 220 | 50 | 62 | 2 |
| Tier: Lead (unit inferred) | 424 | 150 | 0 | 86 | 47 | 141 | 0 |
| Theme: boundaries | 104 | 37 | 0 | 27 | 13 | 27 | 0 |
| Theme: built_environment | 221 | 77 | 0 | 66 | 19 | 59 | 0 |
| Theme: climate_hazard | 121 | 63 | 0 | 37 | 13 | 8 | 0 |
| Theme: demographics | 97 | 39 | 0 | 32 | 7 | 18 | 1 |
| Theme: environment | 140 | 62 | 0 | 53 | 11 | 14 | 0 |
| Theme: food_access | 35 | 5 | 0 | 20 | 3 | 7 | 0 |
| Theme: health_outcome | 90 | 36 | 0 | 14 | 5 | 34 | 1 |
| Theme: other | 48 | 26 | 0 | 14 | 0 | 8 | 0 |
| Theme: sdoh | 103 | 41 | 0 | 33 | 8 | 21 | 0 |
| Theme: toxics | 59 | 24 | 0 | 10 | 18 | 7 | 0 |

## Dead and withdrawn datasets (97)

| id | tier | why | HTTP | Wayback snapshot |
|---|---|---|---|---|
| bd_bbs_census_2022 **(shortlist)** | Curated | link: tls_error (not bypassed) |  | 2026-10-17 |
| de_rki_gisd **(shortlist)** | Curated | link: HTTP 404 | 404 | none |
| gb_ons_census_2021_nomis **(shortlist)** | Curated | link: dns_failure: HTTPSConnectionPool(host='www.nomisweb.co.uk',  |  | 2026-10-14 |
| global_gdl_area_database **(shortlist)** | Curated | withdrawn: body: "Light Dark Auto Area Database Since March 2025, the Area Database is no longer offered on this website. | 200 | 2026-10-14 |
| il_cbs_statistical_areas_ses **(shortlist)** | Curated | soft-404: generic title: "Oops, Something is wrong" -> https://www.cbs.gov.il/en/subjects/Pages/Stat | 200 | none |
| in_orgi_census_2011_pca **(shortlist)** | Curated | link: tls_error (not bypassed) |  | 2026-10-09 |
| ke_knbs_census_2019 **(shortlist)** | Curated | link: tls_error (not bypassed) |  | 2026-10-02 |
| pk_pbs_census_2023 **(shortlist)** | Curated | link: HTTP 404 | 404 | 2026-10-06 |
| ug_ubos_nphc_2024 **(shortlist)** | Curated | link: tls_error (not bypassed) |  | 2026-10-16 |
| us_cdc_diabetes_surveillance **(shortlist)** | Curated | link: HTTP 404 | 404 | 2026-07-26 |
| us_ceq_cejst **(shortlist)** | Curated | withdrawn: body: "rgy, and environmental programs. As of Jan. 22, 2025 , CEQ’s CEJST is no longer available on the White  | 200 | 2026-10-10 |
| us_epa_ejscreen **(shortlist)** | Curated | withdrawn: body: "is an initial reconstruction of Version 2.3 of EPA’s EJScreen. Public access to the tool from EPA was d | 200 | 2026-10-12 |
| us_fema_hazus **(shortlist)** | Curated | withdrawn: body: "es to learn more about the latest version of Hazus. Graphic Hazus 6.1 No Longer Available for Downloads | 200 | 2026-10-17 |
| us_hud_location_affordability_index **(shortlist)** | Curated | link: HTTP 404 | 404 | none |
| us_lake_county_il_cancer_rates **(shortlist)** | Curated | link: HTTP 404 | 404 | 2021-04-04 |
| us_noaa_billion_dollar_disasters **(shortlist)** | Curated | link: HTTP 503 | 503 | 2026-10-17 |
| us_noaa_climate_at_a_glance **(shortlist)** | Curated | link: HTTP 503 | 503 | 2026-10-16 |
| us_philadelphia_heat_vulnerability_by_census_tract **(shortlist)** | Curated | link: HTTP 404 | 404 | 2025-10-16 |
| ie_datagovie_county_development_plan_2025_2031_land_use_zoning_bound **(shortlist)** | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_county_galway_land_use_zonings_cdp_2022_2028 **(shortlist)** | Lead (u | link: HTTP 500 | 500 | 2025-05-11 |
| ie_datagovie_flood_studies_update_fsu_catchment_boundaries_ungauged **(shortlist)** | Lead (u | link: HTTP 500 | 500 | 2026-01-06 |
| ie_datagovie_waste_facility_boundaries **(shortlist)** | Lead (u | link: HTTP 500 | 500 | 2025-11-11 |
| af_oecd_africapolis | Curated | soft-404: redirected to home/search/login: "Africapolis" -> https://africapolis.org/; name tokens 2/ | 200 | 2025-12-07 |
| ca_nrcan_cdem | Curated | withdrawn: body: "levation Model, 1945-2011 This collection is a legacy product that is no longer supported. It may not m | 200 | 2026-10-12 |
| de_bkg_vg250 | Curated | link: dns_failure: HTTPSConnectionPool(host='sg.geodatenzentrum.de |  | none |
| eu_eurostat_gisco_urban_audit | Curated | link: HTTP 404 | 404 | 2026-03-04 |
| fi_statfi_paavo | Curated | link: HTTP 502 | 502 | 2026-10-11 |
| gaia_us_nuclear_power_plants | Curated | link: HTTP 404 | 404 | 2025-03-28 |
| gb_defra_pcm | Curated | soft-404: generic title: "Website Maintenance" -> https://uk-air.defra.gov.uk/maintenance/; name tok | 200 | 2026-10-16 |
| gb_ea_rofrs | Curated | link: HTTP 404 | 404 | 2026-10-11 |
| global_airnow_dos_embassies | Curated | link: HTTP 404 | 404 | 2026-10-15 |
| global_berkeley_earth_temperature | Curated | withdrawn: body: "2025 the 1°x1° resolution time series and gridded products below are no longer being updated as we have | 200 | 2026-10-21 |
| global_globio_grip | Curated | link: dns_failure: HTTPSConnectionPool(host='www.globio.info', por |  | 2026-10-06 |
| global_ihme_lbd_geospatial_estimates | Curated | link: HTTP 404 | 404 | none |
| global_nasa_gldas | Curated | withdrawn: body: "rocessed for the dates 2022-08-81 to 2024-03-01. NLDAS-2 GRIB-1 files no longer updated as of 1 August  | 200 | 2026-10-05 |
| global_pure_earth_lead_pollution | Curated | link: HTTP 404 | 404 | none |
| global_temis_uv_index | Curated | withdrawn: body: "selected locations Overview of all archives versions 1.2-1.4: Data is no longer available Notes on the  | 200 | 2026-10-11 |
| global_undrr_gar_risk_information_exchange | Curated | withdrawn: body: "Download Risk Data and Software Notice: The GAR Atlas Risk Data platform has been decommissioned as of  | 200 | 2026-10-12 |
| global_who_euro_health_information_gateway | Curated | link: tls_error (not bypassed) |  | 2026-10-14 |
| global_yale_yceo_suhi | Curated | link: HTTP 404 | 404 | 2026-10-15 |
| it_istat_basi_territoriali | Curated | link: tls_error (not bypassed) |  | 2026-10-07 |
| it_istat_ivsm | Curated | link: tls_error (not bypassed) |  | 2025-04-07 |
| pe_catastrominero_ingemmet | Curated | link: tls_error (not bypassed) |  | 2025-05-28 |
| pe_centrospoblados_inei | Curated | link: dns_failure: HTTPSConnectionPool(host='arcgis4.inei.gob.pe', |  | none |
| pe_midagri_catastro_rural | Curated | link: tls_error (not bypassed) |  | none |
| pt_ine_bgri | Curated | link: HTTP 502 | 502 | 2026-10-13 |
| us_epa_attains | Curated | withdrawn: body: "ess on general water quality conditions in the United States. ATTAINS Data Archive The ATTAINS Data Arc | 200 | 2026-10-17 |
| us_epa_npl_site_boundaries | Curated | link: HTTP 404 | 404 | 2025-04-29 |
| us_epa_superfund_sems_npl | Curated | withdrawn: body: "rchived Data and Reports CERCLIS was a Superfund data system that EPA decommissioned in 2014 following  | 200 | 2026-10-17 |
| us_mdc_park_facilities | Curated | link: HTTP 404 | 404 | 2025-12-12 |
| us_nasa_nldas | Curated | withdrawn: body: "rocessed for the dates 2022-08-81 to 2024-03-01. NLDAS-2 GRIB-1 files no longer updated as of 1 August  | 200 | 2026-10-17 |
| us_noaa_lcd | Curated | withdrawn: body: "utilized standard U.S. units and obtained its data from obtained its data from the Integrated Surface D | 200 | 2026-10-16 |
| us_usgs_nhd | Curated | withdrawn: body: "023, the NHD was retired. NHD data will continue to be available, but no longer maintained. The most cu | 200 | 2026-10-14 |
| us_walkscore | Curated | link: HTTP 503 | 503 | 2026-10-01 |
| ie_datagovie_administrative_boundaries_and_others_fcc | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_air_quality_index_regions | Lead (u | link: HTTP 500 | 500 | 2026-01-17 |
| ie_datagovie_bring_banks_locations_fcc | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_coco_markets_dlr | Lead (u | link: HTTP 500 | 500 | 2024-12-23 |
| ie_datagovie_constituency_boundaries_generalised_20m_national_electo | Lead (u | link: HTTP 500 | 500 | 2024-04-25 |
| ie_datagovie_constituency_boundaries_national_electoral_boundaries_u | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_constituency_boundaries_ungeneralised_national_electora | Lead (u | link: HTTP 500 | 500 | 2024-04-25 |
| ie_datagovie_district_electoral_divisions_boundaries | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_emep_the_european_monitoring_and_evaluation_programme_a | Lead (u | link: HTTP 500 | 500 | 2023-02-08 |
| ie_datagovie_fire_stations_dlr | Lead (u | link: HTTP 500 | 500 | 2025-10-17 |
| ie_datagovie_flood_studies_update_fsu_stations_gauged_2025 | Lead (u | link: HTTP 500 | 500 | 2026-04-18 |
| ie_datagovie_forest_road_polygons_licence_application_spatial_extrac | Lead (u | link: HTTP 500 | 500 | 2025-10-10 |
| ie_datagovie_gaeltacht_boundaries_ungeneralised_national_administrat | Lead (u | link: HTTP 500 | 500 | 2024-07-14 |
| ie_datagovie_gda_cycle_network_survey_2013 | Lead (u | link: HTTP 500 | 500 | 2024-12-11 |
| ie_datagovie_groundwater_historically_polluted_site_pressures | Lead (u | link: HTTP 500 | 500 | 2026-02-07 |
| ie_datagovie_indicative_greenway_cycle_network | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_industrial_and_waste_emission_facilities | Lead (u | link: HTTP 500 | 500 | 2025-04-20 |
| ie_datagovie_industrial_emissions_ie_and_integrated_pollution_contro | Lead (u | link: HTTP 500 | 500 | 2026-09-14 |
| ie_datagovie_industrial_emissions_ie_facilities | Lead (u | link: HTTP 500 | 500 | 2026-01-23 |
| ie_datagovie_industrial_ie_industrial_ipc_and_waste_facilities | Lead (u | link: HTTP 500 | 500 | 2026-09-18 |
| ie_datagovie_integrated_pollution_control_ipc_sites | Lead (u | link: HTTP 500 | 500 | 2025-05-23 |
| ie_datagovie_ippc_facility_monitoring_points | Lead (u | link: HTTP 500 | 500 | 2025-07-19 |
| ie_datagovie_lake_and_trac_historically_polluted_site_pressures | Lead (u | link: HTTP 500 | 500 | 2026-01-17 |
| ie_datagovie_licence_enforcement_and_monitoring_application_emission | Lead (u | link: HTTP 500 | 500 | 2026-02-01 |
| ie_datagovie_licensed_waste_facilities | Lead (u | link: HTTP 500 | 500 | 2025-05-03 |
| ie_datagovie_luas_stop_locations | Lead (u | link: HTTP 500 | 500 | 2024-12-26 |
| ie_datagovie_luas_stops | Lead (u | link: HTTP 500 | 500 | 2026-01-24 |
| ie_datagovie_national_ambient_air_quality_sites | Lead (u | link: HTTP 500 | 500 | 2025-05-02 |
| ie_datagovie_national_indicative_fluvial_mapping_nifm_river_flood_ex | Lead (u | link: HTTP 500 | 500 | 2025-10-13 |
| ie_datagovie_national_road_network_2013 | Lead (u | link: HTTP 500 | 500 | 2025-10-13 |
| ie_datagovie_new_roads | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_primary_cycle_network | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_province_boundaries_ungeneralised_national_administrati | Lead (u | link: HTTP 500 | 500 | 2024-04-25 |
| ie_datagovie_radiation_monitoring_locations | Lead (u | link: HTTP 500 | 500 | 2025-10-15 |
| ie_datagovie_river_historically_polluted_site_pressures | Lead (u | link: HTTP 500 | 500 | 2026-02-06 |
| ie_datagovie_road_improvements | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_road_schedule | Lead (u | link: HTTP 500 | 500 | 2025-10-09 |
| ie_datagovie_school_warning_signs_sdcc | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_school_warning_vas_signs_2023_fcc | Lead (u | link: HTTP 500 | 500 | none |
| ie_datagovie_tusla_administrative_boundaries | Lead (u | link: HTTP 500 | 500 | 2024-12-24 |
| ie_datagovie_urban_waste_water_snapped_emission_points | Lead (u | link: HTTP 500 | 500 | 2026-01-06 |
| ie_datagovie_waste_emission_points | Lead (u | link: HTTP 500 | 500 | 2025-08-03 |
| ie_datagovie_waste_monitoring_points | Lead (u | link: HTTP 500 | 500 | none |

## Domains that blocked or timed out

| domain | rows | kind | shortlist rows |
|---|---|---|---|
| data.humdata.org | 100 | blocked_bot 100 | 7 |
| data.gov.au | 41 | blocked_robots 41 | 0 |
| www.huduser.gov | 7 | blocked_bot 7 | 4 |
| nanda.isr.umich.edu | 4 | blocked_bot 4 | 4 |
| www.icpsr.umich.edu | 3 | blocked_bot 3 | 3 |
| dataverse.harvard.edu | 3 | blocked_bot 3 | 1 |
| geosnirh.ana.gob.pe | 3 | timeout 3 | 0 |
| www.ibge.gov.br | 2 | blocked_bot 2 | 1 |
| figshare.com | 2 | blocked_bot 2 | 0 |
| hub.worldpop.org | 2 | timeout 2 | 0 |
| sedac.ciesin.columbia.edu | 2 | timeout 2 | 0 |
| psa.gov.ph | 1 | blocked_bot 1 | 1 |
| www12.statcan.gc.ca | 1 | blocked_bot 1 | 1 |
| unhabitat.org | 1 | blocked_bot 1 | 1 |
| datasus.saude.gov.br | 1 | connection error 1 | 1 |
| www.ahrq.gov | 1 | blocked_bot 1 | 1 |
| evictionlab.org | 1 | blocked_bot 1 | 1 |
| www.inspq.qc.ca | 1 | blocked_bot 1 | 1 |
| www.otago.ac.nz | 1 | blocked_bot 1 | 1 |
| www.oecd.org | 1 | blocked_bot 1 | 1 |
| www.gov.scot | 1 | blocked_bot 1 | 1 |
| www.nrdc.org | 1 | blocked_bot 1 | 1 |
| www.idep.gob.pe | 1 | timeout 1 | 0 |
| energydata.info | 1 | blocked_bot 1 | 0 |
| broadbandmap.fcc.gov | 1 | blocked_bot 1 | 0 |
| transit.dot.gov | 1 | blocked_bot 1 | 0 |
| www.bps.go.id | 1 | blocked_bot 1 | 0 |
| climateknowledgeportal.worldbank.org | 1 | blocked_bot 1 | 0 |
| crudata.uea.ac.uk | 1 | connection error 1 | 0 |
| www.dwd.de | 1 | blocked_robots 1 | 0 |
| www.heat.gov | 1 | blocked_bot 1 | 0 |
| volcano.si.edu | 1 | blocked_bot 1 | 0 |
| www.unhcr.org | 1 | blocked_bot 1 | 0 |
| www.ciesin.columbia.edu | 1 | blocked_bot 1 | 0 |
| www.elapseproject.eu | 1 | timeout 1 | 0 |
| podaac.jpl.nasa.gov | 1 | timeout 1 | 0 |
| www.mdpi.com | 1 | blocked_bot 1 | 0 |
| www.waterqualitydata.us | 1 | blocked_robots 1 | 0 |
| wad.jrc.ec.europa.eu | 1 | blocked_bot 1 | 0 |
| mics.unicef.org | 1 | blocked_bot 1 | 0 |
| hhearprogram.org | 1 | timeout 1 | 0 |
| digital.nhs.uk | 1 | blocked_bot 1 | 0 |
| datacatalog.urban.org | 1 | blocked_bot 1 | 0 |
| database.espon.eu | 1 | blocked_bot 1 | 0 |
| www.datalumos.org | 1 | blocked_bot 1 | 0 |
| www.pobal.ie | 1 | timeout 1 | 0 |
| www.enverus.com | 1 | blocked_bot 1 | 0 |

Access URLs answering 401/403/429 or timing out (needs login, key, or bot-protected), by domain: www12.statcan.gc.ca (5), www.icpsr.umich.edu (3), www.openicpsr.org (2), www.datalumos.org (2), hub.worldpop.org (2), psa.gov.ph (1), www.data.gov.in (1), data.census.gov (1), statistics.ubos.org (1), file-khulna.portal.gov.bd (1), api.insee.fr (1), open.data.gov.sa (1), broadbandmap.fcc.gov (1), silastik.bps.go.id (1), climateknowledgeportal.worldbank.org (1).

## Domains that moved (0 rows)

| from | to | rows |
|---|---|---|

## Machine-readable metadata

Of 731 live landing pages, 241 expose machine-readable dataset metadata, 232 have only OpenGraph or Dublin Core tags, and 258 have none that the script recognises. A page can expose more than one kind.

| kind | pages |
|---|---|
| DCAT | 103 |
| schema.org Dataset | 95 |
| CKAN | 63 |
| CMR | 36 |
| ArcGIS Hub (DCAT feed) | 27 |
| Socrata | 18 |
| STAC | 8 |

Persistent identifiers: 103 rows have a DOI or handle on the page or in a URL (27 in the URL itself). A DOI found in page text may belong to a cited paper rather than the dataset; part B should confirm.

## Run time and cost

- Wall time: 5 min; span of checked_at stamps 249 min (first to last row checked, 2026-10-22T01:06:44Z to 2026-10-22T05:15:32Z UTC).
- About 3135 HTTP requests (one landing GET, one Wayback CDX lookup and one robots.txt per domain, plus one HEAD or 1 KB range GET per access URL), across 364 landing domains, at most one request per second per domain.
- Cost: none beyond bandwidth; no LLM calls. The Wayback lookups are the floor (one domain, paced at one request per 2.5 s: about 42 min minimum).
- A monthly re-run of all 1018 rows should take about the same wall time (5 min); it resumes from the partial CSV if interrupted, appends a new run_id to `verify-log.csv` and writes `verify-changes-<date>.md` with every result that changed. Re-running only the shortlist (211 rows) would take about a quarter of that.

## Caveats

- Soft-404 and withdrawal detection are keyword rules on the page text; a `warn` means a person or part B should look, not that the page is wrong.
- `chk_machine_metadata` recognises schema.org Dataset JSON-LD, DCAT markers, CKAN, STAC, CMR, Socrata and ArcGIS Hub pages; other catalog software reads as `fail`.
- Pages behind bot protection (`blocked`) were not retried with other agents or headers; the shortlist ones are in the browser queue. These domains answer HTTP 202 with an empty body (a JavaScript challenge) to this agent and open normally in a browser: data.humdata.org (100), www.huduser.gov (7), dataverse.harvard.edu (3), figshare.com (2), www.gov.scot (1). data.gov.au's robots.txt disallows everything for every agent.
- 5xx answers were retried once after 3 s and count as `dead`, but a 500/502/503 can be an outage on the day: data.gov.ie (47), www.ncei.noaa.gov (2), mapas.ine.pt (1), www.walkscore.com (1), stat.fi (1). Rows re-checked with `--redo-ids` keep the later result; the monthly re-run settles the rest.
- TLS failures are what Python's certificate store reported (expired, self-signed, or an incomplete chain). A browser may accept some of them; they were not bypassed.
- Wayback snapshots come from the CDX API on web.archive.org (latest capture of the exact URL), paced at one request per 2.5 s; the availability API answered 429 to every request.
- Access URLs were probed with HEAD, falling back to a 1 KB range GET. Some servers answer HEAD differently from a real download.
