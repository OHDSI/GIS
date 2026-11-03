# Place-data inventory: what's next

**The expansion sandbox for continuing this work.** Items are grouped by how well specified they are:
1. **Ready to run.** The method and inputs exist; often a prompt is already written.
2. **Scoped.** The method is known, but it needs a prompt or brief.
3. **Exploratory.** The question is clear; the approach still needs framing.
4. **Needs people.** Decisions or definitions from Robert or the working group.

**References:**
- **Iteration numbers** (#n) point to the table in `iterations/README.md`, which lists each run's approach, results and lessons.
- **Prompt numbers are not item numbers.** `PROMPT-1.8-…` and `PROMPT-2.1-…` are written P1.8 and P2.1 here; plain 1.8 or 2.1 means the item in the tables below.
- **Size:** S is under 1 hour, M is 1-3 hours, L is a day or more, as a scripted run on Sonnet.

**Update 2026-11-03 (#20):** candidate pool worked: +27 rows (9 Gold); Gold+Silver 547 (Gold 120); master `inventory-combined-2026-11-03b.csv`. NaNDA licence needs one person-read (bot-checked).

**Update 2026-11-02 (#19):** 699 rows (676 counted, 23 pilot); Gold 111, Silver 409 (225 with all four core checks settled), Bronze 106, Browser needed 20, Failed 30; Gold+Silver 520. Master `inventory-combined-2026-11-02j.csv`; report `run-2026-11-02/report-2026-11-02.md`. Done: 1.6, 1.7, UCMR 4, 2.12, 2.14 (14 of 28; 14 stay Failed with notes), 2.15 (except UNdata), 2.2 polygon count, GIS#553 rows, unit labels (92 left in `run-2026-11-02/g-unit-vocab-review.csv`). For 4.10: Silver needing licence + one more core check would demote about 133 rows; licence + unit + years about 192 (counts from 2026-11-02i). Still open from tier 1: 1.5, 1.8, 1.9; 2.3 waits on the UDS file (Wayback only).

**State as of 2026-10-30 (late):** 691 rows (667 without the pilot); 494 verified (Gold 105, Silver 389) after the validation sweep (#17) and the browser pass (#18; `browser-pass/browser-pass-report-2026-10-30.md`); 20 Browser needed left; 15 file-verified. Master: `inventory-combined-2026-10-30-bp.csv`. Caution: 111 Silver rows have two or fewer of licence/unit/years/access settled (see 4.10). Categories retagged (14, anchor-aligned); thin categories backfilled (Prompt P1.8); policy sources spiked (Prompt P2.1). 9 of the 13 working-group dataset requests have a file-verified source. 1,087 `likely_relevant` DataCite candidates (precision about 0.59) are in `landscape/candidates-2026-10-29.csv`.

## How to run anything here (lessons from #1-#14)

- **One job at a time**, in a fresh Claude Code session, on Sonnet (`/model sonnet`).
- **Scripts first.** Agent page reads only where scripts can't decide. **No parallel sub-agents**: they caused the usage spikes in #6.
- **Resume with an explicit prompt** that says what to skip. A bare "continue" restarts the original plan.
- **Hard caps** in every prompt: rows, fetches, time. Checkpoints, and "if a limit stops you, don't retry; write the report".
- **Evidence URL for every value.** Label assumptions (e.g. `license_class = public_domain_us_federal`). Run a numbers check (#9) before anything is shared.
- **Writes go to the run's own folder**; a merge step updates the inventory afterwards.

## 1. Ready to run

| # | Item | Why | Inputs and references | Size | Done when |
|---|---|---|---|---|---|
| 1.1 | ~~Merge file verification into the inventory~~ (done 2026-10-29: `inventory-combined-2026-10-29-fv.csv`) | Turns "page-verified" into "file-verified" for the WG request rows | `fileverify/` (#14), `wg-open-checks-2026-10-29.md`; UCMR 5 from `fileverify/proposed-rows-*.csv` | S | New columns (`file_verified`, `place_key_found`, …) in `inventory-combined`; tiers re-run; numbers check |
| 1.2 | ~~Close out Prompt 2~~ (done 2026-10-29). `us_epa_ucmr` kept Silver (Robert); ~~add UCMR 4 as its own row~~ (done 2026-11-02: `us_epa_ucmr4_occurrence`, Silver, page-read) | Phases may have stopped early; data.gov returned 503 | `PROMPT-2-landscape-census.md` (#12), `landscape/checkpoints/` | S | All phases in the report, or marked skipped with a reason; spike verdicts recorded |
| 1.3 | ~~Run Prompt 2.1~~ (done 2026-10-29). Next: list PDAPS and LawAtlas in full (DataCite gives LawAtlas's 76 DOIs), the CMS catalog with place keys, NaNDA families; consider a DIRAC data request | Care sites (radiotherapy) and policy are priority anchors | `PROMPT-2.1-priority-sources-spike.md` (#13) | S | A verdict per source: list in full, or manual only |
| 1.4 | ~~Build the GitHub package~~ (built 2026-10-29: `publish/`, by `scripts/build_publish_package.py`; PR to open) | Publish to OHDSI/GIS `exploration/place-data-inventory/` | `scripts/build_publish_package.py` (to write), output in `publish/OHDSI-GIS/` | S | Package plus PR description (with `Refs OHDSI/gaiaCatalog#…`) plus an `rmd/data/updates.json` entry |
| 1.5 | ~~**Comment on the request issues**~~ (posted by Robert 2026-11-03 after #554; later comments go out after each merge) | Closes the loop with requesters | 14 gaiaCatalog requests and GIS#288; `pr/comments/*.md` and `post-comments.sh` (gh CLI); the agreed format is "B" (3 lines; "C" when something is open) | S | Comments posted after the PR merges, so the links are stable |
| 1.6 | ~~Read the last 25 close-queue rows~~ (done: 24 of the 25 D08 rows were re-read on 2026-10-30, #17/#18; now Silver 13, Bronze 12; checked 2026-11-02) | Finishes part B for round 1 | `partB/queue-close.json`, `partB/BRIEF.md` (#6) | S | 25 rows tiered |
| 1.7 | ~~Review the federal-rule edge cases~~ (done 2026-11-02, #19, page read only: Daymet and Smithsonian GVP to Gold; WQP warn, Silver) | Gold partly rests on an assumption | `federal-publishers-2026-10-29.csv`; leftover cases: Smithsonian, ORNL Daymet, the Water Quality Portal (#10) | S | Each decided; tiers re-run |
| 1.8 | **Schedule the monthly link check** | Catches withdrawals and dead links early | `scripts/verify_links.py` (#3) | S | A monthly run writes `verify-log.csv` and a short diff report |
| 1.9 | **Send the PEDP licence question and the notes for Tim** | Unblocks the EJScreen/CEJST/HIFLD mirrors; catalog fixes | `decisions-needed-2026-10-28.md`, `notes-for-tim-2026-10-28.md` | S (Robert) | Sent; answers logged |
| 1.10 | **Add a `tier_cap` column** (value plus reason) that `tier_of()` respects | 11 rows hold a hand cap stored only as their tier value; any re-tier silently undoes it (#24) | `run-2026-11-03/report-fixes-2026-11-03.md` (tier drift); `scripts/apply_records_2026_11_02.py` | S | The 10 remaining caps (GHGRP, MDI, CHORDS and 7 backfill rows) are columns, and a fresh `tier_of()` reproduces every stored tier |

## 2. Scoped (needs a prompt)

| # | Item | Why | Inputs and references | Size |
|---|---|---|---|---|
| 2.1 | ~~**Browser pass over the queue, grouped by domain**~~ (done 2026-10-30, #18: 145 of 167 opened; 20 left, all security checks, 403s or unreachable hosts; retry the unreachable ones from another network) | 150 rows on 79 domains are script-blocked; about 4 in 5 open in a real browser (#7) | `browser-queue-2026-10-28.csv`; one visit per domain settles many rows | M |
| 2.2 | ~~Find water-system service-area boundaries~~ **Found 2026-10-30 (#17):** EPA Public Water System Service Areas v3 (March 2026), PWSID key; row `us_epa_pws_service_areas` is in the inventory. Polygon check done 2026-11-02 (#19): CWS feature service 44,615 polygons, 44,614 PWSID; still to measure: UCMR PWSID coverage | Unlocks UCMR 3, UCMR 5, UCMR, SDWIS | `validation/v5-answers.md` | S |
| 2.3 | **ZIP-to-ZCTA crosswalk: partly answered (#17). Decision 2026-11-02 (Robert): use the archived UDS crosswalk; file check in `run-2026-11-02/`.** No official source: Census publishes ZCTA relationship files only; UDS Mapper was sunset in early 2024; HUD-USPS maps ZIP to tract/county/CBSA (not ZCTA) and its API needs a key. Decide the route (HUD ZIP-to-tract + ZCTA-to-tract, or archived UDS) | Gates 20 ZIP-keyed rows (CMS, HRSA, HUD) | `validation/v5-answers.md`; `us_hud_usps_zip_crosswalk` is Browser needed | S |
| 2.4 | **Round 2 gap sweeps 2-5**, one at a time, 15 each | Transport, hazard time series, non-US food access, non-US sub-national health | `round2/SWEEP-BRIEF.md`; partial files for sweeps 2 and 3 already exist (#8) | M |
| 2.5 | **DataCite for the remaining anchors**, worldwide | Priority 1 and Australia are done (#11) | The query pattern in `iterations/datacite-quiver-2026-10-29.md`; use the precision found in phase B | S |
| 2.13 | ~~**Browser pass for the rows the validation sweep could not read**~~ (done in #18) (22 of the 46 never-read Bronze rows: Miami-Dade Hub pages, ICPSR/NaNDA, HDX, IAEA; plus 10 V1 rows) | Scripts get JS shells or challenge pages (#17) | `validation/v2-results.csv`, `validation/v1-results.csv` | M |
| 2.14 | **Resolve the 28 Failed rows left `unresolved`** (2026-11-02, #19: 14 resolved; 14 left, leads in each row's `run_2026_11_02_note`) (searches were capped; 9 are confirmed stale, 7 have a live successor to check against the row) | `validation/v4-results.csv` (#17) | M |
| 2.15 | ~~Successor URLs~~ (done 2026-11-02, #19: NZDep, OECD, EFAS, BFS, HIFLD hospitals; AHRQ was already renamed; open: UNdata is now UN Data Commons) (#18): EFAS about page, OECD regional statistics, Otago NZDep (all 'not found'); AHRQ SDOH URL now opens the CLH Database (rename the row?); `us_hifld_hospitals` points at 'HIFLD OPEN Trauma Levels'; data.un.org is now UN Data Commons; BFS English pages gone | Keeps Failed and Silver rows honest | `browser-pass/browser-pass-report-2026-10-30.md` | S |
| 2.6 | **Australian government portals** | The best Australian DataCite hits were copies of portal data | data.gov.au (CKAN) and the state portals; anchors in `landscape/anchors.csv` | M |
| 2.7 | **Scale the landscape spikes** | Only if the phase D and E verdicts say so | `landscape/landscape-report-*.md` (#12) | M-L |
| 2.8 | **Act on the metadata-enrichment result** | If metadata matches the page reads, cheaper verification at scale | Phase F of #12 | S-M |
| 2.9 | **Promote verified rows into gaiaCatalog** (2026-11-03: six draft JSON-LD entries with embedded select/where recipes for EJI, TRI, AQS sites, COI, UCMR 5 and the PWS service areas, in `publish/catalog-drafts-2026-11-03/`; #529 input, awaiting Robert's review) | The inventory becomes catalog entries; start with the WG requests (EJI, TRI, AQS sites, COI, UCMR 5) | The metadata template (`repos/ohdsi-gis-metadata-template`); `publish/OHDSI-gaiaCatalog/` | M per few datasets |
| 2.12 | ~~Add the newer care-site sources~~ (done 2026-11-02, #19: GRID3 NGA v4.0 and COD v9.0 Gold; CNES Silver; PO Bronze lead) | GRID3 Nigeria Health Facilities v4.0 (Oct 2026), GRID3 DRC Health Facilities v9.0, Brazil DATASUS CNES (establishment registry) and PO (oncology panel since 2013) | `browser-pass/care-sites-2026-10-29.csv` | S |
| 2.11 | ~~Backfill thin categories~~ (done 2026-10-29: 51 rows read). Still thin: US drinking water (needs service-area geometry), recent sub-national development; 10 new Browser-needed rows | After the 29 Oct retag (`scripts/categories_2026_10_29.py`, 14 anchor-aligned categories), the thin ones are health policy (1 row), sub-national development (6), water quality (11), heat (15) and deprivation indices (28); care sites have 54 rows but few verified (8 primary) | Start with the DataCite candidates already tagged by anchor (`landscape/candidates-2026-10-29.csv`), then capped gap sweeps, about 10 per category; policy needs Prompt 2.1's sources | M |
| 2.10 | **National statistics-office boundary files** | 21 rows (Latin America, Africa, Asia) have no known boundary source | Phase A, geometry unlocks | M |
| 2.16 | **Recipe-ready packets (the file-verified rung)** (2026-11-03, after #23) | 127 rows have licence, access, format and join key settled, but only 15 have ever had a file opened; recipes need the file. Field of dreams: packets anyone can turn into a recipe once #532 settles the format | Schema from APIs first (ArcGIS `?f=json`, Socrata views, CKAN datastore, Dataverse variables), a partial (range) read second, full download last. Per dataset: schema and source, place key with system and vintage, 5 sample rows, value and missing-value coding, evidence; `publish/catalog-drafts-2026-11-03/` (six worked examples, `validate.py`) | M (PROMPT-7) | Packets for the 127 rows; `place_key_system` and `place_key_vintage` filled |

## 3. Exploratory (needs framing)

| # | Item | The question | Starting point |
|---|---|---|---|
| 3.1 | **Place identifiers and boundary standards** (high priority; **measuring step done 2026-11-03 in P6 K0**: GEOID/FIPS 145 of 604 Gold/Silver rows, NUTS 10, ONS GSS 5, ASGS 6; only 25 rows (4%) state a key vintage, so add `place_key_vintage`; 13 unique crosswalk products found, see `run-p6-placekey/report.md`) | Which identifier systems should Gaia treat as first-class, by region, and which crosswalks are needed? | `backlog-place-identifiers-2026-10-28.md`; `landscape/place-keys-by-region-*.csv`; `unit-vocabulary.csv` |
| 3.2 | **Health policy data in OMOP** | How do state laws with effective dates become exposure periods? Which sources are comparable across states? | Anchor `health_policy`; Prompt 2.1 results (LawAtlas, PDAPS) |
| 3.3 | **Access to specialty care** (radiotherapy, oncology) | Facility sources plus a distance or travel-time method that fits Gaia | Anchor `care_sites`; DIRAC and CMS in 2.1; DataCite hits on travel time (#11) |
| 3.4 | **Notability signals** | Rank candidates by use: citations (DataCite, OpenAIRE ScholeXplorer) and presence in peer catalogs (NIEHS CHORDS/HEW, NaNDA, Data Commons) | Phase F citation signal (#12) |
| 3.5 | **Raster support** | 147 rows need raster handling. Is that a Gaia capability question or a recipe pattern? | `gaia_fit = needs_raster`; GIS #522 (the retrieval/join split) |
| 3.6 | **Expert-curated lists from review papers** | Extract the data sources named in 5-10 recent exposome and SDOH-linkage reviews | Small and agent-based; capped |
| 3.7 | **Vocabulary alignment** | Map `unit-vocabulary.csv` and the place keys to the WG's vocabulary work and to OMOP location | `repos/GIS/vocabularies`; the WG's vocabulary page |

| 3.8 | **Place-key-first discovery** (**done 2026-11-03, iteration #23: 20 rows, 10 Gold / 10 Silver; verdict: scale with changes**, see `run-p6-placekey/report.md`; Robert's idea, 2026-11-02) | Search by the identifiers datasets join on (tract/block-group GEOID, ZCTA, NUTS, LSOA, ASGS SA1) instead of by topic, then fan out from the publishers that yield | Spike: top 5 key systems × 2-3 collections searched by variable or column name (Dataverse variable search, Socrata column search, CKAN resource fields), 20 hits each; measure precision and overlap; verdict like #12 D |
| 3.9 | **Publisher-family fan-out** (**done 2026-11-03, iteration #21: 26 rows, 6 Gold / 20 Silver; verdict: scale with changes**, see `run-p4-fanout/report.md`) | For each publisher with Gold or Silver rows, list its sibling datasets (hub search APIs answer in one call: GRID3, NaNDA, CDC, CMS) | `run-2026-11-03/` shows NaNDA alone had 8 missing products |
| 3.10 | **Continue the candidate pool (#20)** (**done 2026-11-03, iteration #22: 32 rows, 20 Gold / 12 Silver; verdict: scale with changes**, see `run-p5-pool2/report.md`) | About 510 in-scope families left; about 27 rows per hour, a third Gold | `run-2026-11-03/a-families.csv`; Zenodo/figshare/Dataverse first; filter supplements and microdata in step A |
| 3.11 | **Key vintage and crosswalk list** (follow-on to P6, 2026-11-03) | Add `place_key_system` and `place_key_vintage` to the master (draft logic in `run-p6-placekey/k0.py`), then list the crosswalks the rows imply (2010/2020 tracts, ZIP/ZCTA, LSOA 2011/2021, NUTS versions) | `run-p6-placekey/k0-place-keys.csv`, the 13 unique crosswalk products in `k2-hits-classified.csv` |

## 4. Needs people

| # | Item | Who |
|---|---|---|
| 4.1 | Define the vague requests: gaiaCatalog#26 (suicide risk: which datasets?), #34 (SDG: which indicators and countries?), #28 (which MDI?) | Requesters / WG |
| 4.2 | Confirm the anchor priorities. Many WG requests are 1-3 years old; which still matter? | WG meeting |
| 4.8 | Do site-wide terms pages count as a dataset licence? The sweep set 6 rows to pass on that basis (ABS, ONS, Welsh Government, Statistics Canada, World Bank; `license_basis = site_terms`) (2026-11-03: Miami-Dade County's Hub terms are a disclaimer only, no grant and no restriction; 18 rows stay warn on that basis, #24) | Robert, WG |
| 4.9 | Should warn-only Silver rows (registration, non-commercial, unit differs from the listed one) count toward Gold? The sweep left them as warn | Robert, WG |
| 4.10 | Tighten Silver? (2026-11-02, Robert: take to the WG; no change until then.) Today it needs only a live link, any one page read and no fail among licence, unit, years and recency, so 111 of 389 Silver rows have two or fewer of licence/unit/years/access settled (#18). Option: Silver needs licence plus at least one more core check settled | Robert, WG |
| 4.11 | Miami-Dade Park Facilities (catalog row, Failed): the layer is gone from the county Hub; successor is County Operated Park - View (points) or Municipal Park? (#24) | Robert |
| 4.12 | Older NaNDA studies (icpsr38xxx, 7 rows): no licence on the study page; read the original openICPSR deposit (project 110641) in your own browser (ICPSR blocks agents) | Robert (1 page) |
| 4.3 | A policy on person-level public records (the offender-registry entry was removed) | WG |
| 4.4 | Whether to name the sensitive entries in shared docs (thread open in the retrospective) | Robert |
| 4.5 | Whether non-commercial sources are acceptable (IHME, Global Data Lab, EM-DAT) | WG |
| 4.6 | Whether an `exploration/` folder is welcome in OHDSI/GIS, or a separate repo | GIS maintainers |
| 4.7 | gaiaCatalog fixes: flag the test-address fixture; remove the registry entry | gaiaCatalog maintainers |
