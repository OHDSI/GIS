# P6: place-key-first discovery spike (TODO 3.8, with the measuring step of 3.1), report 2026-11-03

> **This assumes:** (1) the master for "new" is `inventory-combined-2026-11-03-p5a.csv` (761 rows excluding `2-pilot`), matched by DOI, URL and title only, so product families already covered under a different title count as new unless flagged by hand; (2) hit labels (keyed dataset, boundary, crosswalk...) come from search metadata alone, not from opening files; (3) "keyed" means the record names the key or a place unit. Only Socrata column search and Dataverse variable search show that a column exists.

## Check these first (contrary evidence)

- **The key matched, but the dataset was often not reusable.** Dataverse `variableName:GEOID` returned 40 datasets: 28 were replication packages for papers (`document_or_code`), 10 keyed datasets. A column called GEOID proves a join key, not a reusable product.
- **Bare code tokens fail on Zenodo.** `GEOID` matched geodesy (geoid models, GEOSAT, GNSS): 15 of 20 hits were not place data. `ZCTA5CE20`, `LSOA21CD` and `SA2_CODE21` returned 0 hits on Zenodo; `LSOA` and `ASGS SA2` worked as phrases. On data.gov.au the bare `SA2_CODE21` search returned 16 off-topic records (tax tables, ocean moorings, charities) and the quoted phrase returned 0.
- **My first labelling was wrong in places.** Hand check of 30 random hits: the script agreed on 22 (73%). Three of the disagreements were my own error in the first pass (Colorado DOLA "Census ... in Colorado" tables are ACS attribute tables, not boundary files); I corrected them in the check file and the script, and did **not** re-measure on a fresh sample. The final labels carry 8 hand overrides after I read all keyed and not-place titles (`k2-hits-classified.csv`, column `label_note`).
- **Strict "new" overstates novelty.** 97% of keyed hits are not in the master by the 0.6 title rule, but by hand 10 hits belong to families the master already holds under another title (CDC PLACES ZCTA releases ×6 and its Zenodo copy, Eurostat postcode-to-NUTS, ATO postcode tax tables). I counted those as not new (`family_in_master`): 59 new keyed out of 61 keyed.
- **The K3 queue was hand-ordered toward health and SDOH.** The script's ranking put JRC tourism indicators and Dutch labour-market tables near the top. I read a hand-picked 26 (`k3fetch.py`, `QUEUE`). The share of health-linked rows below is partly my selection, not the search's.

## Verdict: scale with changes

