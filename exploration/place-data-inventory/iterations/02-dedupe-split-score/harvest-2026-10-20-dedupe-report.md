# Harvest 2026-10-20: duplicate sweep and breakdowns

**This assumes:** the aggregated harvest (pass 1 sweeps plus pass 2 catalog-API listings). Duplicates were judged on titles, publishers and URLs only; no page was re-read. Exact duplicates were merged and removed; everything fuzzier is flagged, not removed, because the same title in two catalogs can still be two products (a mirror vs the original, or a national clip of a global grid).

## What was done

- Rows before: 3337. Removed as exact duplicates: 177 (merged into the kept row; listed in `_to_delete/harvest-removed-duplicates.csv` with the id they were merged into). Rows after: 3160.
- Flagged, not removed: 354 rows in 174 groups, via two new columns at the end of the CSV: `dup_group` (shared key, D0001...) and `dup_role` (primary = best confidence and most complete; alternate). The notes column names the other members and the reason (same title in several listings; same access URL; near-identical title, same publisher).
- Rule for a later pass: keep the primary, and either drop the alternates or record them as additional distributions of the primary (`access_url`), unless a read of the pages shows two genuinely different products.

## Flagged groups by reason

| Reason | Flagged rows |
|---|---|
| near-identical title, same publisher | 260 |
| same access URL | 51 |
| same title in several listings | 43 |

### Largest flagged groups

