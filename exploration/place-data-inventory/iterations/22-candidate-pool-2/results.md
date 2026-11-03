# P5: candidate pool, round 2 (TODO 3.10), report 2026-11-03

**Question.** Does continuing #20's method (DataCite families, read through repository APIs) keep yielding about 27 rows per hour, a third of them Gold?

**Verdict: scale with changes.** 32 new rows (20 Gold, 12 Silver). The Gold share (62%) is higher than #20's (33%), but that is because this pool was mostly gridded climate products with open licences, which pass every check from one API record. Few of the rows are health-linked. Time: tool time was short (a few minutes of API calls); the session clock is not a reliable rows-per-hour figure, so none is claimed.

## Scope and premises

- Master: `inventory-combined-2026-11-03-p4.csv` (752 rows; 729 excluding `2-pilot`: Gold 126, Silver 447). Output: `inventory-combined-2026-11-03-p5.csv` (784 rows).
- No sub-agents. Writes stayed in `run-p5-pool2/` until C4. Nothing committed or deleted. `tier_of()` and the federal licence rule are unchanged.
- A repository API record (Zenodo, figshare, Dataverse, PANGAEA JSON-LD, EIDC catalogue JSON, Dryad) counts as a read. DataCite alone did not settle any licence.
- The C2 shortlist was chosen by hand from the 200 enriched titles (a keyword filter could not tell a clinical supplement from a dataset), so the selection is a judgment call, logged in `c2-dropped.csv`.

## Counts per phase

| Phase | Target | Result |
|---|---|---|
| C0 | endpoints, queue | 5 of 6 reachable (catalog.data.gov CKAN still 404). 734 families → 480 queued: removed 33 by DOI and 37 by title match to the master, 166 with no place unit in the title or geolocation, 5 no-API hosts, 13 Earthdata MODIS/VIIRS versions |
| C1 | 200 families | 200 enriched from DataCite (all HTTP 200) → `enriched.csv` |
| C2 | shortlist 90 | 53 shortlisted (29 Zenodo, 7 figshare, 4 Dataverse, 2 PANGAEA, 1 Dryad, 1 OSF, 9 page reads). Dropped 147: supplements/clinical/survey 59, off-topic 55, ICPSR/NaNDA 9, JRC single events 9, ResearchGate 7, WorldPop poverty siblings 6 (already covered by `af_worldpop_poverty_1km`), projections only 2 |
| C3 | read ≤ 60 | 53 fetched; 32 recorded; 19 not recorded (reasons in `blocked.csv`); 3 JavaScript-only pages (OSF, Science Data Bank, Kinder UDP) recorded as blocked |
| C4 | merge | 32 rows applied; numbers check passes |

## Rows added

| Tier | n |
|---|---|
| Gold | 20 |
| Silver | 12 |

By category: Heat and temperature 13, Floods/drought/wildfire 9, Census and socioeconomic 5, Reference geography 2, Deprivation 1, Air pollution 1, Care sites 1.

Gold: global 1 km air temperature 2017; global 1 km LST 2024 (day, night sibling); China monthly 1 km temperature 1951-2020; Zhejiang daily temperature; ONFIRE burned area; LSOA health and income (4 UK city regions); Northern Italy LST; ELITE LST China 2007; China all-sky air temperature 2003-2019; HYPER-P Europe rainfall; Bangladesh BDGR rainfall; SM2RAIN China; Vietnam gridded rainfall; Colombia 1 km climate; Afro-Asian monsoon precipitation; Ebro SPEI; annual SEIFA at SA1; US tract PM2.5 2000-2019; CEH-GEAR1hr Great Britain; UK 1 km gridded population 2021.

