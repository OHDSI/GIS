# Open checks on the working-group request rows (2026-10-29, browser)

The four checks left open by `exploration-1.5-report-2026-10-29.md`. Each page was opened in the Claude desktop browser pane; no files were downloaded.

**The inventory CSV has not been changed**, because Prompt 2 is running. Apply these findings in the next refine step, or fold them into the issue comments.

| Request | Row | Check | Finding | Evidence |
|---|---|---|---|---|
| gaiaCatalog#29 EJI | `us_cdc_eji` | Vintage and formats (the page rendered empty for scripts) | **Confirmed.** Years **2022 and 2024** (the 2024 update adds a Climate Burden Module and an EJI + Climate rank). Geography: United States or any single state; **census tract** level, with rankings always national. Formats: **Geodatabase** (embedded tract polygons) or **CSV** (GEOID, so the geometry comes from Census TIGER tracts). | https://eji.cdc.gov/dfe/eji_data_download_dfe.html ; https://www.atsdr.cdc.gov/place-health/php/eji/environmental-justice-index-2024-update.html |
| gaiaCatalog#23 CyAN | `global_nasa_cyan` | Is a login needed? | **Not settled.** The CyAN File Search (NASA OB.DAAC) lists files openly, by date, period (daily or weekly), product and tile. Download authentication is not stated on the pages read. NASA DAACs commonly require a free Earthdata Login (unconfirmed). Also confirmed: 300 m, CONUS and Alaska tiles; MERIS 2002-2012, OLCI 2016 to present; GeoTIFF daily and 7-day composites; release notes for Version 6 (Aug 2025). | https://www.earthdata.nasa.gov/data/projects/cyan ; https://oceandata.sci.gsfc.nasa.gov/api/cyan_file_search/ |
| gaiaCatalog#38 UCMR 3 | `us_epa_ucmr3_occurrence` | The ZIP-code file | **Partly.** UCMR 3 data are available as three zips: all, by state, and by method classification (`ucmr3-occurrence-data*.zip`, re-posted April 2024). 30 contaminants plus 5 extras. The page does not list the files inside the zips, so the ZIP-codes-served file is not confirmed from the page; its presence rests on the request issue. | https://www.epa.gov/dwucmr/occurrence-data-unregulated-contaminant-monitoring-rule |
| gaiaCatalog#32 AQS sites | `us_epa_aqs_sites_monitors` | Coordinate columns | **Not checked.** Confirming them needs the file opened, and we don't download data files. | - |

## Found along the way

- **UCMR 5 (2023-2025)**: monitoring for **29 PFAS and lithium**. The final dataset was released in **August 2026**. Same packaging as UCMR 3 (text-file zips), plus a Data Finder that filters by water system, state and contaminant. It is a strong candidate for the drinking-water anchor, and newer than the UCMR 3 data the working group asked for. Not yet in the inventory.

## UCMR 5: quick evaluation (2026-10-29, browser)

| Field | Finding |
|---|---|
| What | Drinking-water results for **29 PFAS and lithium**, collected 2023-2025. The final dataset was released in August 2026 (Data Summary report July 2026; page updated 15 Oct 2026) |
| Who is covered | All community and non-transient non-community water systems serving 3,300 or more people, plus a nationally representative sample of smaller systems |
| Unit and key | **Public water system** (PWS ID) and sampling location; filters for state and EPA region. No geography stated, so: `geometry_source = reference_specific`, dependency **water-system service areas (TBD)**, the same as UCMR 3 and SDWIS |
| Access and format | Open: text-file zips (all, by state, by method classification) and an interactive Data Finder with download. It also includes EPA's location averages compared against the new PFAS drinking-water standards (technical assistance only, not compliance) |
| Licence | US federal work (WG rule) |
| Suggested tier | **Silver**, capped by the geometry dependency. Health relevance is high (PFAS); the drinking-water anchor |
| Evidence | https://www.epa.gov/dwucmr/fifth-unregulated-contaminant-monitoring-rule-data-finder ; https://www.epa.gov/dwucmr/occurrence-data-unregulated-contaminant-monitoring-rule ; https://www.epa.gov/dwucmr/data-summary-fifth-unregulated-contaminant-monitoring-rule |

**Implication:** all four EPA drinking-water rows (UCMR 3, UCMR 5, the general UCMR row and SDWIS) wait on one geometry: water-system service-area boundaries. Finding and verifying that dataset is the single step that would unlock the drinking-water anchor.
