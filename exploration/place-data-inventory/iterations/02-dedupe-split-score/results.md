# Next pass, steps 1-3: split, gaiaCatalog link, scoring (2026-10-20)

**This assumes:** the de-duplicated harvest (3,160 rows) is the input; the gaiaCatalog clone is at its 2026-10-20 head (113 datastore folders); scores follow the rubric in the brief using only what each row says, with the hand judgements listed in `scripts/split_link_score.py` (OVERRIDES). Nothing was verified against a live page in this step.

## Row counts

| File | Rows | Note |
|---|---|---|
| input `harvest-2026-10-20.csv` | 3160 | unchanged; backup in `_to_delete/harvest-2026-10-20-before-split.csv` |
| `inventory-working.csv` | 594 | 584 pass-1 rows + 10 rows added from gaiaCatalog folders that matched nothing |
| `leads-2026-10-20.csv` | 2576 | pass-2 catalog listings, with `lead_status` |
| check | 3160 | pass-1 + pass-2 = input (3160) |
| `gaia-link-2026-10-20.csv` | 113 | one row per catalog folder |

## Lead status

| lead_status | Rows |
|---|---|
| stub | 2254 |
| imagery_or_model | 269 |
| promote_candidate | 43 |
| duplicate_of | 10 |

Of the 10 duplicates, each names the pass-1 id it duplicates. Promote candidates have a geography unit and a date range and do not look like imagery or model output; stubs lack one or both.

## gaiaCatalog link

| match_method | Folders |
|---|---|
| url | 62 |
| publisher_product | 38 |
| new_row | 12 |
| name | 1 |

Folders: 113. Matched to an existing working row: 101. Added as new rows: 12 folders into 10 product rows (the three synthetic surfaces fold into one). Working rows with `in_gaia` set: 42.

Folders without JSON-LD (folder name only): mdc_2013_2022_lst_30m, mdc_2021_hylo, tz_2022_nbs.

Flagged in `gaia-link` notes: the five `synthetic_*` benchmark folders, `mdc_5000_addresses_normalized` (test address list) and a person-level registry layer (name withheld pending a WG decision) (sensitive person-level layer).

New rows added from the catalog (id, name, folders):

- `gaia_bogota_2019_estratos_manzana_dane`: Estratos Socioeconómicos de Bogotá Según Manzanas (bogota_2019_estratos_manzana_dane)
- `gaia_fl_superfund_waste_cleanup_sites`: Florida Superfund Waste Cleanup Sites (fl_superfund_waste_cleanup_sites)
- `gaia_hh_rios_ana`: Ríos Huayhuash (hh_rios_ana)
- `gaia_mdc_5000_addresses_normalized`: Miami-Dade County 5000 Addresses Normalized (Random) (mdc_5000_addresses_normalized)
- `gaia_mdc_brownfield_site`: Miami-Dade Brownfield Sites (mdc_brownfield_site)
- `gaia_mdc_streets`: Miami-Dade Streets (mdc_streets)
- `gaia_synthetic_road_proximity`: Simulated near-road exposure increment (distance bands) (synthetic_road_proximity)
- `gaia_synthetic_surface`: Simulated exposure surfaces (correlation length 100 m, 1 km, 10 km) for the OHDSI GIS benc (synthetic_surface_100m;synthetic_surface_10km;synthetic_surface_1km)
- `gaia_synthetic_tract_ses`: Simulated census tract SES index for the OHDSI GIS benchmark (synthetic_tract_ses)
- `gaia_us_nuclear_power_plants`: US Nuclear Power Plants (us_nuclear_power_plants)

Working rows holding the most catalog folders:

- `global_nasa_viirs_vnp46a4`: 23 folders (egom_2012_viirs_vnp46a4, egom_2013_viirs_vnp46a4, egom_2014_viirs_vnp46a4, egom_2015_viirs_vnp46a4, egom_2016_viirs_vnp46a4, egom_2017_viirs_vnp46a4, ...)
- `us_cdc_svi`: 11 folders (fl_2018_svi_tract, fl_2020_svi_county, fl_2020_svi_tract, fl_2022_svi_tract, ma_2018_svi_tract, ma_2020_svi_tract, ...)
- `us_census_tiger_line`: 10 folders (fl_2019_tl_tract, fl_2020_tl_tract, fl_2021_tl_tract, fl_2022_tl_cousub, fl_2022_tl_tract, fl_2023_tl_tract, ...)
- `global_openstreetmap`: 10 folders (hh_glaciares_osm, hh_red_vial_osm, hh_rios_arroyos_osm, hh_rutas_pie_osm, tt_ferry_routes, tt_populated_places, ...)
- `us_census_acs_5year`: 8 folders (fl_2021_acs_5yr_tract_fsr, mdc_2019_acs_5yr_tract_dvmt, mdc_2020_2024_acs_5yr_trends_tract_dvmt, mdc_2020_acs_5yr_tract_dvmt, mdc_2021_acs_5yr_tract_dvmt, mdc_2022_acs_5yr_tract_dvmt, ...)
- `us_census_tiger_line_county`: 4 folders (us_2019_county_tl, us_2020_county_tl, us_2022_county_tl, us_2023_county_tl)
- `gaia_synthetic_surface`: 3 folders (synthetic_surface_100m, synthetic_surface_10km, synthetic_surface_1km)
- `us_fnai_florida_managed_areas`: 2 folders (fl_2026_flma, mdc_2026_flma)
- `global_copernicus_era5_land`: 2 folders (hh_dem_copernicus, tz_1984_copernicus_avg_temp)
- `global_nasa_srtmgl1_v003`: 2 folders (hh_dem_srtm, tz_magu_dem_srtm)
- `us_um_gdsc_mdc_derived_layers`: 2 folders (mdc_2013_2022_lst_30m, mdc_2021_hylo)
- `us_census_zcta`: 2 folders (mdc_2020_zcta, us_2020_zcta)

