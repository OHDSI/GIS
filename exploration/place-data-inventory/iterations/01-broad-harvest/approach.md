# Claude Code prompt: first-pass harvest of public place-based datasets

Paste everything below the line into Claude Code, run from the umbrella workspace root (`D:\workspace\gaia`), with web search and fetch enabled.

---

You are building a **first-pass inventory of publicly available, place-based datasets** (data tied to geography that could be linked to where people live) for the OHDSI GIS / Gaia project. This is a broad "big grab". Later steps will parse, deduplicate, verify and curate the list. Breadth matters more than depth right now.

## Do NOT

- Download any datasets. Only read landing pages, catalog listings, API docs and metadata pages.
- Edit anything under `repos/`, or any file outside `docs/discovery/`. The only exception is the `git pull --ff-only` in step 0.
- Commit or push.
- Invent values. If a field isn't stated on a page you actually read, leave it blank.

## Target

About **500 datasets**. Stop at around 500 rows, or sooner if you run out of credible sources. Aim for wide coverage across themes and countries rather than many near-duplicates from one publisher.

## What counts

Any public dataset whose values are attached to geography and could be joined to a residence or location history, including:

- **Environment and air:** PM2.5, ozone, NO2, AQI, monitors, modeled surfaces, satellite products.
- **Climate and hazards:** temperature, heat, precipitation, drought, wildfire smoke, floods, sea level, hurricanes, natural hazard risk.
- **Social determinants:** deprivation, vulnerability and opportunity indices, income, education, housing, eviction, broadband, segregation.
- **Demographics:** census, community surveys, population grids.
- **Built environment:** land use and land cover, green space, NDVI, walkability, roads and traffic, light at night, noise, transit.
- **Food and access:** food environment, access to care, pharmacies, hospitals, travel time.
- **Toxics and industry:** TRI, superfund and contaminated sites, pesticides, water quality, drinking water violations, lead.
- **Area-level health:** small-area disease estimates, mortality, vector and infectious disease surveillance.
- **Boundaries and reference geography:** census units, postal codes, administrative boundaries, gazetteers.
- **International and global:** WHO, World Bank, UN, Copernicus, NASA, ESA, WorldPop, OpenStreetMap-derived layers, national statistics offices (UK ONS, Statistics Canada, Eurostat, ABS Australia, IBGE Brazil, INEGI Mexico, Kenya and Tanzania NBS, and others).

## Step 0: verify the recent growth of gaiaCatalog (do this first)

A colleague reports that gaiaCatalog has grown a lot recently. The local clone was last updated at `830b75a` (2026-10-07, "Quick metadata update"), when `datastore/data/` held 23 dataset folders.

1. Update the clone: `git -C repos/gaiaCatalog pull --ff-only`. This is the only git write allowed, and it is the same as `scripts/bootstrap`. If the pull would not be a fast-forward, stop and report; don't merge.
2. Report:
   - every commit since `830b75a`: SHA, date, author, title;
   - the number of folders in `datastore/data/` before (23) and after;
   - the new folder names, grouped by country and theme;
   - how many new folders have each of the `meta_json-ld`, `meta_dcat`, `meta_etl` files and an `etl/*.sh` script.
3. Spot-check five new entries. For each, does the JSON-LD title match the folder name? Does the landing or download URL in the metadata respond (HEAD request only, no downloads)?
4. Add every catalog dataset (old and new) to the harvest CSV with `source_of_listing = gaia_catalog` and the folder name in `in_gaia`.
5. Put the results in a "gaiaCatalog growth check" section at the top of the summary file.

## Where to look (sweep these, then follow links)

1. **Existing seeds in this workspace (read only):**
   - `repos/gaiaCatalog/datastore/data/*/` (folder names and the `meta_json-ld` titles);
   - `repos/ohdsi-gis-metadata-template` (about 107 records);
   - `docs/discovery/approach.md` (candidate publishers list).

   Mark these rows `source_of_listing = gaia_catalog` or `metadata_template`.