Key search finds a different slice of data than topic search: 15 of the 16 recorded rows with DOIs were absent from every earlier candidate list I checked (the DataCite queue, the #20/#22 enrichment and the landscape candidates). It reached care sites, housing and ZCTA/LSOA products that the gridded-climate-heavy topic pools did not. It is too noisy to run unfiltered. Use it as a complement to topic search with the three changes at the end.

## Numbers

| Phase | Result |
|---|---|
| K0 | 604 Gold and Silver rows profiled (146 Gold, 458 Silver); 9 endpoints tested, all reachable; 2 of the 7 collections have field-level search (Socrata column names, Dataverse variable names); Zenodo, CKAN, figshare and data.europa.eu are full text only |
| K1 | 20 searches (15 planned plus 5 fallbacks of <5 hits) → 210 hits, 168 after removing duplicates within a key (Europa mirrors Zenodo) |
| K2 | 61 keyed datasets (precision 0.36), 12 boundary files, 13 crosswalks, 32 paper/code supplements, 48 not place, 2 restricted; 59 new keyed; 45 shortlisted by script, 26 read from a hand-ordered queue |
| K3 | 26 reads (all HTTP 200), **20 rows recorded: 10 Gold, 10 Silver**; 6 read and not recorded (`blocked.csv`) |
| K4 | `inventory-combined-2026-11-03-p6.csv`: 804 rows (781 excluding `2-pilot`): Gold 146 → 156, Silver 458 → 468; Bronze 107, Browser needed 20, Failed 30 unchanged; 0 existing rows changed; `inventory.csv` = 624 Gold+Silver |

Numbers check: recounted the new master directly (781 non-pilot rows; Gold 156, Silver 468), diffed against p5a (20 added ids, none removed, none of the 784 earlier rows altered), and the `inventory.csv` row count equals Gold+Silver (624). Cost: about 65 API requests for 20 rows (about 3 per row), against about 260 for #22's 32 rows (200 DataCite lookups plus 53 record reads). I did not record a reliable wall-clock, so no rows-per-hour figure is claimed (the same position as #22). #20 reported about 27 rows per hour.

## Question 3.8: precision, new share, anchors

Unique hits, after removing duplicates inside a key.

| Key | Unique hits | Keyed | Boundary | Crosswalk | Paper/code | Not place | Precision | New keyed |
|---|---|---|---|---|---|---|---|---|
| US GEOID | 54 | 18 | 3 | 0 | 15 | 17 | 0.33 | 18 |
| ZCTA | 35 | 14 | 0 | 3 | 16 | 2 | 0.40 | 12 |
| NUTS | 23 | 19 | 2 | 2 | 0 | 0 | 0.83 | 19 |
| UK LSOA | 20 | 6 | 2 | 7 | 1 | 3 | 0.30 | 6 |
| ASGS SA1/SA2 | 36 | 4 | 5 | 1 | 0 | 26 | 0.11 | 4 |
| **All** | 168 | 61 | 12 | 13 | 32 | 48 | **0.36** | 59 |

| Collection | Unique | Keyed | Precision | New keyed | Anchor match (keyed) | Health/SDOH (keyed) |
|---|---|---|---|---|---|---|
| Socrata (column search) | 17 | 11 | 0.65 | 10 | 0.91 | 1.00 |
| data.europa.eu | 21 | 17 | 0.81 | 17 | 0.06 | 0.35 |
| Zenodo | 65 | 22 | 0.34 | 21 | 0.23 | 0.68 |
| Harvard Dataverse (variable search) | 40 | 10 | 0.25 | 10 | 0.10 | 0.60 |
| data.gov.uk | 7 | 0 | n/a | 0 | n/a | n/a (all 7 are ONS crosswalks) |
| data.gov.au | 16 | 0 | 0 | 0 | n/a | n/a |
| figshare | 2 | 1 | 0.50 | 1 | 0 | 1.00 |

- **Column or variable search vs full text.** Field search (Socrata column, Dataverse variable): precision 0.37, anchor match 0.52, health/SDOH 0.81. Full text: precision 0.36, anchor match 0.15, health/SDOH 0.55. Equal precision, but field search is far more relevant to anchors, and it is the only mode that shows the key column exists. Socrata's 11 keyed hits are dominated by one publisher (DOLA, 10), so its 0.91 anchor rate is not independent evidence.
- **Overlap between collections.** One pair only: data.europa.eu and Zenodo for NUTS (4 duplicate records; Europa mirrors Zenodo, so these are one dataset seen twice). Dataverse, Socrata, CKAN and figshare did not overlap with each other for these keys. The collections are close to disjoint, so a key search needs several collections.
- **Compared with other iterations.** #12 D's DataCite quiver had precision about 0.59 on place data. Here, usable place hits (keyed + boundary + crosswalk) are 86 of 168 (0.51); keyed alone is 0.36. #22's 200 enriched DataCite items gave 53 shortlisted and 32 rows (0.16 of enriched); here 20 rows came from 168 unique hits (0.12) but from 26 reads rather than 53.
- **Anchors reached.** Of 20 rows: care sites 3 (GB accessibility indicators to GPs, hospitals, pharmacies; Australian travel times to hospitals, GPs, emergency and pharmacies by Mesh Block; US county Family Medicine and surgery linked data), housing 3 (Tampa Bay ZCTA rent burden; Pennsylvania municipal property tax and housing; NYC public housing tracts), heat 2, air pollution 1, healthcare flood exposure 1, health outcomes 1 (England and Wales long-term health by LSOA, Census 2011), other 9 (built environment, census, other). WG-requested anchors (care sites, housing) give 6 of 20 (30%), against 3 of 32 (9%) in #22. Deprivation indices, health policy and food: 0. Small sample and a hand-ordered queue.

## Question 3.1 (K0): what the Gold and Silver rows actually use

`k0-place-keys.csv`, `k0-summary.csv`. One primary system per row, taken from the first of `join_key_confirmed`, `chk_join_key_detail`, `place_key_type`, `place_key_found`, `finest_unit_confirmed`, `finest_unit` that gives one. 491 rows from a key column or key type, 93 inferred from the unit alone (grid, tract, point...) and 20 unknown. Stored `verify_tier` was used because 11 rows differ from a fresh `tier_of()` (nine are Bronze rows that a fresh `tier_of()` would make Silver, two are Silver rows it would make Gold; I did not investigate why the stored tiers differ); the 604 count matches the p5a report.

| System | Rows (G+S) | Where |
|---|---|---|
| GEOID/FIPS (tract, county, state, block group, block) | 145 | US 141, other 4 |
| Grid (raster) | 116 | global 66, US 20, EU 13, Asia 11 |
| Embedded geometry only | 88 | US 44 |
| Coordinates | 62 | Africa 12, US 18, global 12 |
| National statistical code | 59 | US 17 (state codes), Latin America 9, Africa 8, EU 7 |
| ISO 3166 | 30 | global 28 |
| ZCTA 21, ZIP 18 | 39 | US 33 |
| NUTS | 10 | EU 10 |
| ASGS | 6 | Australia 5 |
| ONS GSS | 5 | UK 5 |
| LAU 4, StatCan SGC/DGUID 3, GADM 1, geoBoundaries 1, OCHA P-code 1, non-geographic ID 1 | 11 | |
| none 13, unknown 20 | 33 | |

- **Levels.** US GEOID/FIPS rows: tract 26 (plus 7 that name 2010/2020 tracts and ZCTA together), county 21, state 21, block group 9, block 8, point 6. ZCTA rows are mostly tract-or-ZCTA products (NaNDA), which a single primary label cannot show. Non-US systems are thin: NUTS 10, LSOA 5, ASGS 6, StatCan 3.
- **Vintage is almost never recorded.** Only 25 of 604 rows (4%) state a vintage: 2010 (12), 2020 (4), 2021 (3), others (6). That is the largest finding: the crosswalk need (2010 vs 2020 tracts) is invisible in the inventory, so a `place_key_vintage` column is the first fix.
- **Crosswalks implied by the rows and the K1 hits.** US 2010 vs 2020 tracts (11 rows state 2010, 3 to 4 state 2020; the new California PM10/ozone row uses 2010 tracts); ZIP vs ZCTA (18 ZIP rows, 21 ZCTA rows, plus the HUD ZIP-to-tract crosswalk already in the master); LSOA 2011 vs 2021 (the new GB accessibility and Nomis rows use 2011, GreenRoute uses 2021; ONS publishes a 2011 to 2021 best-fit lookup, seen in K1); NUTS 2016/2021/2024 versions (new rows use 2021 and 2024); ASGS 2011/2016/2021. K1 found 13 unique crosswalk products (26 raw hits, mostly dated versions of ONS lookups: ONS postcode-to-LSOA, ABS suburb-to-postal-area, Eurostat postcodes to NUTS3, a Washington geographic crosswalk, a US counties correspondence) as candidates for the crosswalk list.
- **Against the landscape counts** (`place-keys-by-region-2026-10-29.csv`): the landscape counts all keys per row; this profile gives one primary key per row, so it undercounts embedded geometry (88 vs 231) and coordinates (62 vs 144). The landscape had no "grid" bucket (116 here, since I labelled gridded products that way). GEOID/FIPS is higher here (145 vs 85) because I count state and county FIPS implied by the unit, 14 of them from the unit alone. ZIP/ZCTA 39 vs 60 and ISO 3166 30 vs 45 are lower. NUTS 10 vs 11, ONS GSS 5 vs 7, StatCan 3 vs 4, ASGS 6 vs 1 (the landscape missed ASGS: it had one row). Both exclude different populations, so the two are not reconciled.
- **Classifier limit.** The "national statistical code" bucket is about half genuine (a 16-row hand sample: IBGE, INDEC, ISTAT, Statbel, KNBS, UBOS, DANE codes were real; station IDs, geometry-only and "no code named" rows were not). Treat 59 as an upper bound, near 30.

## Rows recorded (20)

Gold (10): GB Accessibility Indicators 2023 (LSOA/Data Zone, care sites; key vintage 2011); England and Wales long-term health by LSOA (Census 2011); Tampa Bay ZCTA rent burden (siblings: vacancy, home values); Pennsylvania municipal property tax and housing 2021-2023; California PM10/ozone with wildfire attribution by ZIP and 2010 tract 2006-2020; county residential air-conditioning prevalence 2010/2015/2020; California ZIP-level solar, storage and EV charging panel 2023; Queensland gaming machines by SA2; Colorado ACS 2011 by Census geography (a family of about 12 tables); NUTS3 metropolitan areas with population 2015-2022.

Silver (10), and why: Australian travel times to health services by Mesh Block (OSM extract date not stated); EEA healthcare in flood-prone areas, NUTS2 (licence not in the record); REACHOUT heatwaves (CC BY-NC-SA; unit level guessed); OEPS v3.0 (data years not stated); NYC tract ACS and public housing (ACS vintage not read); county Family Medicine linked data (source years unstated; the AMA Masterfile is licensed upstream); Living England land cover by LSOA (land-cover year not stated); GreenRoute LSOA greenspace travel times (snapshot dates not read); Dutch Interreg population by NUTS 2024 (unit inferred); LAMASUS farm payments at NUTS3 (years not stated).

Not recorded (`blocked.csv`): Hampton Roads camera locations, Energy Insecurity survey package, Census 2000 ZIP subset, PostalUp ZIP rankings (repackaged ACS), 2011 ASGS income bundle, discontinued Dutch GVA tables.

## Cautions on the recorded rows

- **Key evidence for five Dataverse rows is a search hit** (`variableName:GEOID` in a named data file), recorded as `chk_join_key_evidence`, not a read of the data file. The dataset record itself was read.
- **Unknown years are blank**, not guessed: NYC tracts, county dyads, Dutch population, LAMASUS and Living England have an empty `latest_year_final` and recency "warn".
- **Re-use risks.** AI23 and Nomis keys are 2011 LSOAs; California PM10 uses 2010 tracts; the Colorado family is static 2011 ACS.

## Fan-out seeds (for a later run, not this one)

`k2-publishers.csv`. Publishers with 3 or more new keyed datasets:

| Publisher | Catalog kind | New keyed | Comment |
|---|---|---|---|
| Colorado DOLA | Socrata catalog | 10 | Static 2011 ACS tables; low value as a seed |
| Dutch Interreg (Grensdata, via the government portal) | DCAT on data.europa.eu | 6 | NUTS labour-market and population tables; the portal is a JavaScript app, so read through data.europa.eu |
| JRC Urban Data Platform | DCAT on data.europa.eu | 6 | NUTS-level city indicators; tourism-heavy, check for health items |
| Cieplechowicz (Tampa Bay) | Zenodo creator | 3 | Independent author; ZCTA series |

Reference geography only (3 or more boundary/crosswalk hits, no keyed datasets): ONS (8 unique boundary/crosswalk hits; the 20 raw hits are dated versions of the same lookups), ABS republished on Zenodo (6), NYC City Planning (3). **To check, not verified:** publicdata.au, which republishes government CSVs to Zenodo by SA2 (two records seen: ABS boundaries and Queensland gaming machines), could be a seed for Australian small-area data.

## Recommendations

1. **Scale with changes.** Keep key search as a complement to topic search; do not use bare code tokens.
2. **Change the method:** (a) use field-level search only where the API supports it (Socrata `column_names`, Dataverse `variableName` with `type=file`, collapse files to datasets); on Zenodo, CKAN and figshare use a quoted phrase plus the unit name (for example "LSOA 2021"), never the bare column code; (b) add a health/SDOH and anchor filter before ranking (the script ranked tourism indicators first); (c) drop paper supplements before K3: Dataverse hits are 70% replication packages.
3. **Add `place_key_vintage` and `place_key_system` columns** (the K0 script is the draft: `run-p6-placekey/k0.py`), then build the crosswalk list from the 13 unique crosswalk products.
4. **Next run:** the new keyed datasets in `k2-hits-classified.csv` that were not in the 26 reads are unread; start with NUTS and LSOA collections, and the ONS lookups for the crosswalk list.

## Files

`endpoints.csv`, `k0.py`, `k0_endpoints.py`, `k0-place-keys.csv`, `k0-summary.csv`, `k1.py`, `k1-hits.csv`, `k1-searches.csv`, `k2.py`, `k2b.py`, `k2-hits-classified.csv`, `k2-handcheck-v1.csv`, `k2-measures.csv`, `k2-overlap.csv`, `k2-publishers.csv`, `k2-shortlist.csv`, `k3fetch.py`, `k3write.py`, `reads/`, `records.jsonl`, `records-tier-moves.csv`, `blocked.csv`, `checkpoint.jsonl`, `lib.py`, this report.