## Scores

### health_relevance x gaia_fit

| health_relevance | now | needs_aggregation | needs_raster | not_linkable | unknown | Total |
|---|---|---|---|---|---|---|
| 3 | 117 | 63 | 90 | 38 | 32 | 340 |
| 2 | 50 | 22 | 56 | 9 | 17 | 154 |
| 1 | 37 | 8 | 6 | 2 | 19 | 72 |
| 0 | 2 | 2 | 7 | 2 | 1 | 14 |
| unknown | 0 | 0 | 0 | 5 | 9 | 14 |
| Total | 206 | 95 | 159 | 56 | 78 | 594 |

### finest_unit x theme

| finest_unit | environment | climate_hazard | built_environment | sdoh | demographics | health_outcome | boundaries | toxics | food_access | other | Total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| point | 20 | 10 | 20 | 12 | 0 | 0 | 4 | 17 | 2 | 6 | 91 |
| unknown | 3 | 2 | 18 | 13 | 4 | 6 | 10 | 4 | 3 | 27 | 90 |
| postcode_small_area | 2 | 2 | 2 | 14 | 21 | 2 | 15 | 0 | 0 | 2 | 60 |
| tract | 5 | 1 | 2 | 14 | 2 | 8 | 6 | 2 | 3 | 1 | 44 |
| county | 4 | 3 | 0 | 4 | 3 | 10 | 5 | 3 | 1 | 1 | 34 |
| country | 1 | 2 | 0 | 3 | 7 | 11 | 0 | 0 | 2 | 2 | 28 |
| grid_1km | 16 | 3 | 4 | 0 | 2 | 1 | 1 | 0 | 0 | 0 | 27 |
| grid_ | 8 | 4 | 0 | 0 | 2 | 1 | 2 | 0 | 0 | 3 | 20 |
| block | 0 | 1 | 1 | 1 | 9 | 0 | 5 | 1 | 0 | 0 | 18 |
| grid_30m | 7 | 4 | 4 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 16 |
| zcta_zip | 1 | 0 | 1 | 9 | 0 | 1 | 3 | 0 | 0 | 1 | 16 |
| block_group | 2 | 0 | 3 | 5 | 3 | 0 | 1 | 0 | 0 | 1 | 15 |
| admin1 | 0 | 4 | 0 | 3 | 0 | 2 | 1 | 4 | 0 | 0 | 14 |
| polygon | 3 | 2 | 4 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 10 |
| grid_0.25deg | 3 | 7 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 10 |
| grid_100m | 2 | 0 | 0 | 0 | 6 | 0 | 0 | 0 | 0 | 1 | 9 |
| admin2 | 0 | 3 | 0 | 1 | 2 | 0 | 2 | 0 | 0 | 0 | 8 |
| grid_0.5deg | 2 | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 7 |
| grid_0.1deg | 2 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 6 |
| grid_10m | 3 | 0 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 6 |
| line | 1 | 0 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 5 |
| grid_4km | 0 | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 5 |
| grid_500m | 2 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 4 |
| grid_0.01deg | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 4 |
| grid_5km | 0 | 2 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 4 |
| grid_30arcsec | 1 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 4 |
| grid_1m | 2 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |
| grid_300m | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |
| grid_250m | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |
| grid_810m | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 2 |
| grid_0.05deg | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| grid_5arcmin | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| address | 0 | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 2 |
| grid_50m | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| grid_12km | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_10km | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_8deg | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_24deg | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_4m | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_2.5arcmin | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_3.5km | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_375m | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_9km | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_0.75deg | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_5.5km | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_250km | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_1.67km | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_8km | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_12deg | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_2m | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_200m | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_3arcsec | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_25m | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| grid_20m | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |

### record_type

| record_type | Rows |
|---|---|
| dataset | 559 |
| portal | 13 |
| api | 12 |
| tool | 10 |

## Verification shortlist for step 4: 167 rows

Rows with health_relevance >= 2 and gaia_fit = now. By theme: sdoh 50, demographics 38, health_outcome 21, environment 16, built_environment 13, climate_hazard 12, toxics 10, food_access 4, other 2, boundaries 1. With `in_gaia` set: 8. Low confidence among them: 25.

## Scored unknown

- health_relevance unknown: 14 (mostly theme 'other' rows that are catalogs, cohorts or base layers without a scoring keyword).
- gaia_fit unknown: 78 (no geography unit recorded, or a vector format with no unit).
- finest_unit unknown: 90 (geography_units blank or not parseable).

Examples of health_relevance unknown: `us_urban_institute_data_catalog`; `us_harvard_dataverse`; `global_ciesin_harvard_dataverse_sedac_collection`; `global_worldbank_data_catalog`; `global_ihme_ghdx`; `eu_data_europa_eu`; `us_niehs_pegs`; `us_niehs_hhear`; `eu_expanse_project`; `eu_ehen_human_exposome_network`; `nl_exposome_nl`; `eu_athlete`; `fr_iarc_exposome_explorer`; `global_who_urban_health_index`.

Caveats: `finest_unit` adds the value `polygon` for vector layers whose unit is a feature polygon (parks, flood zones, managed areas), which the rubric did not list; `health_relevance` is rule-based from theme and keywords, and the hand overrides cover the seed rows and the new catalog rows only. Step 4 (verification) was not started.