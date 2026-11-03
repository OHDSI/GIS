# PROMPT 6: place-key-first discovery spike (TODO 3.8, with the measuring step of 3.1)

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet (`/model sonnet`). Unattended. **Time box: about 3 hours in total, with a cap for each phase.** Run the phases in order, one at a time. **No sub-agents.** Run this job alone: only one job writes inventory masters at a time.

## Context

- **Master:** the newest `docs/discovery/inventory-combined-*.csv` by date suffix (at writing, `inventory-combined-2026-11-03-p5a.csv`, 784 rows). Ignore `round = 2-pilot`.
- **Question (3.8):** does searching by the identifier a dataset joins on (a column called `GEOID`, `ZCTA5`, `NUTS_ID`, `LSOA21CD`, `SA2_CODE21`) find usable place data that topic searches missed, and which publishers yield enough to fan out from? This is a spike: the verdict matters more than the row count. Compare with #12 D, #20 and #22.
- **Question (3.1, measuring part only):** which identifier systems, levels and vintages do the inventory's Gold and Silver rows actually use, by region?
- **Why now:** #22 (P5) found topic-ranked pools now yield mostly gridded climate products; WG-requested anchors gave 3 of 32 rows. A join key is, by construction, the thing Gaia needs.
- Read first: `backlog-place-identifiers-2026-10-28.md`, `landscape/place-keys-by-region-2026-10-29.csv`, `unit-vocabulary.csv`, `run-p5-pool2/report.md` (lessons), and the "Rules" section of `PROMPT-4-publisher-fanout.md`.

| Phase | Target | Cap | Time |
|---|---|---|---|
| K0 | Profile the inventory's place keys (script); test endpoints | | 25 min |
| K1 | Key searches: 5 keys x 2-3 collections, metadata only | 20 hits per search, 300 in all | 40 min |
| K2 | Classify, dedupe, measure (script plus hand check) | | 25 min |
| K3 | Read the best new hits through repository APIs | 30 rows | 60 min |
| K4 | Merge, tiers, numbers check, report, docs (always runs) | | 30 min |

## Rules (every phase)

Same as PROMPT-4 "Rules", with the run folder `docs/discovery/run-p6-placekey/` and `round = p6-placekey`. In short: writes only to the run folder until K4; evidence URL for every value; repository API and catalog records (Zenodo, figshare, Dataverse, CKAN, Socrata) count as reads, DataCite alone does not settle a licence; BRIEF reading limits; no downloads, sign-ins or bot-check workarounds (ICPSR, openICPSR and NaNDA show challenges: record `blocked`); 1 request per second per host; the inventory user-agent string; checkpoints every 10 items in `checkpoint.jsonl`; K4 always runs; don't change `tier_of()` or the federal licence rule.

## K0: profile the inventory and test endpoints (script)

1. For every Gold and Silver row (computed with `tier_of()` from `scripts/apply_records_2026_11_02.py`; excluding `2-pilot`), classify the place key into `system` (GEOID/FIPS, ZCTA, ZIP, NUTS, LAU, ONS GSS, ASGS, StatCan SGC/DGUID, OCHA P-code, ISO 3166, GADM, geoBoundaries, national statistical code, coordinates, grid, embedded geometry, none, unknown), `level` (unit-vocabulary term) and `vintage` (year, if stated). Use `join_key_confirmed`, `chk_join_key_detail`, `place_key_type`, `place_key_found`, `finest_unit_confirmed` and `finest_unit`, in that order of trust. Record which column decided it. Don't read any pages.
2. Write `k0-place-keys.csv` (id, tier, region, system, level, vintage, source_column) and `k0-summary.csv` (system x region counts, Gold/Silver split). Compare with `landscape/place-keys-by-region-2026-10-29.csv` in the report: what the inventory has versus what the landscape has.
3. Test each search endpoint in K1 once with a trivial query; record reachable / refused / no-field-search in `endpoints.csv`. If a column or variable search does not work, fall back to title/description search **and say so** for that search; that changes how its precision is read.

## K1: key searches (metadata only)

Five key systems; for each, 2-3 collections. Search for the column or variable name first, then the code-system phrase. Take the first 20 hits per search, newest first where the API allows. Record: key, collection, query, mode (column / variable / full-text), title, id/URL, DOI, publisher, date, licence field, formats, any geography field. Write `k1-hits.csv`. Don't read pages.

