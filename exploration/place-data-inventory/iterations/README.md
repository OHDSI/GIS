# Iterations: how the place-data inventory was built

One row per execution: what it set out to do, the approach (the prompt or brief), what it produced, and what we learned.

- **Files:** each iteration's approach (prompt or brief) and results are in its own folder below.
- **Numbering:** the names Robert used along the way ("1.5", "1.6", "2", "2.1") are in brackets.

| # | Date | Iteration | Intent | Approach | Results | What we learned |
|---|---|---|---|---|---|---|
| 0 | 10-01 | Framing | Decide what discovery is for | [approach](00-framing/) | [results](00-framing/) | The goal was an evidence-backed inventory of place-based datasets, separate from recipe generation |
| 1 | 10-20 | Broad harvest | Collect as many place-based datasets as possible (aim: about 500), worldwide | [approach](01-broad-harvest/) | [results](01-broad-harvest/) | 3,337 rows, but pass 2 (catalog APIs by keyword) was mostly noise. Research repositories (Dataverse, Zenodo, ICPSR) were never queried, and the data.gov API returned 404 |
| 2 | 10-20 | De-duplicate, split, score | Merge duplicates; separate curated rows from leads; score relevance and Gaia fit; link to gaiaCatalog | [approach](02-dedupe-split-score/) | [results](02-dedupe-split-score/) | 3,160 after de-duplication; 1,018 curated or with a stated unit. Rule-based scoring is cheap and explainable |
| 3 | 10-21 | Part A: link health | A scripted URL check per row, no LLM | [approach](03-link-health/) | [results](03-link-health/) | About 1 hour, free and re-runnable. Found withdrawn tools (EJScreen, CEJST, Hazus, NHD). Separate check columns with evidence made tiers explainable |
| 4 | 10-22 | Trim (feedback-driven, before the part A re-check) | Drop stale, one-off, hyper-local and portal rows | [approach](04-trim/) | [results](04-trim/) | 570 kept. Scope rules should come before harvesting, not after |
| 5 | 10-22/23 | Part B: page reads (overnight) | Agents read landing pages for licence, years, unit and access, with evidence URLs | [approach](05-page-reads/) | [results](05-page-reads/) | 256 rows read; Gold 19, Silver 92. About 15k tokens per row, so page reads are the expensive step |
| 6 | 10-28 | Close run | Read the remaining rows; decide duplicates, mirrors and loose ends; package for GitHub | [approach](06-close-run/) | [results](06-close-run/) | 175 more rows read; Gold 33, Silver 156. Ten parallel agents used up the usage limit in about an hour; resuming with a bare "continue" restarted the expensive plan |
| 7 | 10-28 | Browser sample | Find out what "Browser needed" really means: 25 rows in a real browser | [approach](07-browser-sample/) | [results](07-browser-sample/) | 18 of 23 opened, so it is mostly bot-blocking, not dead links. Page reads also corrected rows (AHRQ SDOH became CLH). Licences are rarely on landing pages |
| 8 | 10-28 | Round 2 gap pilot | Targeted sweeps for known gaps; 1 of 5 ran (health facilities) | [approach](08-round2-gap-pilot/) | [results](08-round2-gap-pilot/) | 24 of 25 candidates were new. Targeted sweeps beat the broad harvest; run them one at a time |
| 9 | 10-28 | Finish round 1 ["1"] | Combine the inventory; check every quoted number | [approach](09-finish-round1/) | [results](09-finish-round1/) | 328 of 339 claims matched; the 11 mismatches were all wording. Generated reports need a numbers check |
| 10 | 10-29 | WG targets and the federal licence rule ["1.5"] | Cover the working group's dataset requests; apply the public-domain rule | [approach](10-wg-targets-licence-rule/) | [results](10-wg-targets-licence-rule/) | Gold+Silver 189 → 275; 10 of 14 WG requests at Silver or better. Gold now partly rests on an assumption; the unit check passes non-geographic units (UCMR) |
| 11 | 10-29 | The DataCite quiver ["1.6"] | Cheaply fill the to-do list from DataCite, worldwide and Australia | [approach](11-datacite-quiver/) | [results](11-datacite-quiver/) | About 2,900 references at near-zero cost, nearly all new. Needs title and place filters; precision not yet measured |
| 12 | 10-29 | Landscape, phased ["2"] | Geometry dependencies, collection map (spike), pull-and-overlap (spike), DataCite triage, metadata enrichment | [approach](12-landscape/) | [results](12-landscape/) | 59% of rows ship geometry, 32% join to a standard geography; Census TIGER and GADM are the big unlocks; GEOID/FIPS is US-only. Both spikes are worth scaling with changes (per-API query adapters are the real cost). DataCite triage precision about 0.59. Only 26% of verified rows appear in catalog metadata, often without a licence, so metadata is a cross-check, not a replacement for page reads |
| 13 | 10-29 | Priority sources spike ["2.1"] | Care sites (radiotherapy), policy databases and NaNDA: are they worth listing in full? | [approach](13-priority-sources-spike/) | [results](13-priority-sources-spike/) | Policy data with effective dates exists and is cheap to list (PDAPS, LawAtlas; state FIPS joins). The CMS catalog lists in one API call. NaNDA lists via DataCite. DIRAC (radiotherapy) is manual only and facility data are restricted. PDAPS pages are 7-111 MB, so the full listing needs a lighter route |
| 14 | 10-29 | File-verify the WG requests ["1.7"] | Download and open one small file per request row: columns, place key, geometry, years | [approach](14-file-verify/) | [results](14-file-verify/) | 9 of 13 requests now have a file-verified source. Files corrected the pages: UCMR 3 runs to 2016 and has a ZIP-codes-served file; the UN SDG database is country-only while the DHS API is open and sub-national; DIVA-GIS is 2015 GADM, non-commercial. Gates (Earthdata Login, registration, API keys) are recorded, not bypassed |
| 15 | 10-29 | Browser pass: care sites | Open the 25 care-site rows stuck at Browser needed, grouped by site; HDX rows read through HDX's own API | [approach](15-browser-pass-care-sites/) | [results](15-browser-pass-care-sites/) | 24 of 25 opened: 15 Silver, 5 Bronze, 4 Failed (archived, removed, or a wrong link), 1 still blocked (Kenya's KMHFL). One site API call settled 16 rows; HOT/OSM facility exports are current and open (ODbL). Found newer sources to add: GRID3 Nigeria Health Facilities v4.0, DRC v9.0, and Brazil's CNES registry and oncology panel |
| 16 | 10-29 | Backfill thin categories ["1.8"] | Up to 12 page reads each for health policy, sub-national development, water quality, heat and deprivation | [approach](16-backfill-thin-categories/) | [results](16-backfill-thin-categories/) | 51 read: 10 Gold, 24 Silver, 7 Bronze, 10 Browser needed. The DataCite pool was poor for these categories; scripted searches found most. LawAtlas can be enumerated through DataCite (76 datasets). US drinking water and recent sub-national development stay thin |

## Cross-cutting lessons

- **Order of work:** cheap scripted checks first; agent page reads only where scripts can't decide; targeted sweeps over broad harvests.
- **Cost:** parallel agents are what caused the usage spikes. Run one job at a time, on Sonnet, in fresh sessions, with explicit resume prompts.
- **Trust:** every value carries an evidence URL. Assumptions are labelled (for example `public_domain_us_federal`), and generated reports get a numbers check.
- **Scope:** decide anchors and rules before collecting. The working group's own requests and use cases are the best yardstick.

## Related

- `backlog-place-identifiers-2026-10-28.md`: the next exploration (place identifiers and boundary standards).
- `decisions-needed-2026-10-28.md`: Robert's decisions and their status.