2. **Catalogs of catalogs:**
   - data.gov (geospatial and health tags);
   - CDC (EPHTN, PLACES, SVI/EJI pages);
   - EPA (AirData, EnviroAtlas, TRI);
   - NASA Earthdata and SEDAC;
   - NOAA NCEI;
   - USGS;
   - Census (ACS, TIGER, CBP);
   - USDA ERS;
   - FEMA;
   - HUD;
   - NaNDA / ICPSR;
   - Neighborhood Atlas (ADI);
   - diversitydatakids (COI);
   - Copernicus (CAMS, C3S, CLMS);
   - ESA;
   - WorldPop;
   - Humanitarian Data Exchange (HDX);
   - World Bank Data Catalog;
   - WHO GHO;
   - Global Burden of Disease (GBD) geospatial;
   - GADM;
   - geoBoundaries;
   - Eurostat GISCO;
   - national statistics office open-data portals;
   - Google Earth Engine data catalog (listing only);
   - AWS Open Data Registry (geospatial tags);
   - Planetary Computer catalog (listing only).
3. **Literature pointers:** review articles on geospatial exposure models and exposome data resources. Only add datasets named there if you can reach the publisher's landing page.

## One row per dataset, not per release

Put releases, versions and years in the `versions` and `temporal` columns. Different products from the same publisher get separate rows. For example, SVI and EJI are two rows; SVI 2018, 2020 and 2022 is one row.

## Output

Write `docs/discovery/harvest-2026-10-20.csv` (UTF-8, comma-separated, quote every field). Use these columns, in this order. Inside a cell, separate list items with `;`.

| Column | What to put |
|---|---|
| `id` | Short slug: country_publisher_product, for example `us_cdc_svi`, `gb_ons_imd`, `global_worldpop_population` |
| `dataset_name` | The publisher's title |
| `organization` | Publisher or owner organization |
| `sub_organization` | Agency, program or lab, if stated |
| `site_url` | Landing page you actually read |
| `access_url` | Download, API or service endpoint page, if separate |
| `theme` | One of: environment, climate_hazard, sdoh, demographics, built_environment, food_access, toxics, health_outcome, boundaries, other |
| `variables_examples` | 2–5 example variables, as named by the publisher |
| `geography_units` | For example tract; county; zip; block_group; grid_1km; point; admin1; admin2; LSOA |
| `coverage` | For example US; US-states; global; EU; GB; KE; TZ |
| `temporal` | Years and frequency, for example `2000-2022 annual`, `2014-2019 monthly` |
| `versions` | Named versions or releases, for example `2018;2020;2022` or `v4.GL.03` |
| `format` | For example csv; shp; gdb; geotiff; netcdf; geojson; api |
| `access_type` | open_download; api; api_key; registration; request; restricted |
| `license` | As stated, or blank |
| `update_cadence` | As stated, or blank |
| `in_gaia` | gaiaCatalog `datastore/data` folder name, if the dataset is in the catalog |
| `source_of_listing` | Where you found it: gaia_catalog; metadata_template; data.gov; hdx; earthdata; literature; and so on |
| `evidence_url` | The page that supports the row (usually `site_url`) |
| `confidence` | high (publisher page read); medium (catalog listing only); low (secondary mention, page not reached) |
| `last_checked` | Today's date (YYYY-MM-DD) |
| `notes` | Caveats: withdrawn or moved, paywalled, duplicate of X, tract only for some years, and so on |

## Working method

1. Start with the workspace seeds, then sweep the catalogs above, one theme at a time.
2. **Save progress every 50 rows**, appending to the CSV, so an interruption loses little.
3. **Dedupe as you go:** same publisher plus same product means one row. Add new releases to `versions`.
4. **If a page is down, withdrawn or moved**, keep the row with `confidence = low` and say so in `notes`. Some U.S. federal environmental-justice tools were reportedly withdrawn or moved in 2025; record them, don't skip them.
5. **Spend little time per row** (about 1–2 minutes). Leave fields blank rather than digging. Later passes will fill them.

## When you finish, also write `docs/discovery/harvest-2026-10-20-summary.md`

It should contain:

- **Row counts** by theme, by coverage (US, international, global) and by confidence.
- **Which sources were swept,** and which you skipped and why.
- **Known gaps:** themes or regions with thin coverage.
- **Problems hit:** dead links, withdrawn tools, paywalls, rate limits.
- **Suggested next pass:** verification, enrichment, scoring health relevance, and mapping to the `inventory.csv` columns.

Finally, print the summary and stop. Do not start the next pass.
