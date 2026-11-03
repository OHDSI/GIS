# P4: publisher-family fan-out (TODO 3.9), report 2026-11-03

**Question.** Publishers that already have Gold or Silver rows usually publish sibling datasets. Does listing each publisher's catalog find new, verifiable rows faster than topic searches?

**Verdict: scale with changes.** 26 new rows (6 Gold, 20 Silver), none of which were already in the master (3 of 302 listed siblings matched it). About 26 rows in roughly 16 minutes of session clock time (23:34 to about 23:50 EST); that figure counts tool time only and is not comparable to #20's "about an hour", so treat it as "faster, not yet measured". Listing is cheap and reliable on hub-style APIs; on DataCite it is noisy. Changes needed are under "Lessons".

## Scope and premises

- Master: `inventory-combined-2026-11-03b.csv` (726 rows; Gold 120, Silver 427; `2-pilot` ignored). Output: `inventory-combined-2026-11-03-p4.csv` (752 rows).
- No sub-agents; no other job wrote masters; nothing committed or deleted.
- A repository or hub API record counts as a read. DataCite alone was not used as a read: DataCite items were read through their landing page.
- Existing rows were not re-checked and `tier_of()` and the federal licence rule are unchanged.

## Counts per phase

| Phase | Target | Result |
|---|---|---|
| F0 | 6 endpoints | 5 reachable (DataCite, Zenodo, figshare, Harvard Dataverse, HDX); **catalog.data.gov CKAN API refused (HTTP 404)**. 24 publishers qualified (cap 25) → `publishers.csv` |
| F1 | 15 siblings per publisher | 302 siblings listed from 23 publishers (Census Bureau returned 0; CDC 6, WHO 4, WorldPop 6, Defra 1) |
| F2 | shortlist 80 | 302 → dropped 41 doc/code/single-site/microdata, 23 not place-based, 3 already in master (1 DOI, 1 URL, 1 title), 28 within-list duplicates, 69 by an 8-per-publisher cap → 80 shortlisted |
| F3 | read ≤60 | 45 fetched; **26 recorded**, 5 blocked, 11 read but not recorded (reasons in `blocked.csv`), 3 JRC SPEI accumulation variants skipped as one series |
| F4 | merge | 26 new rows applied; numbers check passes (below) |

## Rows added

| Tier | n | Rows |
|---|---|---|
| Gold | 6 | HOT/OSM Burundi health facilities, Burundi education facilities, Bulgaria buildings; JRC GDO cold spell Tmin, warm spell Tmax, warm spell Tmin (CC BY 4.0, NetCDF) |
| Silver | 20 | 7 HUD layers (QCT and DDA 2027, HCV by tract, public housing buildings, 2 multifamily, HOME activity); GRID3 DRC health areas and health zones v9.0; 3 Miami-Dade utility-coordination layers; 4 EEA (hot days NUTS3 and hospitals, UWWTD plants); JRC SPEI-3; ECMWF fuel and burned area; NOAAGlobalTemp; Esri/OpenAQ live air quality on the FEMA Hub |

By category: Built environment 9, Heat and temperature 7, Census and socioeconomic 3, Reference geography 2, Floods/drought/wildfire 2, Care sites 1, Air pollution 1, Water quality 1.

Silver, not Gold, for the HUD, Miami-Dade and Esri rows because their Hub licence field is a disclaimer or the Esri master agreement, not a named open licence (same treatment as the existing `us_mdc_*` and `us_hud_*` rows). EEA, ECMWF and NOAA rows are Silver because the access route was not read (`chk_access` left unset, not guessed).

## Numbers check

Recounted from the new master (excluding `2-pilot`): Gold 120 → 126 (+6), Silver 427 → 447 (+20), Bronze, Browser needed and Failed unchanged. The deltas equal the tier moves in `records-tier-moves.csv` (6 Gold, 20 Silver, 26 rows). `inventory.csv` went from 547 to 573 Gold+Silver rows. None of the 26 ids existed in the previous master.