Silver, and why: Italy temperature/drought code (title says 2017-2022, files run to 2024: temporal warn); Manila/Bangkok/Jakarta LST grid (cell size not read); US Northeast tract boundaries (vintage inferred from file names); HSU (CC BY-NC-SA); LZU0025 (data file format not read, so access unset); Dhaka UHRI, NUTS3 heat over-65, FIRESPAIN-025 (years not stated in the summary); Australian ED by hospital (no coordinates stated); Canada 2021 census tracts (no licence field); ATO postcode income ("Other (Attribution)" text not read); South Africa municipal data (IEEE DataPort, no licence text).

## Numbers check

Recounted from the new master (excluding `2-pilot`): Gold 126 → 146 (+20), Silver 447 → 459 (+12); Bronze 106, Browser needed 20, Failed 30 unchanged. The deltas equal the 32 tier moves in `records-tier-moves.csv` (20 Gold, 12 Silver). `inventory.csv` went from 573 to 605 Gold+Silver rows. All 32 ids were new.

## Blocked and not recorded (`blocked.csv`)

- **Gone or restricted:** BRain-D (Zenodo HTTP 410); ChinaHighTEMmax, Queensland drought indices and Australian city PM2.5 (Zenodo `restricted`, no files); a Harvard Dataverse ACS record that returned no version metadata.
- **JavaScript-only pages:** OSF, scidb.cn, kinderudp.org. Not worked around.
- **Not datasets:** a figshare record with only a PDF and PNG; a Zenodo questionnaire-only record.
- **ICPSR/NaNDA:** 9 queued records dropped up front as blocked hosts.
- **Out of scope on reading:** Mau Forest atlas (single site), Houston/Phoenix single-week LST, UFZ flood forcing, Hot-nights GB (years unclear), SEDAC West Africa poverty grid (licence not on the page).

## Lessons

1. **The queue order was weak.** Ranking by "unit in title" let in precipitation grids, WPA household records, fish censuses and Kinder county ACS extracts. The word "census" matched ecology and historical records. Rank by anchor and a health or demographic term in the title first.
2. **Only 200 of 480 queued families were enriched, and 53 survived C2.** The cap (200) and the hand filter, not API errors, limited the run. The filter dropped 74% of enriched items, so the cheap step is C1; most of C3's cost is now in the 53 that remain.
3. **Climate grids are cheap Gold but low priority.** Zenodo and figshare records settle every check in one call, so they dominate the Gold count. They fit the heat and hazards anchors, but WG-requested anchors (care sites, deprivation indices) gave 3 rows.
4. **Siblings need family handling in C0.** Day/night LST, min/mean/max temperature, hospital ED tables and UK population variants are one family each. 14 sibling ids were folded into 6 family rows and named in `notes`.
5. **Zenodo `restricted` records have no files.** Checking `access_right` before shortlisting would have saved 3 reads.
6. **PANGAEA needs `Accept: text/html`** (the JSON Accept header returns HTTP 406); the landing page carries JSON-LD with licence and coverage.
7. **Dataverse DOI case:** the lowercase DOI from DataCite worked for 4 of 5 records; one returned a bare record. Use the DOI as published.

## Remaining in-scope families

The queue held 480 families. 200 were enriched; 46 of those became or sit with recorded rows (32 rows plus 14 sibling ids), the rest were dropped or blocked. **280 queued families remain un-enriched** (by publisher: Zenodo 63, Harvard Dataverse 26, figshare 24, Mendeley Data 12, ICPSR 11 which need a person-read, Kinder 9, Government of Canada 9, Climateverse India 8, and a tail). A next round should enrich the next 200 with the improved ranking from lesson 1 and expect roughly 25 to 30 rows.

## Files

`endpoints.csv`, `queue.csv`, `enriched.csv`, `shortlist.csv`, `c2-dropped.csv`, `reads/` (raw API text per item), `records.jsonl`, `records-tier-moves.csv`, `blocked.csv`, `checkpoint.jsonl`; scripts `c0.py`, `c1.py`, `c2.py`, `c3fetch.py`, `c3write.py`, `lib.py`, `show.py`.
