# Browser sample of "Browser needed" rows (2026-10-28)

25 rows were sampled from `browser-queue-2026-10-23.csv`: the shortlist rows first, then a spread across domains. Each was opened in a real browser (the Claude desktop browser pane). Nothing was downloaded, there were no sign-ins, and CAPTCHAs were not attempted. Row detail is in `browser-sample-2026-10-28.csv`.

## Counts

| Result | Rows |
|---|---|
| Sampled | 25 (2 already-trimmed HDX rows skipped, so 23 visited) |
| **Opened fine in a browser** | **18 of 23 (78%)** |
| Bot challenge (Cloudflare CAPTCHA) | 1 (NRDC) |
| Sign-in required or item gone | 1 (HUD Public Housing Developments, ArcGIS item) |
| Page not found (404 in a browser too) | 1 (CIESIN PM2.5 components 50 m) |
| Host unreachable | 2 (sedac.ciesin.columbia.edu, elapseproject.eu) |
| Certificate warning | 0 |

## What the opened pages showed

- **Would-be Gold or Silver: 13 of 23.**
  - **Gold:** HUD CHAS (block group, 2018–2022). COI 3.0 (tract, 2012–2024) is Silver until its license is confirmed.
  - **Silver:** AHRQ CLH (the replacement for SDOH), Eviction Lab, IHME county, HUD FMR, IPEA IVS, the SEDAC PM2.5 Dataverse source, COVID Community Levels (archived), and four point layers needing aggregation: the two CMS files, HIFLD Hospitals and CAMPD.
- **Should be trimmed or reclassified: 5.**
  - FAA noise maps: per-airport PDFs only.
  - CDC Heat & Health Tracker: a dashboard, no download.
  - HDX Kenya ICU beds: a one-day 2020 snapshot.
  - Enverus: commercial.
  - HUD eGIS: a portal, not a dataset.
- **Licenses:**
  - **Open, as stated on the page:** 2, both CC BY.
  - **US government, public domain assumed but not stated:** 7.
  - **Restricted:** 3. IHME is non-commercial, Eviction Lab has a cite-as requirement, Enverus is commercial.
  - **Not seen on the landing page:** 5.

## Takeaways

1. **"Browser needed" mostly means bot-blocking, not dead links.** About 4 in 5 open fine in a person's browser. For the remaining ~105 queue rows, expect roughly 80 to open, roughly 50–60 to be usable, and 15–25 to be trims.
2. **The page read changes the row as often as the link check does.** Several rows needed a substantive correction:
   - AHRQ SDOH has become the CLH Database.
   - The DataLumos "HIFLD Hospitals" mirror is titled *Trauma Levels*.
   - The COVID Community Levels data is discontinued.
   - IHME is non-commercial.
3. **The SEDAC problem is real.** The SEDAC host itself fails in a browser, and a CIESIN page is 404. The Harvard Dataverse copy of the SEDAC PM2.5 data (a gaiaCatalog source) opens fine under CC BY 4.0. For Tim: the Dataverse source is OK; check NASA Earthdata for anything still pointing at sedac.ciesin.columbia.edu.
4. **Licenses are rarely on landing pages.** Confirming the license needs a second click (terms, about, or a metadata page), so budget for it in any promotion step.

## Suggested status changes

| id | From | To |
|---|---|---|
| us_ahrq_sdoh_database | Browser needed | Silver (repoint to CLH) |
| us_brandeis_coi | Browser needed | Silver → Gold once license confirmed |
| us_hud_chas | Browser needed | Gold |
| us_hud_fair_market_rents, us_eviction_lab, us_ihme_county_mortality_life_expectancy, br_ipea_ivs, us_cdc_covid_community_levels | Browser needed | Silver |
| us_cms_hospital_general_information, us_cms_nursing_home_provider_info, us_hifld_hospitals, us_epa_campd_power_plant_emissions | Browser needed | Silver (needs_aggregation) |
| global_sedac_pm25_countries_urban_1998_2016 | Browser needed | Silver |
| us_faa_airport_noise_exposure_maps, hdx_kenya_number_of_hospital_icu_beds_per_county, us_enverus_well_data | Browser needed | Trimmed |
| us_cdc_heat_health_tracker | Browser needed | Bronze (tool, not dataset) |
| us_sedac_amini_pm25_components_50m, us_sedac_di_pm25_1km_2000_2016, eu_elapse_lur_surfaces, us_hud_public_housing_developments | Browser needed | Failed (look for a new home) |
| us_nrdc_lead_service_lines | Browser needed | Browser needed (person check; CAPTCHA) |
