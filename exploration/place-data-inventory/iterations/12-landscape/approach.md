# PROMPT 2: geometry dependencies, the quiver, and the landscape of collections (phased)

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet (`/model sonnet`), after Prompt 1.5. Script-first.

**It is built to stop anywhere.** Phases run in order of value per hour. Each phase ends by appending its section to the running report, so a stop after any phase still leaves a usable handover. Run all phases in this order: A, D, E, B, F, then R. Time box: about 2.5 hours.

**D and E are spikes, not full executions.** They test a handful of examples to judge whether the method is worth running at scale. Keep to their stated sizes, and end each with a verdict: worth scaling (yes / no / with changes), the estimated cost at full scale, and what to change. Phase C (priority 1-2 sources, listed in full) has moved to its own spike prompt, `PROMPT-2.1-priority-sources-spike.md`.

| Phase | What | Est. time | Why it is early |
|---|---|---|---|
| A | Unit vocabulary, geometry source and dependency, place-key type on the 601 rows; re-tier; "geometry unlocks" and identifier-prevalence tables | 20-30 min | Scripts only, no web. Fixes the UCMR-type over-tiering and produces two new, decision-ready findings |
| D (spike) | 10 collections × 12 anchors: count queries plus a small heatmap | 15-20 min | A first "map of what's possible" at minimal cost |
| E (spike) | 3 collections × 3 anchors × top 10, with Dataverse file and variable lookups on up to 10 hits; overlap on that sample | 20-30 min | Tests whether bulk pulls and variable-level place keys pay off |
| B | Fold the DataCite quiver (2,909 references) into one triaged candidates file with a precision estimate | 30-40 min | Data already pulled; turns raw references into a ranked to-do list |
| F | Metadata enrichment of the 275 verified rows, plus a citation signal for up to 200 DOIs | 30-45 min | Tests whether metadata can replace agent page reads |
| R | Report: finalise `landscape/landscape-report-<date>.md` | 10-15 min | Always run, even after a stop |

## Rules (lessons from round 1)

- **One process, no sub-agents, no parallel agents.** Scripts do the fetching, filtering and matching. Read web pages only to learn an API's query syntax.
- **Fetch metadata only.** Never download data files.
- **Be polite.** Rate-limit requests to about 1 per second per host. User-agent: `OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)`. No email address in any header.
- **Keys:** the data.gov key is in `config/keys/api-data-gov.key`. Send it as the `x-api-key` header to `https://api.gsa.gov/technology/datagov/v3/`. Never print, log or write the key anywhere else. No other service needs a key for search.
- **Checkpoint after each phase and each collection** (`landscape/checkpoints/`), and resume from checkpoints. If a usage or spend limit stops you, don't retry. Run phase R with what exists.
- **Caps:**
  - Full listing only where a collection holds 100k or fewer records after server-side filters (dataset type, years ≥ 2000).
  - Otherwise, the top 50 per anchor per collection.
  - At most 250k raw rows in total.
- **Writes:** under `docs/discovery/landscape/`, plus the new inventory file and vocabulary named in phase A. Keep raw pulls in `landscape/raw/` as gzip JSON or CSV. Member repos are read-only. Don't commit. Don't delete: move superseded files to `_to_delete/`.
- **Inputs:**
  - baseline `inventory-combined-2026-10-29.csv` (601 rows; columns `round`, `wg_request`);
  - anchors `landscape/anchors.csv` (12 anchors, agreed; use as-is; `priority` 1 = active use cases, then 2 policy, 3 air, 4 sub-national development, 5 the rest);
  - the quiver `quiver/datacite-*.csv`.

## Phase A: geometry source, dependencies and place keys (scripts only, no web)

1. **A unit and place-key vocabulary.** Write `unit-vocabulary.csv` (in `docs/discovery/`), the single reference the scripts read.
   - **Columns:** term, kind (`unit` / `place_key` / `geometry_source`), level or resolution, region, example, notes.
   - **Seed it from the unit list in `partB/BRIEF.md`:** point, line, address, block, block_group, tract, zcta, zip, county, state, country, admin1-3, lsoa, msoa, grid_<res>, polygon, raster.
   - **Then append:**
     - **units:** water_system and other service areas (hospital service area, school district), h3_<res>, Australia's SA1-SA4, LGA and postcode, NUTS0-3, LAU, Canada's DA/CSD, P-code admin levels;
     - **place keys:** coordinates, embedded geometry, GEOID/FIPS, ZCTA, NUTS, LAU, ONS GSS, StatCan SGC/DGUID, ASGS, OCHA P-code, ISO 3166, GADM, geoBoundaries, non-geographic ID, none;
     - **geometry sources:** `embedded`, `reference_standard`, `reference_specific`, `none`.

   Add any new term met later to this file, never to the code.
2. **Classify every row.** Use the confirmed fields (`finest_unit_confirmed`, `join_key_confirmed`, `formats_confirmed`, `gaia_fit`), falling back to the listed ones. Add:
   - `geometry_type`: point / line / polygon / raster / none;
   - `place_key_type`: from the vocabulary;
   - `geometry_source`:
     - `embedded`: the dataset ships its own points, lines, polygons or raster;
     - `reference_standard`: keyed to a standard geography whose geometry is easy to get (GEOID → Census TIGER; NUTS → Eurostat GISCO; LSOA → ONS);
     - `reference_specific`: keyed to one particular geometry dataset (water-system service areas, EPA monitoring sites, a CDC-specific ID);
     - `none`;
   - `geometry_dependency`: the inventory id of that geometry dataset if it is in the inventory, or the name of a standard source (e.g. "Census TIGER tracts 2020"), or `TBD`.

   Record how sure each classification is (`geo_class_basis`: confirmed / listed / inferred). Hand-check 20 rows, including `us_epa_ucmr`, `us_epa_aqs_data_mart_api`, `us_epa_aqs_sites_monitors` and two CDC tract tables.
