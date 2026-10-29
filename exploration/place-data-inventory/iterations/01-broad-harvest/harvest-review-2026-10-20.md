# Review of the first-pass harvest (2026-10-20, claude.ai chat)

**Verdict:** the harvest worked for breadth: 646 rows against a target of about 500, with a clear structure and honest confidence labels. It is weak on verification, and its unit of record is inconsistent. Treat it as a well-organized list of candidates, not an inventory.

## What worked

- **Breadth:**
  - 10 themes;
  - 278 US, 213 global and 155 other-international rows, covering about 40 countries;
  - about 300 sources swept.
- **Rows read accurately in a spot check of 40:** specific versions (for example CRU TS 4.10, SatPM2.5 V5.NA.05, GISD releases), sensible geography units, and the right publishers.
- **Withdrawn and moved tools are recorded, with mirrors where known:** EJScreen, CEJST, HIFLD, SEDAC, Billion-Dollar Disasters. That alone is valuable.
- **The summary is honest:** confidence split (316 high / 238 medium / 92 low), blocked sites, gaps, and a sensible next pass.

## Problems

1. **Stale gaiaCatalog seeds.**
   - The run seeded from the pre-pull clone (23 folders), not today's 113.
   - Step 0 (the growth check) was not done, and there is no `in_gaia` column.
   - Only 12 rows are tagged `gaia_catalog`.
   - So it can't yet answer "what do we have vs. what exists".
2. **Facts filled from memory.** About 60 rows say their versions came "from product knowledge" rather than a page read. This breaks the brief's no-guessing rule; treat those fields as unverified.
3. **Mixed unit of record.**
   - About 80 rows are portals, APIs or databases (AQS API, Envirofacts, WHO GHO, Water Quality Portal) rather than datasets.
   - 37 rows are sub-national seeds (Miami-Dade, Huayhuash) at a different grain from the national rows.
   - 44 rows are themed "other".
4. **Verification is thin.**
   - 92 rows are low confidence.
   - About 55 were fetch-blocked by bot protection.
   - data.gov's API failed, so those rows came from search instead.
   - Liveness was not checked independently (this chat's sandbox cannot reach the web).
5. **No Gaia-fit signal.**
   - Formats: 139 raster, 144 vector, 202 table, 137 API/other.
   - Only 74 US rows have tract units.
   - Nothing yet says which rows Gaia can ingest today (vector polygons or points plus attribute tables), as opposed to ones that need raster support or aggregation.

## Would another approach do better?

**For breadth,** an LLM web sweep finds well-known products well, but it is slow (it hit the session limit), blocked by many sites, and tempted to fill fields from memory.

**For structured metadata** (versions, licenses, cadence, formats), a hybrid is likely to be more complete and more accurate:

1. **Pull structured catalogs through their APIs** with ordinary scripts run from the PC terminal, not the sandbox:
   - NASA CMR;
   - Google Earth Engine and Planetary Computer STAC;
   - the AWS Open Data registry YAML;
   - data.gov and HDX CKAN;
   - Copernicus CDS;
   - Zenodo / Dataverse.

   These return versions, licenses and spatial and temporal extents as data, with no guessing involved.
2. **Seed from existing curated inventories in this field:**
   - the Environmental Exposome Gateway;
   - CHORDS (NIEHS);
   - HHEAR;
   - NaNDA;
   - the C-HER exposome dataset list (arXiv 2511.03750);
   - PhenX SDOH.

   Others have already done the health-relevance filtering in these.
3. **Use the LLM only for:**
   - classification (theme, health relevance, Gaia fit);
   - deduplication across catalogs;
   - summarizing documentation.
4. **Check liveness with a plain link-checker script** on the PC (HEAD request, status, redirect). It's quicker and more reliable than LLM fetching.

## For the pass now running

- **Re-seed from the updated gaiaCatalog** (113 folders) and add `in_gaia`.
- **Don't fill versions or licenses from memory.** Leave them blank, or mark them `unverified` in notes.
- **Add three columns:**
  - `record_type`: dataset / portal / api / tool;
  - `finest_unit`: for example tract, grid_1km, point;
  - `gaia_fit`: now / needs_aggregation / needs_raster / not_linkable.