| Group | Rows | Example title | Listings |
|---|---|---|---|
| D0003 | 5 | US Building Footprints | data.gov.au, open.canada.ca, publisher_site, socrata_discovery |
| D0020 | 3 | Daily County-Level PM2.5 Concentrations, 2001-2022 | data.gov, gaia_catalog |
| D0013 | 3 | Population Density | data.europa.eu, data.gov.au, opendevelopmentmekong |
| D0014 | 3 | Street Lighting (sample data) | data.europa.eu, data.gov.au, data.gov.uk |
| D0021 | 2 | American Community Survey 5-Year Data | census |
| D0022 | 2 | EnviroAtlas National Data (metric tables by HUC12, county, tract, bloc | epa |
| D0046 | 2 | Daily and Annual PM2.5 Concentrations for the Contiguous United States | earthdata |
| D0023 | 2 | SatPM2.5 (Satellite-derived PM2.5) global estimates V6.GL.02.04 and V5 | publisher_site |
| D0001 | 2 | HAQAST Sentinel-5P TROPOMI Nitrogen Dioxide (NO2) CONUS Monthly Level  | earthdata, earthdata_cmr |
| D0002 | 2 | U.S. Billion-Dollar Weather and Climate Disasters | noaa, publisher_site |
| D0004 | 2 | United States COVID-19 Community Levels by County (archived) | cdc, socrata_discovery |
| D0024 | 2 | Hospital General Information (Care Compare / Provider Data Catalog) | publisher_site |
| D0005 | 2 | 10m Annual Land Use Land Cover (9-class) | aws_open_data, planetary_computer |
| D0025 | 2 | Chesapeake Land Cover (13-class and 7-class) and Land Use | planetary_computer |
| D0026 | 2 | NOAA MRMS QPE (Multi-Radar Multi-Sensor Quantitative Precipitation Est | planetary_computer |
| D0027 | 2 | Global Roads Inventory Project (GRIP4) | google_earth_engine, publisher_site |
| D0006 | 2 | 2015 Street Tree Census - Tree Data (TreesCount!) | data.gov, socrata_discovery |
| D0047 | 2 | MODIS/Terra Vegetation Indices 16-Day L3 Global 1km SIN Grid V061 (MOD | aws_open_data, earthdata |
| D0028 | 2 | WorldPop Population Counts, individual countries 2015-2030, 100 m (R20 | worldpop |
| D0029 | 2 | Common Operational Datasets - Administrative Boundaries (COD-AB) | hdx |
| D0030 | 2 | Territorial units for statistics (NUTS) - GISCO geodata | eurostat |
| D0007 | 2 | Canadian Index of Multiple Deprivation (CIMD) | open.canada.ca, publisher_site |
| D0008 | 2 | 2021 Population and Housing Census (PHC 2021) | publisher_site |
| D0054 | 2 | Satellite - Ocean Colour - MODIS - 1 day - Chlorophyll-a concentration | aws_open_data |
| D0055 | 2 | Satellite - Ocean Colour - MODIS - 1 day - Diffuse attenuation coeffic | aws_open_data |

## Breakdowns

### Rows by pass and confidence

| Pass | High | Medium | Low | Total |
|---|---|---|---|---|
| pass1_sweep | 313 | 234 | 92 | 639 |
| pass2_api | 3 | 2518 | 0 | 2521 |

### Theme by listing source (rows)

| Source | environment | climate_hazard | built_environment | sdoh | demographics | health_outcome | boundaries | toxics | food_access | other | Total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| google_earth_engine | 617 | 39 | 11 | 1 | 12 | 0 | 1 | 1 | 0 | 2 | 684 |
| aws_open_data | 127 | 161 | 62 | 0 | 12 | 15 | 0 | 1 | 0 | 67 | 445 |
| hdx | 32 | 53 | 97 | 59 | 25 | 52 | 16 | 19 | 25 | 1 | 379 |
| publisher_site | 39 | 37 | 30 | 39 | 41 | 18 | 23 | 8 | 2 | 22 | 259 |
| earthdata_cmr | 28 | 53 | 63 | 0 | 19 | 33 | 0 | 0 | 0 | 0 | 196 |
| data.europa.eu | 23 | 40 | 58 | 33 | 14 | 0 | 0 | 0 | 20 | 0 | 188 |
| socrata_discovery | 21 | 22 | 52 | 9 | 11 | 5 | 20 | 18 | 13 | 0 | 171 |
| planetary_computer | 50 | 52 | 17 | 1 | 0 | 0 | 1 | 0 | 0 | 2 | 123 |
| data.gouv.fr | 12 | 13 | 30 | 10 | 2 | 10 | 8 | 10 | 0 | 0 | 95 |
| data.gov.ie | 10 | 8 | 35 | 1 | 0 | 3 | 11 | 17 | 6 | 0 | 91 |
| data.gov.au | 7 | 13 | 21 | 1 | 3 | 9 | 12 | 7 | 5 | 0 | 78 |
| metadata_template | 1 | 2 | 16 | 4 | 0 | 1 | 6 | 1 | 3 | 9 | 43 |
| open.canada.ca | 1 | 14 | 21 | 4 | 0 | 0 | 2 | 0 | 1 | 0 | 43 |
| data.gov.uk | 4 | 3 | 15 | 0 | 0 | 2 | 5 | 6 | 2 | 0 | 37 |
| opendevelopmentmekong | 2 | 5 | 8 | 2 | 5 | 7 | 4 | 3 | 1 | 0 | 37 |
| earthdata | 20 | 7 | 3 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 31 |
| literature | 8 | 2 | 3 | 4 | 1 | 0 | 0 | 6 | 0 | 6 | 30 |
| epa | 11 | 0 | 1 | 1 | 0 | 0 | 0 | 11 | 0 | 0 | 24 |

### Coverage (first token), top 40

| Coverage | Rows |
|---|---|
| (blank) | 1458 |
| US | 284 |
| global | 155 |
| FR | 113 |
| IE | 102 |
| AU | 85 |
| GB | 80 |
| CA | 70 |
| KH | 37 |
| DE | 30 |
| US-FL-Miami-Dade | 26 |
| EU | 21 |
| US (CONUS) | 20 |
| NGA | 19 |
| KEN | 18 |
| IT | 16 |
| CH | 16 |
| PHL | 16 |
| MT | 15 |
| CZ | 14 |
| ETH | 14 |
| PE | 12 |
| EUROPE | 12 |
| BGD | 12 |
| SDN | 12 |
| NL | 11 |
| AT | 10 |
| BE | 9 |
| IND | 9 |
| EGY | 8 |
| NPL | 8 |
| MWI | 7 |
| AFG | 7 |
| SOM | 7 |
| ZWE | 6 |
| UGA | 6 |
| ES | 5 |
| ECU | 5 |
| LKA | 5 |
| HTI | 5 |

### Access type

| Access type | Rows |
|---|---|
| open_download | 1816 |
| registration | 932 |
| api | 311 |
| (blank) | 47 |
| api_key | 22 |
| restricted | 20 |
| request | 12 |

### Top 40 publishers

| Publisher | Rows |
|---|---|
| NASA | 213 |
| NASA Earthdata | 196 |
| MODIS | 173 |
| LANDSAT | 68 |
| COPERNICUS | 54 |
| JRC | 49 |
| World Bank Group | 45 |
| US EPA | 28 |
| FAO | 28 |
| JAXA | 28 |
| Environmental Protection Agency | 27 |
| World Health Organization | 26 |
| U.S. Census Bureau | 21 |
| ISDASOIL | 21 |
| HeiGIT (Heidelberg Institute for Geoinformation Technology) | 21 |
| Humanitarian OpenStreetMap Team (HOT) | 20 |
| Miami-Dade County | 19 |
| [Met Office](https://www.metoffice.gov.uk/) | 19 |
| Food and Agriculture Organization (FAO) of the United Nations | 19 |
| Open Development Cambodia | 19 |
| ECMWF | 18 |
| [Digital Earth Africa](https://www.digitalearthafrica.org/) | 18 |
| UNICEF Data and Analytics (HQ) | 18 |
| LARSE | 17 |
| AODN | 16 |
| APAD | 16 |
| CIESIN | 16 |
| NOAA | 15 |
| City of Chicago | 15 |
| CSP | 15 |
| LANDFIRE | 15 |
| NASA LP DAAC at the USGS EROS Center;Microsoft | 15 |
| Office for National Statistics | 14 |
| OpenDataNI | 14 |
| ESA;Microsoft | 13 |
| ESA | 12 |
| [JRC](https://joint-research-centre.ec.europa.eu) | 12 |
| Oxford Poverty & Human Development Initiative | 12 |
| OCHA Field Information Services Section (FISS) | 12 |
| United Nations Human Settlements Programmes, Data and Analytics Section | 12 |

### Field completeness by pass (percent of rows filled)

| Field | pass1_sweep | pass2_api |
|---|---|---|
| dataset_name | 100% | 100% |
| organization | 100% | 99% |
| sub_organization | 66% | 14% |
| site_url | 99% | 100% |
| access_url | 75% | 60% |
| theme | 100% | 100% |
| variables_examples | 90% | 10% |
| geography_units | 90% | 5% |
| coverage | 100% | 42% |
| temporal | 86% | 28% |
| versions | 61% | 8% |
| format | 96% | 92% |
| access_type | 92% | 100% |
| license | 54% | 60% |
| update_cadence | 70% | 35% |
| source_of_listing | 100% | 100% |
| evidence_url | 99% | 100% |
| confidence | 100% | 100% |
| notes | 99% | 100% |

### Versions and years

- Rows with a `versions` value: 592; with a `temporal` value: 1269.
- Rows whose notes flag a withdrawn, retired, moved or discontinued source: 35.
- Rows noting commercial or paywalled access: 29.