## Publishers that yielded most

HUD 7, Miami-Dade 3, EEA 4, JRC 4, HOT 3, GRID3 2. Zero from NaNDA, NASA SEDAC and Census Bureau.

## Blocked and unread

- **ICPSR** (NaNDA PRISM climate, NaNDA eating and drinking places): HTTP 403. Not worked around. This is the iteration #20 pattern again: the "8 NaNDA products missing" cannot be settled by script.
- **ciesin.columbia.edu** (SoVI grids, BRIC grids): HTTP 403.
- NASA GES DISC OMPS page: empty without JavaScript.
- Read but not recorded because a needed fact was not on the page: USGS wildfire risk map (unit), EPA CMAQ output (grid, licence text), EEA WISE protected areas (no licence sentence), JRC SPEI-12 (grid), Esri Colleges and Universities (licence text), HUD Public Housing Authorities (geometry type).
- Dropped on reading: a 3-day single-site NOAA field test; GRID3 v8.0 layers (superseded by v9.0, which is already in the master); 72-hour and 48-hour forecast layers on the FEMA Hub.

## Lessons

1. **Hub and CKAN APIs are the efficient route.** One call gave licence field, dates, geometry type and formats. 15 of the 26 rows came from HUD, Miami-Dade, GRID3, FEMA and HOT, all through hub or HDX APIs. A listing of all HOT country exports on HDX would be a large, near-free family (health facilities, education, buildings for ~200 countries). The master already holds some HOT health-facility countries; Burundi, Bulgaria and the education layer were new.
2. **DataCite publisher listing is noisy.** "Newest first" for NASA, USGS, ESA, EPA and NOAA returned mostly non-place items (heat pipes, tuna catches, sea-surface swaths, article supplements). I added a geography-word filter on title and subject to the DataCite query (a change from the prompt), and F2's place filter still let through a lot. Rank by a place key or unit term before listing, not after.
3. **The 8-per-publisher cap in F2 was needed** (69 siblings dropped), otherwise HUD and JRC would fill the shortlist; JRC GDO is one series published as several accumulation periods, so only SPEI-3 and the three spell products were taken.
4. **Several publishers have no listable API here**: US Census Bureau (DataCite returns nothing usable), CDC (6), WHO (4). catalog.data.gov's CKAN endpoint returns 404, so federal publishers (EPA, USGS, CDC, USDA, NOAA) can only be listed through DataCite, which is where the noise is.
5. **Dedup was not the limiting factor**: only 3 of 302 listed siblings matched the master by normalized DOI, URL or title (Jaccard ≥ 0.6). The master is sparse on these publishers rather than the listing missing duplicates.
6. **F1 date field**: Hub items report `modified` (a refresh date), not a data year. Rows from Hubs get `chk_temporal = warn` unless the description states a coverage year, which keeps them out of Gold.
7. **Relevance**: the three Miami-Dade utility-coordination layers pass the checks but have little health relevance. Next time, rank Hub items by title and tag match to the anchor terms before F3, and skip generic infrastructure layers.

## Recommendation

Scale, with these changes: (a) list Hub, HDX and CKAN-style publishers first and enumerate them fully (HOT per-country exports, HUD, GRID3, other Esri Hubs with Gold/Silver rows); (b) for DataCite, query with a place-key or unit term and a resource-type filter, and prefer repository APIs for the read; (c) record ICPSR and CIESIN hosts as blocked up front; (d) add a relevance pre-filter against the anchor terms.

## Files

`endpoints.csv`, `publishers.csv`, `siblings.csv`, `shortlist.csv`, `reads/` (raw API and landing text per item), `records.jsonl`, `records-tier-moves.csv`, `blocked.csv`, `checkpoint.jsonl`; scripts `f0.py`, `f0b.py`, `f1.py`, `f2.py`, `f3fetch.py`, `f3write.py`, `lib.py`.
