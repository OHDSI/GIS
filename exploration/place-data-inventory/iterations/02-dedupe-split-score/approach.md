# Claude Code prompt: split the harvest, link it to gaiaCatalog, score the curated rows

Paste everything below the line into Claude Code, run from `D:\workspace\gaia`. It needs no web access.

---

You are doing steps 1–3 of the next pass on the place-based data harvest, described in `docs/discovery/inventory-status-2026-10-20.md`. Read that file and `docs/discovery/README.md` first.

## Rules

- **Write only under `docs/discovery/`.** Read `repos/gaiaCatalog` but don't change it. Don't commit or push.
- **Don't overwrite `harvest-2026-10-20.csv`.** Copy it first to `_to_delete/harvest-2026-10-20-before-split.csv`, then write the new files described below.
- **Don't invent values.** Scores must follow the rubric below, using only what the row says (name, organization, geography_units, format, access_type, theme, notes). If a row lacks the information needed, score it `unknown` rather than guessing.
- **Do all the work with Python scripts saved in `docs/discovery/scripts/`,** so the pass can be re-run. Use the LLM only for the scoring judgement in step 3, and record why.

## Step 1: split the file

- **Pass 1 (the working inventory):** rows whose first `source_of_listing` token is *not* one of these:
  - `google_earth_engine`, `aws_open_data`, `hdx`, `earthdata_cmr`, `data.europa.eu`, `socrata_discovery`, `planetary_computer`, `earth_search_aws`;
  - `data.gouv.fr`, `data.gov.ie`, `data.gov.au`, `open.canada.ca`, `opendevelopmentmekong`, `data.gov.uk`.

  Expect about 584 rows. Write them to `inventory-working.csv`.
- **Pass 2 (leads):** everything else, about 2,576 rows. Write them to `leads-2026-10-20.csv`, adding a column `lead_status`:
  - `promote_candidate`: has a geography (`geography_units`), a date range (`temporal`), and its name doesn't look like raw imagery or scenes (Landsat, Sentinel, MODIS, VIIRS L1/L2, "Level-1/2", reflectance, radiance, SAR, lidar, aerial or orthoimagery, NAIP) or a forecast/model run;
  - `imagery_or_model`: matches those patterns;
  - `stub`: everything else (missing geography or dates).
- **Possible-duplicate groups that span both files** (`dup_group`): keep the pass-1 row in `inventory-working.csv`, and put the pass-2 member in leads with `lead_status = duplicate_of:<pass-1 id>`.
- **Check the counts:** the pass-1 and pass-2 rows must add up to the input total. Print both counts.

## Step 2: link to gaiaCatalog

1. **Read all 113 folders in `repos/gaiaCatalog/datastore/data/`.** For each, collect:
   - the folder name;
   - from `meta_json-ld_<id>.json`: name, publisher or provider, url / landingPage, distribution contentUrl, spatialCoverage, temporalCoverage;
   - whether `meta_dcat`, `meta_etl`, `meta_kobo-json-path` and `etl/*.sh` exist.

   Three folders have no JSON-LD (`mdc_2013_2022_lst_30m`, `mdc_2021_hylo`, `tz_2022_nbs`); use the folder name only for those.
2. **Add an `in_gaia` column to `inventory-working.csv`:** a `;`-separated list of the catalog folder names that hold that dataset. Match on, in order:
   - a landing-page or download domain-and-path match;
   - the same publisher and product (for example, `fl_2018_svi_tract`, `mdc_2022_svi_tract` and `us_2018_svi_county` all map to the CDC SVI row);
   - a name match.

   Year, state and county subsets fold into the parent product row, as before.
3. **Catalog folders that match no row:** add a new row for the product, with `source_of_listing = gaia_catalog`, `confidence = medium`, fields filled only from the JSON-LD, and `in_gaia` set.
4. **Write `gaia-link-2026-10-20.csv`** with one row per catalog folder:
   - `folder`, `matched_id`, `match_method` (url / publisher_product / name / new_row), `has_jsonld`, `has_dcat`, `has_etl`.

   Flag in its notes:
   - the 5 synthetic benchmark folders (`synthetic_*`);
   - `mdc_5000_addresses_normalized` (test address list);
   - a person-level registry layer (name withheld pending a WG decision) (sensitive person-level layer).

## Step 3: score the working inventory

Add four columns to `inventory-working.csv`:

| Column | Values | Rule |
|---|---|---|
| `health_relevance` | 3 / 2 / 1 / 0 / unknown | **3** = a direct exposure or determinant with known health links (air pollution, heat, deprivation or vulnerability indices, toxics, food access, green space, noise, area-level health outcomes). **2** = plausible context or confounder (demographics, land use, transport, housing, hazards). **1** = reference or boundary data needed for linkage (census units, gazetteers, DEMs). **0** = no plausible residence-health use |
| `finest_unit` | point / address / block / block_group / tract / zcta_zip / postcode_small_area / county / admin2 / admin1 / country / grid_<size> / line / unknown | The finest unit listed in `geography_units`. Grids keep their size, for example `grid_1km`, `grid_30m` |
| `gaia_fit` | now / needs_aggregation / needs_raster / not_linkable / unknown | **now** = vector polygons or points, or a table keyed to standard geographies (tract, county, ZIP and so on): what the geom/attr index joins today. **needs_aggregation** = point, line or event data that needs counting or distance to an area first, or a table at a non-standard unit. **needs_raster** = gridded or raster data (GeoTIFF, NetCDF, HDF, Zarr). **not_linkable** = national-only tables, documents, apps or tools with no downloadable data |
| `score_note` | text | One short phrase saying why (for example "tract CSV + TIGER key", "1 km NetCDF grid") |

**Also add `record_type`:** dataset / portal / api / tool. Mark rows whose names or notes say portal, catalog, hub, explorer, API, viewer or tool, and check those by eye.

## Outputs and report

- **Files:**
  - `inventory-working.csv` (pass 1 + `in_gaia` + scores);
  - `leads-2026-10-20.csv`;
  - `gaia-link-2026-10-20.csv`;
  - `scripts/split_link_score.py`.
- **Write `next-pass-2026-10-20-report.md` (one page):**
  - row counts per file;
  - lead_status counts;
  - catalog folders matched vs added as new rows, with the match method;
  - cross-tabs of `health_relevance` × `gaia_fit` and `finest_unit` × `theme`;
  - the count of rows with health_relevance ≥ 2 and gaia_fit = now (the verification shortlist for step 4);
  - anything ambiguous you scored `unknown`.
- **Update `docs/discovery/README.md`:** the status line, the files table and the next steps.
- **Print the report and stop.** Don't start step 4 (verification).
