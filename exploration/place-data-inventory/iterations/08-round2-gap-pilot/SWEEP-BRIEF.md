# Round-2 sweep brief (preview, 2026-10-28)

You are running one targeted web sweep for the OHDSI GIS working group's place-based data inventory (round 2 preview). Round 1 (574 datasets, `docs/discovery/inventory-refined-2026-10-23.csv`) left gaps; your sweep fills one. The goal is a short, well-sourced candidate list: at most 30 candidates, every field read from a page you cite. Budget: about 45-60 minutes. Stop at 30 or when the budget runs out.

## Hard rules

- **Write exactly one file:** `docs/discovery/round2/sweeps/<your file name>` (JSON). Do not edit or create any other file anywhere.
- **Never download a dataset** (no zip, csv, shp, tif, nc, gdb, parquet). Reading HTML pages and HTML/PDF documentation is fine.
- **Never bypass bot protection, logins or certificate errors.** If a page cannot be fetched, say so in `notes`, set `confidence` to `low`, and fill only what a search-result snippet or a second page (e.g. a catalog record) supports.
- **Never guess.** Every row carries an `evidence_url`: the page where you read the values. Values from memory are not evidence; if you remember a dataset but cannot open a page that confirms a field, leave the field blank and set `confidence` accordingly. Blank means "not stated / not read".
- Use WebSearch to find candidates and WebFetch to read landing pages (load them through ToolSearch if they are deferred). Polite crawling: one fetch per page, no retries in a loop.
- **Do not re-add datasets already in round 1.** Your instructions list the round-1 ids that overlap your topic; skip those products (a different product from the same publisher is fine). If a candidate turns out to be the same product as a round-1 row, drop it and name it under `overlap_round1` in your file.
- Prefer national or multi-national series; skip city/council products (hyper-local), single events, and anything whose latest data is before 2000.

## Row fields (all strings unless noted; blank when not stated on a page)

| field | what to put |
|---|---|
| `id` | `<scope>_<org>_<product>` lower snake case, e.g. `us_cms_nppes`, `gb_nhs_ods_organisations`, `global_who_gmp_accessibility`. Scope = ISO-2 country, `eu`, `global`, or a region tag |
| `dataset_name` | the product's name as the publisher writes it |
| `organization` | publisher |
| `site_url` | landing page |
| `access_url` | a direct download, API or catalog-record URL if one is shown; else blank |
| `theme` | one of: environment, sdoh, climate_hazard, built_environment, demographics, health_outcome, boundaries, toxics, food_access, other |
| `variables_examples` | 2-5 example variables, `;`-separated |
| `geography_units` | the spatial units offered, `;`-separated, finest first (e.g. `point;county`, `lsoa;msoa;local authority`, `grid_1km`) |
| `coverage` | e.g. `US`, `GB`, `England`, `EU-27`, `global`, `CA`, ISO-2 lists `;`-separated |
| `temporal` | years covered and cadence, e.g. `2010-2023 annual`, `2000-present monthly`, `2019 (single release)` |
| `versions` | named version or release if any, e.g. `v3.2`, `2024 release` |
| `format` | `;`-separated: csv, xlsx, shp, gpkg, geojson, gdb, geotiff, netcdf, api, parquet, pdf, html |
| `access_type` | one of: open_download, api, api_key, registration, request, restricted |
| `license` | the licence text as stated (e.g. `CC BY 4.0`, `OGL v3`, `public domain`), or blank |
| `source_of_listing` | `round2_<sweep>` as given in your instructions |
| `evidence_url` | the page(s) you read, `;`-separated |
| `confidence` | `high` (landing page read, key fields stated), `medium` (page read, some fields missing or from a catalog record), `low` (snippet or blocked) |
| `notes` | anything a reader needs: caveats, what the product is, why it fills the gap |
| `finest_unit` | one of: point / address / block / block_group / tract / zcta_zip / postcode_small_area / county / admin2 / admin1 / country / grid_<size> / line / polygon / unknown |
| `health_relevance` | 3 = direct exposure or determinant with known health links (pollution, heat, deprivation, food access, area health outcomes, access to care); 2 = plausible context or confounder (transport, hazards, land use, demographics); 1 = reference/boundary data; 0 = none |
| `gaia_fit` | now = vector polygons/points or a table keyed to standard geographies; needs_aggregation = points/lines/events needing a count or distance step, or a non-standard unit; needs_raster = gridded; not_linkable = national-only, documents, apps; unknown |
| `keep` | `Y` or `N` after applying the trim rules below |
| `trim_reason` | blank if kept; else one of: `pre_2000`, `single_event`, `hyper_local`, `not_health_relevant`, `catalog_or_portal`, `viewer_or_tool`, `withdrawn`, `duplicate_of_round1` |

## Trim rules (same as round 1)

Keep only if: latest data year 2000 or later (2015 or later for one-off facility snapshots); not a single dated event; not hyper-local (city, council, metro); health-relevant (health_relevance 2 or 3, or 1 only if it is a reference layer the gap needs); a dataset, not a catalog, portal, viewer or tool; not withdrawn. For hazards: multi-year series only.

## File format

```json
{
  "sweep": "<sweep name>",
  "source_of_listing": "round2_<sweep>",
  "started": "<ISO time>", "finished": "<ISO time>",
  "searches_run": <int>, "pages_fetched": <int>,
  "rows": [ { ...fields above... } ],
  "overlap_round1": [ {"candidate": "<name>", "round1_id": "<id>", "why": "same product"} ],
  "could_not_find": [ "<what you looked for and did not find, one line each>" ],
  "blocked_pages": [ "<url>: <what happened>" ]
}
```

When the file is written, reply with: the file path, the number of rows (kept / trimmed), 3-5 highlights (name + why), what you could not find, and your rough time. Nothing else.