3. **Re-tier** with the existing rules, plus one new rule: **`reference_specific` with `geometry_dependency = TBD` caps the row at Silver**, with the note "geometry dependency TBD". Don't change any other rule.
4. **Write:**
   - `inventory-combined-2026-10-29-geo.csv`;
   - `landscape/geometry-unlocks-<date>.csv`: each geometry dependency with the number of attribute rows it unlocks (all rows, and Gold and Silver), and whether that geometry is itself in the inventory. Sort by rows unlocked.
   - `landscape/place-keys-by-region-<date>.csv`: `place_key_type` × region (US, EU, UK, Canada, Australia, Africa, Asia, Latin America, global).

   Regenerate `inventory.csv`.
5. **Report section A:**
   - tier changes and the rows capped;
   - the top 15 geometry unlocks;
   - place-key prevalence by region;
   - the `TBD` dependencies worth finding first.

## Phase D (spike): collection table and anchor counts

1. **Write `landscape/collections-<date>.csv` for 10 collections only:** DataCite, Harvard Dataverse, Zenodo, ICPSR, data.gov, data.europa.eu, HDX, data.gov.au, NASA CMR-STAC, Earth Engine catalog.

   Columns:
   - name, kind;
   - scope and region;
   - approximate size;
   - metadata standard;
   - API, and key needed (y/n);
   - which filters it supports server-side;
   - whether full listing is possible, and how.
2. **Run one count query per collection × anchor** (10 × 12 = 120 queries, about 1 per second). Use the anchor's terms and server-side filters. Write `landscape/anchor-counts-<date>.csv` and a small heatmap PNG (log scale; anchors in priority order). Skip any collection whose API can't do counts, and say so.
3. **Report section D:**
   - where the depth is, and the thin anchors;
   - **the spike verdict:** worth extending to 30-50 collections? (yes / no / with changes), plus the estimated time at that scale.

## Phase E (spike): top-N pulls and overlap

1. **Pull the top 10 per anchor** for 3 anchors (care_sites, deprivation_indices, air_pollution) from 3 collections (Harvard Dataverse, data.europa.eu, data.gov). That's at most 90 records.
2. **Fetch the file list and, for tabular files, the variable names** for up to 10 Dataverse hits. A GEOID, FIPS, ZIP or similar column sets `place_key_type`. Report how often the variables reveal a place key.
3. **Match** the sample across collections and against the inventory, in this order: DOI → normalized landing URL → publisher plus product → fuzzy title (report fuzzy matches as "possible" only). Report the overlap rate and any product found in more than one collection.
4. **Write `landscape/spike-e-<date>.csv`.**
5. **Report section E:**
   - relevance of the sample (hand-check titles);
   - overlap with the inventory;
   - whether variable-level place keys are worth fetching at scale;
   - **the spike verdict**, with the estimated cost at full scale.

## Phase B: the quiver (scripts only, no web)

1. **Merge.** Combine `quiver/datacite-pilot-2026-10-29.csv`, `quiver/datacite-australia-2026-10-29.csv` and the phase E sample (`landscape/spike-e-<date>.csv`) into `landscape/candidates-<date>.csv`, normalized. Columns:
   - source collection, DOI, title, publisher, year;
   - anchor(s), region;
   - `place_unit_in_title`;
   - `paper_supplement`;
   - citations;
   - `in_inventory`.

   Keep Australian rows only where `australia_in_title = Y`. List the rest in a skipped file.
2. **Triage by rules** into `likely_relevant` / `maybe` / `unlikely`. Signals: an anchor term in the title; a place unit in the title; year ≥ 2000 and not a single event; not a paper supplement; a known geography word. Drop obvious false matches with a small stop-list, and keep that list in the vocabulary file's notes or its own CSV:
   - species and plant censuses;
   - marine heatwaves;
   - greenhouse-gas emission factors;
   - quantum or acoustic "noise" studies.
3. **Precision.** Hand-check a random 100 (titles only), and report the precision of `likely_relevant`.
4. **Report section B:** counts by anchor and region, the precision estimate, and the 20 strongest new candidates.

## Phase F: enrichment and citations

1. **Enrichment.** Look up the 275 Gold and Silver rows in DataCite (by URL, then title), the data.gov API and data.europa.eu. Record each match and the metadata's license, years and spatial fields, and report agreement with the part B values, field by field. Write `landscape/enrichment-275-<date>.csv`.
2. **Citations.** For up to 200 `likely_relevant` candidates with DOIs, get citation counts from DataCite and links from OpenAIRE ScholeXplorer.
3. **Report section F.**

## Phase R: report (always run)

Finalise `landscape/landscape-report-<date>.md`. It should have:
- **A one-paragraph headline for the handover:** what we now know that we didn't, with numbers.
- **The completed sections,** A onward.
- **A ranked shortlist of 3-5 collections** to make primary feeds, from what was measured.
- **The next steps.**
- **Time and usage**, and the phases skipped.

Include a table of the spike verdicts for D and E (and for 2.1, if it has run).

Then update:
- the Dataset discovery row in `STATUS.md`;
- the "Latest" section at the top of `docs/discovery/README.md`.

Print the files written and the before/after tier counts.