| Key | Column / phrase examples | Collections |
|---|---|---|
| US tract / block group GEOID | `GEOID`, `GEOID10`, `GEOID20`, `TRACTFIPS`, `census tract FIPS` | Socrata Discovery API (`https://api.us.socrata.com/api/catalog/v1`, column names); Harvard Dataverse search (`variableName:`); Zenodo |
| ZCTA | `ZCTA5`, `ZCTA5CE20`, `ZCTA` | Socrata; Harvard Dataverse; Zenodo |
| NUTS | `NUTS_ID`, `NUTS3`, `NUTS 2021` | data.europa.eu search API; Zenodo |
| UK LSOA / MSOA (ONS GSS) | `LSOA21CD`, `LSOA11CD`, `MSOA21CD` | data.gov.uk CKAN `package_search`; Zenodo; figshare |
| Australia ASGS SA1 / SA2 | `SA1_CODE21`, `SA2_CODE21`, `SA2_MAIN16` | data.gov.au CKAN `package_search`; Zenodo; figshare |

Cap: 20 hits per search, 300 hits in all. If a search returns fewer than 5 hits, try one more phrasing, then move on.

## K2: classify, dedupe, measure (script plus hand check)

1. **Dedupe against the master** with normalized matching, as in PROMPT-4 F2: lowercase DOIs without version suffixes, ICPSR numbers, title Jaccard 0.6 or more, same URL host plus path. Mark `in_master`.
2. **Classify each hit**: `keyed_dataset` (a reusable dataset whose rows are places keyed by that system), `boundary_file` (the geometry itself), `crosswalk`, `not_place` (keyed by something else), `microdata_or_restricted`, `document_or_code`. Use the metadata only. Hand-check a random 30 of the script's labels and report agreement.
3. **Measure per key and per collection:** precision (keyed_dataset share), new share (not `in_master`), anchor match (`anchors.csv` terms in title or description), health or SDOH relevance, and overlap between collections for the same key.
4. **Publisher yield:** publishers with 3 or more new keyed_dataset hits, with their catalog kind. These are fan-out seeds for a later run, not this one. Write `k2-publishers.csv`.
5. Shortlist up to 45 new keyed datasets for K3, ranked: WG-requested anchors first (care sites, deprivation, health policy, food, housing), then other anchors, then the regional gap (outside the US first), then recency. Write `k2-shortlist.csv`.

## K3: read the best new hits (cap 30 rows)

Read through repository and catalog APIs as in PROMPT-5 C3 (Zenodo, figshare, Dataverse, CKAN package records, Socrata dataset metadata at `/api/views/<id>.json`). Record rows exactly as in PROMPT-4 F3 (`records.jsonl`, same fields), and also set `join_key_confirmed` (column name and system, as stated by the record) and `place_key_type`. One row per product family; list sibling ids in `notes`. Unit from the record only (grids as `grid_<res>`; areas as unit-vocabulary terms). Write `blocked.csv` for what could not be read.

## K4: merge and record (always runs)

As PROMPT-4 F4: apply `records.jsonl` with `scripts/apply_records_2026_11_02.py` to make `inventory-combined-<today>-p6.csv`; numbers check; `run-p6-placekey/report.md`; the next iteration number in `iterations/README.md`; a `PR-next.md` section; TODO 3.8 marked with the date and verdict, and TODO 3.1 noted with the K0 findings.

The report answers, with numbers:
1. **3.1:** which systems, levels and vintages the Gold and Silver rows use, by region; where the inventory differs from the landscape counts; which crosswalks the rows imply (for example 2010 vs 2020 tracts, ZIP vs ZCTA, LSOA 2011 vs 2021).
2. **3.8:** precision and new share per key and per collection; whether column or variable search beat full-text; cost per row compared with #20 and #22; which anchors the key search reached that topic search did not.
3. **Verdict:** adopt, scale with changes, or drop, as in #12 D, with the fan-out seeds listed.

## Resume prompt

"Resume PROMPT-6 from `run-p6-placekey/checkpoint.jsonl`: skip completed phases and items, continue the current phase within its cap, then run K4."
