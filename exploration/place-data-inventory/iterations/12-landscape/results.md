# Landscape report (Prompt 2), 2026-10-29

> **This assumes:** (1) the 601-row inventory (`inventory-combined-2026-10-29.csv`) is the baseline for phases A to E, and the 604-row file-verified merge (`inventory-combined-2026-10-29-fv.csv`; 276 Gold+Silver) is the base for F and for the counts in the headline, with the federal licence rule of 2026-10-28 (R) inside its tiers; (2) the geometry and place-key classes below come from the fields already in the inventory, mostly *listed* or *inferred*, not from re-reading pages (see `geo_class_basis`); (3) collection counts in D and E measure what a collection's own search returns for our query terms, which is a relevance proxy and not a count of usable datasets.

## Headline

We now have a first measured map of where place-based datasets are and how much of it is usable. **Geometry:** 59% of the inventory ships its own geometry, 32% is keyed to a standard geography and only 9 rows (1.5%) depend on one specific geometry dataset; eight US Census TIGER levels unlock 110 of the 195 standard-geography rows, and outside the US GADM (43 rows) plus an unidentified tail of national boundary files (21 rows) are the gaps. GEOID/FIPS is effectively a US-only key (84 of 85 rows). **Landscape (spikes):** raw anchor counts are mostly noise (about 1 in 10 Dataverse care-site hits was a facility dataset), while deprivation indices are thin but precise (27 of 30 top hits on topic). **Quiver:** 1,663 unique DataCite candidates, 1,087 `likely_relevant`, precision about 0.59 (0.49 to 0.68) on a 100-row hand check, so rules halve the page-read burden but do not remove it. **Enrichment:** only 26% of the 276 Gold+Silver rows (73) can be found in DataCite, data.gov or data.europa.eu, and metadata leaves the licence blank in 63% of those, so it cannot replace page reads. **Inventory after file verification:** 604 rows; Gold 75, Silver 201, Bronze 134, Browser needed 154, Failed 40 (before phase A and the merge: Gold 77, Silver 198, Bronze 132).

### Spike verdicts
| Spike | Verdict | Estimated cost at scale | What to change |
|---|---|---|---|
| D: counts across collections | **Extend to 30 to 50 collections, with changes** | about 2 to 3 hours of queries, plus about 1 hour for per-portal adapters | Phrase terms and title/subject fields for noisy anchors; skip ICPSR (Cloudflare) and data.gov counts until the v3 API is up; prefer CKAN/DCAT portals |
| E: top-N pulls, overlap, variables | **Worth scaling, with changes** | about 3 to 4 hours scripted (about 6,000 records, about 3,000 variable lookups) | Top-N only for anchors with an index name; variable lookup only for triaged hits with tabular files; keep fuzzy matches as "possible" |
| 2.1: priority sources | **Run 2026-10-29 (see section 2.1).** PDAPS, LawAtlas, CMS catalog, NaNDA: list in full (each with a method change); DIRAC: manual only | about 1 to 4 h per source | PDAPS: avoid the 7-111 MB pages; NaNDA and ICPSR need a browser for licences |

### Contrary evidence: the `us_epa_ucmr` tier
Phase A capped `us_epa_ucmr` to Silver ("geometry dependency TBD", no water-system geometry). The file-verification merge has it back at Gold. The fv report (`fileverify/fileverify-report-2026-10-29.md`) found that UCMR *does* have PWSID-to-ZIP files (`UCMR3_ZIPCodes.txt`, `UCMR5_ZIPCodes.txt`), contrary to the row's earlier "no ZIP field", and recommends one row per cycle. So the cap's premise has partly changed, but a ZIP list is a weaker geometry than service-area boundaries, and the row is still a generic multi-cycle row. I did not decide this; **Robert to decide whether Gold stands.**

### Ranked shortlist: collections to make primary feeds
Ranked by what was measured (relevance of top 10, depth, cost per query), not by size.
1. **data.europa.eu**: 27 of 30 top hits on topic across three anchors (10/10 on deprivation), plain DCAT API, no key. Weaknesses: publisher often just "Agent"; distributions give formats, not columns.
2. **Harvard Dataverse**: 9 of 10 on deprivation, and the only collection where file and variable metadata decided the place key (2 of 4 tabular hits showed GEOID). Needs a title filter for broad anchors (3/10 for air pollution, 1/10 for care sites).
3. **DataCite**: the quiver source: 1,087 `likely_relevant` candidates from two sweeps, with citations and geolocation fields; precision 0.59, to be used with the v2 stop-list.
4. **data.gov (catalog)**: the right feed for US federal data (19 of 30 on topic), but the keyed API returned 503 all session; use the keyless catalog search and retry the key endpoint.
5. **HDX and data.gov.au (conditional)**: cheap CKAN queries, shallow for priority-1 anchors except census and hazards; worth a trial alongside the Australia work. Not recommended: Earth Engine (title-only listing, near-zero hits) and ICPSR (blocked for scripts; needs a browser pass).

## A. Geometry source, dependencies and place keys

Files: `unit-vocabulary.csv` (60 terms), `inventory-combined-2026-10-29-geo.csv`, `inventory.csv` (regenerated; 275 rows at the time, 276 after the file-verification merge, four geometry columns added at the end), `landscape/geometry-unlocks-2026-10-29.csv`, `landscape/place-keys-by-region-2026-10-29.csv`, `landscape/geo-class-handcheck-2026-10-29.csv`, `scripts/geo_class_2026_10_29.py`.

**How sure.** Basis of the classification: confirmed 181 rows (a confirmed join key), listed 62, **inferred 358** (from unit, region and name only). Read every figure below with that split in mind. Hand-check of 22 rows (the 3 named EPA rows, 2 CDC/CEQ tract tables, 17 others): the first pass had 5 errors, all in keyword rules (a monitoring-site file read as a non-geographic ID, a negated "no FIPS field" read as a FIPS key, "identifier" read as an ID, ISO 3166 given to a Colombian municipio, a water-system row typed as polygon). All five were fixed in the rules and the 22 rows re-read as correct. A clean 22 is not a precision estimate for the 358 inferred rows.

**Geometry source (601 rows).** embedded 354 (59%), reference_standard 195 (32%), none 43 (7%), reference_specific 9 (1.5%).

### Tier changes
| Tier | Before | After |
|---|---|---|
| Gold | 77 | 74 |
| Silver | 198 | 201 |
| Bronze | 132 | 132 |
| Browser needed | 154 | 154 |
| Failed | 40 | 40 |

**Rows capped (Gold to Silver, "geometry dependency TBD"): 3.** `us_epa_ucmr` (the over-tiering we flagged: keyed to a PWS ID, no water-system geometry in the inventory), `us_epa_sdwis_lead_service_line_inventory`, `us_epa_ghgrp` (Facility ID, no lat/lon on the pages read). Three more `reference_specific`-TBD rows were already Silver or Bronze (`us_epa_sdwis_federal`, `us_epa_ucmr3_occurrence`, `global_aiddata_wb_geocoded`). One `reference_specific` row, `us_epa_airdata_pregenerated_files`, has its dependency named and in the inventory (`us_epa_aqs_sites_monitors`) and stays Gold. Gold + Silver is still 275.

### Top 15 geometry unlocks
(Rows that need that geometry; "Gold/Silver" after the cap. The geometry dataset is in the inventory for the rows marked Y.)

| # | Geometry dependency | Rows | Gold | Silver | In inventory |
|---|---|---|---|---|---|
| 1 | Census TIGER counties | 30 | 13 | 10 | Y (us_census_tiger_line_county, Silver) |
| 2 | global_gadm_boundaries (ADM0) | 27 | 0 | 8 | Y (global_gadm_boundaries, Silver) |
| 3 | Census TIGER tracts | 21 | 6 | 10 | Y (us_census_tiger_line, Silver) |
| 4 | ZIP-to-ZCTA crosswalk + Census TIGER ZCTAs | 20 | 2 | 6 | Y (us_census_zcta, Gold) |
| 5 | Census TIGER ZCTAs | 18 | 4 | 4 | Y (us_census_zcta, Gold) |
| 6 | global_gadm_boundaries | 16 | 1 | 7 | Y (global_gadm_boundaries, Silver) |
| 7 | Eurostat GISCO NUTS | 10 | 0 | 3 | Y (eu_eurostat_gisco_nuts, Bronze) |
| 8 | Census TIGER block groups | 9 | 3 | 3 | Y (us_census_tiger_line, Silver) |
| 9 | Census TIGER states | 7 | 0 | 3 | Y (us_census_tiger_line, Silver) |
| 10 | National statistics office boundary file (Latin America); not identified in the inventory | 7 | 1 | 2 | N |
| 11 | ONS Open Geography Portal boundaries | 7 | 2 | 2 | N |
| 12 | National statistics office boundary file (Africa); not identified in the inventory | 6 | 0 | 1 | N |
| 13 | TBD | 6 | 0 | 5 | N |
| 14 | National statistics office boundary file (Asia); not identified in the inventory | 5 | 0 | 0 | N |
| 15 | Census TIGER blocks | 4 | 2 | 2 | Y (us_census_tiger_line, Silver) |

Reading it: the US units (counties, tracts, ZCTAs, block groups, states) account for 110 of the 195 reference_standard rows through eight TIGER-derived dependencies (counties, tracts, ZCTAs, ZIP-via-crosswalk, block groups, states, blocks, a ZIP spelling variant), and our single `us_census_tiger_line` row stands in for all of them. Outside the US, **GADM (ADM0 and ADM1+) is the dependency of 43 rows**, mostly country-level statistics, and a long tail of national statistics-office boundary files (Latin America 7, Africa 6, Asia 5, other 3) are not in the inventory at all. The standard-geography dependencies look cheap; the national-boundary tail is the part with no known source.

### Place-key prevalence by region (rows; a row can carry two keys)
| Place key | Total | US | EU | UK | Canada | Australia | Africa | Asia | Latin America | global |
|---|---|---|---|---|---|---|---|---|---|---|
| embedded geometry | 231 | 83 | 29 | 6 | 1 | 3 | 5 | 7 | 12 | 83 |
| coordinates | 144 | 52 | 9 | 7 | 4 | 2 | 16 | 6 | 5 | 38 |
| GEOID/FIPS | 85 | 84 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| ISO 3166 | 45 | 0 | 1 | 0 | 1 | 0 | 1 | 1 | 0 | 41 |
| none | 43 | 21 | 9 | 2 | 0 | 0 | 1 | 2 | 6 | 2 |
| ZIP code | 41 | 30 | 3 | 0 | 2 | 1 | 0 | 0 | 1 | 4 |
| national statistical code | 21 | 0 | 0 | 0 | 0 | 0 | 6 | 5 | 7 | 0 |
| ZCTA | 19 | 18 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| NUTS | 11 | 0 | 11 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| non-geographic ID | 11 | 9 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| ONS GSS | 7 | 0 | 1 | 6 | 0 | 0 | 0 | 0 | 0 | 0 |
| StatCan SGC/DGUID | 4 | 0 | 0 | 0 | 4 | 0 | 0 | 0 | 0 | 0 |
| HUC | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| OCHA P-code | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| GADM | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| ASGS | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| geoBoundaries | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| LAU | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| H3 index | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

(`other` region, 10 rows, is in the CSV only.) What stands out:
- **GEOID/FIPS is a US-only key (84 of 85 rows) and the only standard code with real weight.** Outside the US the standard keys are thin: NUTS 11 (EU), ONS GSS 7 (UK), StatCan 4, ASGS 1, OCHA P-code 2. For Africa, Asia and Latin America the key is almost always a national statistics code (18 rows) or coordinates; there is no shared code to join on, which is why those regions lean on geometry that ships with the data.
- **Most of the world joins on geometry, not on a code**: 231 rows embed geometry and 144 carry coordinates. For US rows the 84 GEOIDs and 30 ZIP codes dominate. 41 rows are keyed by ZIP code, which is *not* a ZCTA; they need a crosswalk (`us_hud_usps_zip_crosswalk` is in the inventory but is Browser needed).
- 43 rows have no usable key (21 in the US): mostly Miami-Dade layers and cohort studies with no row-level facts yet.

### `TBD` dependencies worth finding first
1. **Public water-system service-area boundaries** (4 rows: `us_epa_ucmr`, `us_epa_ucmr3_occurrence`, `us_epa_sdwis_federal`, `us_epa_sdwis_lead_service_line_inventory`). Every EPA drinking-water row stops here. A candidate (EPA's service-area boundaries dataset) is *not* verified; verify before relying on it.
2. **GHGRP facility locations** (`us_epa_ghgrp`; a crosswalk to FRS is plausible but not read on a page).
3. **National statistics-office boundary files**, grouped by region (21 rows, no identified source). Identify per country, starting with the countries that have a WG interest.
4. (Not TBD but unverified) the ZIP-to-ZCTA crosswalk, which gates 20 ZIP-keyed rows; its inventory row is Browser needed.

## D. Collection table and anchor counts (spike)

Files: `landscape/collections-2026-10-29.csv`, `landscape/anchor-counts-2026-10-29.csv`, `landscape/anchor-counts-2026-10-29.png` (log colour, anchors in priority order), `scripts/landscape_d.py`.

**What ran.** 10 collections listed; counts for 8 of them (96 cells filled, plus ICPSR and data.gov skipped, see below). **Skipped:** ICPSR (search is behind a Cloudflare challenge, 403; not bypassed) and **data.gov** (the GSA key endpoint returned HTTP 503 "no healthy upstream" for every call all session; the keyless `catalog.data.gov/search` works but gives a cursor and no total, so no count is possible). The data.gov key was sent only as a header to api.gsa.gov and is not written anywhere. NASA CMR cannot OR keywords, so its count is the union of concept ids over one query per term (about 95 requests instead of 12). Earth Engine has no search API: the count is a title match over the full listing of 1,165 entries, so it understates (title only).

**Method caveats.** A count is how many records the collection's own search returns for an anchor's OR-ed phrases (datasets only; years ≥ 2000 where the API took a filter: DataCite and Zenodo yes; Dataverse, europa, HDX, data.gov.au no). Single words like "hospital", "income", "pharmacy" pull in clinical trials and generic statistics: the counts below are an upper bound on relevance, not a count of usable place-based datasets. Phase E shows how loose that bound is. The `data.gov.au` column in the heatmap is cut to "DATA.GOV.A".

| Anchor (priority) | DataCite | Dataverse | Zenodo | data.europa.eu | HDX | data.gov.au | NASA CMR | Earth Engine (title) |
|---|---|---|---|---|---|---|---|---|
| care_sites (1) | 95,127 | 9,865 | 19,250 | 14,797 | 2,034 | 2,777 | 52 | 0 |
| deprivation_indices (1) | 456 | 67 | 60 | 27 | 2 | 0 | 31 | 0 |
| census_ses (1) | 188,728 | 43,105 | 25,050 | 91,994 | 11,082 | 6,358 | 601 | 0 |
| heat (1) | 5,436 | 119 | 967 | 263 | 5 | 655 | 2,896 | 0 |
| water_hazards_fire (1) | 109,938 | 1,750 | 9,397 | 25,491 | 3,790 | 3,143 | 4,443 | 7 |
| health_policy (2) | 812 | 1,077 | 42 | 78 | 4 | 94 | 50 | 0 |
| air_pollution (3) | 37,024 | 477 | 2,012 | 5,360 | 887 | 607 | 2,650 | 0 |
| subnational_development (4) | 311 | 52 | 37 | 42 | 179 | 278 | 17,702 | 0 |
| toxic_releases (5) | 290 | 37 | 41 | 242 | 0 | 10 | 101 | 0 |
| drinking_water (5) | 58 | 5 | 10 | 0 | 0 | 0 | 29 | 0 |
| algal_blooms (5) | 5,589 | 44 | 563 | 138 | 0 | 351 | 1,738 | 0 |
| built_environment (5) | 14,387 | 719 | 2,070 | 2,563 | 187 | 274 | 938 | 13 |

**Where the depth is, and the thin anchors.**
- Depth (by raw count) is in `census_ses`, `water_hazards_fire`, `care_sites` and `air_pollution`, on DataCite, Dataverse, Zenodo and data.europa.eu. For `care_sites` and `census_ses` that depth is mostly noise from broad terms (see E: only about 1 in 10 Dataverse `care_sites` hits was a facility or service dataset).
- **Thin: `deprivation_indices`** (priority 1) has 2 to 456 hits per collection, and `drinking_water`, `toxic_releases`, `health_policy` have tens. Thin does not mean empty: the top 10 for deprivation was the most relevant of the three anchors tested in E. Thin anchors are best fed by named-source lookups (the index owners) and not by collection sweeps.
- NASA CMR's 17,702 for `subnational_development` is a keyword artefact (terms like "water access" and "poverty map" matching Earth-observation metadata), not a finding. HDX is shallow for priority 1 anchors except `census_ses` and `water_hazards_fire`.
- Earth Engine's title match is near zero everywhere, as expected for a raster catalog with product-name titles.

### Spike verdict (D)
**Extend to 30 to 50 collections: with changes.** (1) Fix relevance before scale: counts from single broad words are not usable; use phrase terms for the high-noise anchors, restrict to title/subject fields where the API allows, and report counts only as a ranking aid. (2) Skip or defer collections that can't count (ICPSR; data.gov until the v3 API is up). (3) Prefer CKAN and DCAT portals (HDX, data.gov.au, data.europa.eu and other national portals): one query each, 1 to 2 minutes per collection. Estimated time at 30 to 50 collections: **about 2 to 3 hours** of scripted querying (8 collections took roughly 35 minutes elapsed, dominated by CMR's per-term queries and the Earth Engine listing), plus about 1 hour to write per-portal query adapters. What the spike did show: the same OR query needs a different dialect on every API (Lucene, Solr `fq`, a pipe-separated form for europa, single keyword for CMR); that adapter work is the real cost.

## E. Top-N pulls and overlap (spike)

Files: `landscape/spike-e-2026-10-29.csv` (90 records: 3 anchors × 3 collections × 10), `scripts/landscape_e.py`. Anchors: care_sites, deprivation_indices, air_pollution. Collections: Harvard Dataverse, data.europa.eu, data.gov (via the keyless `catalog.data.gov/search`, since the v3 key endpoint was down).

**A slip to record.** While debugging the Dataverse variable lookup I issued one request to the file-download endpoint of a single dataset file (`deprivation.tab`, 5.8 MB), by mistake (I had meant a metadata endpoint). It was read into memory, only its header line was printed, nothing was written to disk, and the final script uses only the metadata endpoints. It still broke the "fetch metadata only" rule; stating it here so it is on the record.

### Relevance of the sample (my reading of the titles; "on topic" is not "usable")
| Collection | care_sites | deprivation_indices | air_pollution |
|---|---|---|---|
| Harvard Dataverse | 1/10 (a state hospital-report dataset; the rest are clinical-study replication data) | 9/10 (county deprivation scores, EJI ×3, Neighborhood Atlas, Community Deprivation Index, GRDI ×2, SVI grids) | 3/10 (the Wei et al. ZIP-code PM2.5/O3/NO2 data ×2 and an NSAPH PM2.5 evaluation; the other 7 are ozone-generator and MOSES-study files, an "ozone" false match) |
| data.europa.eu | 9/10 (8 are Slovak radiation-oncology activity reports, national yearly totals; plus Greek psychiatric clinics) | 10/10 (Pobal HP, IRIS-level FDep, EDI) | 8/10 |
| data.gov | 4/10 (dialysis clinics, VA pharmacy, primary-care utilisation; "office visit costs" series are not place data) | 9/10 (several are COVID-death tables or dashboards that merely use SVI) | 6/10 (CDC WONDER daily PM2.5, EPA county PM2.5, NYCCAS rasters; EPA ORD research-output records pad the rest) |

So 13/30, 27/30 and 19/30 on topic. The OR query worked best for the index-name anchor (deprivation) and worst for the generic-word anchors (care sites, air pollution on Dataverse).

### Overlap
- **Against the inventory (601 rows): 4 of 90 records matched, all as "possible" (fuzzy title), none by DOI or URL**: two Dataverse EJI datasets (`us_cdc_eji`), data.europa.eu "Pobal HP Deprivation Index" (`ie_pobal_hp_deprivation_index`), and a King County SVI dashboard (`us_cdc_svi`). The overlap is about 4% and every hit is a re-host or derivative of a product we already have, so the collections mostly surface candidates the inventory does not hold.
- **Across collections: 5 records, all "possible" (title)**: SEDAC's Global Gridded Relative Deprivation Index (Dataverse ranks 7 and 8, data.gov rank 7) and SEDAC's US SVI Grids (Dataverse 10, data.gov 5). The same SEDAC products show up under two collections, which argues for de-duplicating on title plus publisher and not on DOI alone (the data.gov records carry no DOI here).
- data.europa.eu's `publisher` field came back as the literal word "Agent" for a third of records, so publisher-plus-product matching is weak there; the field needs a better parse.

### Variable-level place keys (Dataverse, 10 hits probed)
- 10 hits: **4 had tabular files**, 6 had none (zip, xlsx, pdf, or non-ingested files, so no variable metadata exists to read).
- Of the 4 with tabular files, **2 showed a place key in the variable names**: the county deprivation scores (`geoid`) and the EJI tract table (`STATEFP; COUNTYFP; TRACTCE; GEOID`). The other two (an MRI study, a breast-cancer study) had none and are not place data.
- Cost: 2 requests per dataset (file list, then variable metadata for up to 2 tabular files), metadata only. Variables come from `/api/access/datafile/<id>/metadata`; the `/metadata/ddi` form returns 406 on Harvard's server.
- Reading: **when a hit is real place data, the variables settle its key.** For the 2 most valuable hits it was decisive and cheap; for non-place data it only confirms exclusion. Only 4 of 10 hits had anything to read, so this works only for ingested tabular files.

### Spike verdict (E)
**Worth scaling: with changes.** (1) Pull top-N only for anchors with an index name or distinctive phrase; broad-word anchors need a title filter first. (2) Run the file and variable lookup only on hits already triaged `likely_relevant`, and only where the file list shows a tabular file. (3) Keep all matching as "possible" unless DOI or normalised URL agrees. (4) Full-scale cost estimate: 12 anchors × 10 collections × top 50 is about 6,000 records at 1 request per page of 50 to 100 (about 2 hours, mostly CKAN and DCAT portals), plus the variable lookup at 2 requests per Dataverse-style hit: for roughly 1,500 triaged hits that is about 3,000 requests, or **about 1 hour**. Total about 3 to 4 hours scripted. Not tested here: Dataverse installations other than Harvard, and whether DCAT portals expose column names at all (data.europa.eu returned distribution formats only).

## B. The quiver, folded into one triaged candidates file

Files: `landscape/candidates-2026-10-29.csv`, `landscape/candidates-skipped-2026-10-29.csv` (1,277 Australian rows without "Australia" in the title), `landscape/stoplist-2026-10-29.csv`, `landscape/candidates-precision-sample-2026-10-29.csv` (100 rows, my labels), `scripts/landscape_b.py`.

**Merge.** Inputs: DataCite pilot 1,006 + DataCite Australia 626 kept (1,277 skipped) + phase E sample 90. After de-duplication by DOI (or title plus publisher), **1,663 unique candidates**: 1,087 `likely_relevant`, 179 `maybe`, 397 `unlikely`. Only 1 candidate is already in the inventory by DOI or URL (the 4 fuzzy phase E matches are left as "possible" and not counted). The rules, in code: `likely_relevant` = an anchor term in the title AND a place unit or geography word in the title, not a paper supplement, year ≥ 2000, not a single event, not on the stop-list; `maybe` = one of the two; the rest `unlikely`. Stop-list (small, in its own CSV): paleoclimate/model output, cell and molecular biology, species and plant censuses, marine heatwaves, emission factors, quantum/acoustic noise, planetary science, one publisher (an archaeology series). **v1.1 note:** the first pass put two species censuses (frog, petrel) and a clinical file at the top of the citation ranking, so I added frog/petrel/penguin/albatross/wildlife and clinical-data/restricted-survey patterns; that moved 18 rows to `unlikely` (1,105 to 1,087 `likely_relevant`). The precision sample below was drawn and labelled under v1.

### Counts of `likely_relevant` by anchor and region

| Anchor | Total | US | Australia | UK | EU | Canada | Africa | Asia | Latin America | global | unspecified |
|---|---|---|---|---|---|---|---|---|---|---|---|
| census_ses | 379 | 168 | 113 | 8 | 3 | 1 | 12 | 9 | 1 | 8 | 56 |
| water_hazards_fire | 251 | 60 | 74 | 3 | 8 | 0 | 2 | 18 | 9 | 7 | 70 |
| heat | 242 | 15 | 23 | 0 | 5 | 0 | 0 | 44 | 1 | 113 | 41 |
| care_sites | 75 | 6 | 45 | 0 | 0 | 1 | 3 | 2 | 2 | 0 | 16 |
| deprivation_indices | 68 | 25 | 6 | 1 | 5 | 0 | 0 | 0 | 2 | 5 | 24 |
| air_pollution | 36 | 9 | 26 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| built_environment | 25 | 0 | 25 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| algal_blooms | 18 | 0 | 18 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| drinking_water | 18 | 0 | 18 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| subnational_development | 6 | 0 | 6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| health_policy | 5 | 0 | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| toxic_releases | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **all rows** | **1087** | 281 | 330 | 11 | 21 | 2 | 17 | 72 | 15 | 134 | 204 |

Note: a candidate with two anchors is counted under both, so anchor totals add to more than the row total. Region comes from title keywords only; 205 rows stay `unspecified`. The Australian share (344) comes from the Australia pull, so it reflects what was searched, not where the data is.

### Precision (hand-check of a random 100 `likely_relevant` rows, titles only)

**59 of 100 were place-based datasets on the anchor topic (precision about 0.59; a 95% interval of roughly 0.49 to 0.68).** "Place-based" was judged from the title alone, and 59% should be read as "a plausible candidate worth a page read", not as confirmed usable data. The 41 misses fall into patterns the rules can drop: (a) individual-address records (7: "WPA household census for 1537 SYDNEY DR, Los Angeles County", a historical series matched by "census" and "Sydney"); (b) single-station time series (5: "SBC LTER Precipitation at ..."); (c) ecology, engineering or health-study data that merely contain a term ("bioretention basin in Melbourne", "heatwaves on body mass in a passerine", "dermatomyositis ... neighbourhood deprivation"); (d) model simulations and input cubes; (e) single events. A further finding: **many "likely" rows are repeats of one product** (yearly files of a seamless 1 km land-surface-temperature product, MODIS LST versions, ACS extracts per Texas county), so the number of distinct products is well below 1,087. These patterns are listed for a v2 stop-list; I did not apply them, so the 59% stands for the rules as run.

### The 20 strongest new candidates

Ranked by anchor priority, citations, a geolocation field in the DataCite record, recency and a unit word; one per title series; not already in the inventory. Titles read by hand; none has been page-verified, so treat each as a lead.

| # | Anchor(s) | Year | Publisher | Cit. | Title | DOI |
|---|---|---|---|---|---|---|
| 1 | census_ses | 2026 | ICPSR - Interuniversity Consor | 103 | National Neighborhood Data Archive (NaNDA): Socioeconomic Status and Demographic Characteristics of  | 10.3886/icpsr38528 |
| 2 | heat | 2015 | NASA Land Processes Distribute | 106 | MOD11A1 MODIS/Terra Land Surface Temperature/Emissivity Daily L3 Global 1km SIN Grid V006 | 10.5067/modis/mod11a1.006 |
| 3 | heat | 2021 | NASA Land Processes Distribute | 58 | MODIS/Terra Land Surface Temperature/Emissivity Daily L3 Global 1km SIN Grid V061 | 10.5067/modis/mod11a1.061 |
| 4 | heat | 2015 | NASA Land Processes Distribute | 53 | MYD11A1 MODIS/Aqua Land Surface Temperature/Emissivity Daily L3 Global 1km SIN Grid V006 | 10.5067/modis/myd11a1.006 |
| 5 | water_hazards_fire | 2022 | NERC EDS Environmental Informa | 7 | Gridded estimates of hourly areal rainfall for Great Britain 1990-2016 [CEH-GEAR1hr] v2 | 10.5285/fc9423d6-3d54-467f-bb2b-fc7357a3941f |
| 6 | census_ses | 2019 | Palisades, NY: NASA Socioecono | 6 | Global Population Projection Grids Based on Shared Socioeconomic Pathways (SSPs), Downscaled 1-km Gr | 10.7927/h44747x4 |
| 7 | heat | 2021 | NASA Land Processes Distribute | 18 | MODIS/Aqua Land Surface Temperature/Emissivity Daily L3 Global 1km SIN Grid V061 | 10.5067/modis/myd11a1.061 |
| 8 | water_hazards_fire | 2022 | NERC EDS Environmental Informa | 3 | Gridded simulations of available precipitation (rainfall + snowmelt) for Great Britain, developed fr | 10.5285/755e0369-f8db-4550-aabe-3f9c9fbcb93d |
| 9 | heat | 2023 | NERC EDS Centre for Environmen | 2 | HadISDH.extremes: gridded global monthly land surface wet bulb and dry bulb temperature extremes ind | 10.5285/2d1613955e1b4cd1b156e5f3edbd7e66 |
| 10 | deprivation_indices | 2020 | CEHI | 1 | Neighborhood Deprivation Index for year 2010, using the 2010 census geographic boundaries | 10.25614/ndi_2010_trt_allstates |
| 11 | census_ses | 2025 | NERC EDS Environmental Informa | 1 | UK gridded population at 1 km resolution for 2021 based on Census 2021/2022 and Land Cover Map 2021 | 10.5285/7beefde9-c520-4ddf-897a-0167e8918595 |
| 12 | heat; water_hazards_fire | 2018 | PANGAEA | 1 | A monthly air temperature and precipitation gridded dataset on 0.025° spatial resolution in China du | 10.1594/pangaea.895742 |
| 13 | census_ses | 2021 | ADA Dataverse | 5 | The Household, Income and Labour Dynamics in Australia (HILDA) Survey, GENERAL RELEASE 20 (Waves 1-2 | 10.26193/yp7mnu |
| 14 | census_ses; deprivation_indices | 2022 | Harvard Dataverse | 4 | 2022 Social Vulnerability by US Census Block Group | 10.7910/dvn/arbhpk |
| 15 | census_ses; deprivation_indices | 2025 | Harvard Dataverse | 0 | Extracted Data From: CDC/ATSDR Social Vulnerability Index | 10.7910/dvn/mzf7xq |
| 16 | deprivation_indices | 2023 | Rice University-Kinder Institu | 0 | Social Vulnerability Index - H-GAC 13-County Extract | 10.25612/837.yg7x97rp03ky |
| 17 | deprivation_indices | 2025 | ICPSR - Interuniversity Consor | 0 | Global Gridded Relative Deprivation Index (GRDI), Version 1 | 10.3886/e240845v1 |
| 18 | deprivation_indices | 2025 | Rice University-Kinder Institu | 0 | Mobile Air Toxics Data in Environmental Justice Communities in Harris County | 10.25612/837.63na8lee52rd |
| 19 | deprivation_indices | 2020 | Rice University-Kinder Institu | 0 | CDC Social Vulnerability Index 2018, 2016, 2014, 2010, and 2000 Database - H-GAC 13-County Extract | 10.25612/837.m7d9qk31lj2m |
| 20 | census_ses | 2025 | Rice University-Kinder Institu | 0 | Majority Race/Ethnicity by CTA and Census Tract in Harris County (American Community Survey) | 10.25612/837.x4wg6dk6m90p |

Reading the list: the real value is in the first rank (NaNDA socioeconomic and demographic tables by tract and ZCTA, a family of NaNDA products we could mine as a whole), the SEDAC and NERC EDS gridded products, the Neighborhood Deprivation Index and CDC SVI re-extracts (these are re-hosts of products already in the inventory, so they are "same product, different host" and not new sources), and MODIS LST (a raster family, `needs_raster` in our terms). Few of the 20 are new place-based *health-relevant* sources, which is itself a finding about what a DataCite title sweep returns.

## F. Enrichment of the Gold+Silver rows, and citations

Files: `landscape/enrichment-275-2026-10-29.csv` (276 rows; the name keeps the "275" of the prompt), `landscape/citations-200-2026-10-29.csv`, `scripts/landscape_f.py`. Base: `inventory-combined-2026-10-29-fv.csv` (the script was pointed at it because `inventory.csv` now holds the 276 fv rows). The first run (207 rows) used the 601-row geo file and the rest used the fv file; the one tier that differs (`us_epa_ucmr`) was refreshed from fv at the end. The run resumed from `checkpoints/F-enrich.json` without redoing rows.

### Enrichment: can metadata replace page reads?
**Largely no, for this inventory.** 73 of 276 rows (26%) matched a record in DataCite, data.gov or data.europa.eu (Gold 17 of 75, Silver 56 of 201); 203 found nothing. By source: DataCite 60 (40 by DOI, 16 by exact title, 4 by landing URL), data.gov 21, data.europa.eu 3 (overlaps allowed). The inventory is mostly federal agency pages, national portals and project sites that those indexes do not hold. Title matches needed similarity of 0.9 or more, so matching is conservative.

Agreement with the part B values, among matched rows only (73):
| Field | Agree | Differ | Metadata empty | Other |
|---|---|---|---|---|
| Licence | 3 | 3 | 46 | 21 cannot compare |
| Years | 45 | 23 | 1 | 4 part B empty |
| Spatial | not compared | not compared | 48 | 25 have a spatial field |

- **Licence:** metadata is empty for 46 of 73 (63%), so it rarely settles a licence. Of the 6 comparable pairs, 3 differ, and the differences are informative: `global_sedac_infant_mortality_v2` (DataCite says CC BY 4.0; the page says "openly shared" under NASA EOSDIS guidance), `global_cred_emdat` (DataCite carries CC0/open access; the page states non-commercial EM-DAT terms) and `us_usda_naip` (a CC0 tag against Public Domain with Attribution on the AWS registry). Where a repository tag and the publisher's own terms disagree, follow the publisher's page and flag the row.
- **Years:** 45 of 68 comparable pairs agree within a year. Most of the 23 that differ are a real difference in what is measured: metadata gives the *publication* year (2023 for the European Settlement Map and the World Settlement Footprint) where we record the *data* epoch (2015, 2019). A DataCite year cannot stand in for temporal coverage.
- **Spatial:** only 25 of 73 matched records carry a spatial field, mostly a place name or box, which does not give a unit or geometry source.
- **Verdict (F, enrichment):** cheap (about 3 requests per row) and useful as a cross-check and DOI/citation finder for the 26% it reaches, but it does **not** replace page reads: licence is usually blank and years are publication years.

### Citations for the top 200 candidates
Selection: 200 `likely_relevant` candidates with a DOI, not already in the inventory, ranked by anchor priority, citations (log) and a geolocation field, with a small penalty for known repeat series. **90 of 200 have one or more DataCite citations; 121 have at least one OpenAIRE ScholeXplorer link.** The DataCite counts equal the quiver's citation field in all 200 cases, so a second lookup of the same source added nothing; Scholix is the new signal (links to papers and datasets, as source or target).

Top by citations: MODIS MOD11A1 LST v006 (106; 134 Scholix target links), NaNDA socioeconomic and demographic tables (103; 3 source, 24 target), MOD11A2 (66), MOD11A1 v061 (58), MYD11A1 (53). The MODIS raster family dominates; the highest-cited tabular, tract-level product is the NaNDA table. With 110 of 200 uncited, citations are a tie-breaker, not a filter.


## Next steps
1. Run `PROMPT-2.1-priority-sources-spike.md` (priority 1 to 2 sources, in full).
2. Build the v2 stop-list from the precision misses (individual-address records, single-station series, studies that merely contain a term, model output, single events) and group repeat product families before any page reads.
3. Find the TBD geometry dependencies first: water-system service areas, GHGRP facility locations, the ZIP-to-ZCTA crosswalk (gates 20 rows), national boundary files for WG countries.
4. Decide the `us_epa_ucmr` tier (see the contrary-evidence note above) and whether to split it per cycle.
5. If scaling D: write adapters for the 5 to 6 CKAN/DCAT portals first; retry the data.gov v3 key endpoint.

## Time and usage
Phases A, D, E, B and F ran in that order, then R. Phase D skipped counts for ICPSR and data.gov (reasons in D); phase 2.1 was not part of this run. Phase F resumed from its checkpoint (207 of 276 rows), finished the remaining rows and the 200-candidate citation step in one run. Requests stayed at about 1 per second per host. One rule slip is recorded in E (a single 5.8 MB data file was read into memory by mistake and not saved). Nothing was committed or deleted.

## 2.1 Priority sources spike (2026-10-29)

Method: one process, metadata only, no data downloads, 2 s between requests, the Prompt 2 user-agent (no email). Rows: `spike-2.1-2026-10-29.csv` (43 rows: 10 each for CMS, PDAPS, LawAtlas, NaNDA; 3 for DIRAC). Geometry columns use the `unit-vocabulary.csv` / inventory terms (`embedded`, `reference_standard`, `none`). Inventory check is against `inventory-combined-2026-10-29-fv.csv` (604 rows).

**What slowed or blocked me**
- PDAPS dataset pages are 7 to 111 MB each because the whole law corpus is embedded as JSON. I fetched five pages to read effective dates, then deleted them. That is more than "metadata only" strictly intends; at scale, don't do this (see verdict).
- `nanda.isr.umich.edu` and `doi.org/10.3886/ICPSR…` (ICPSR) both returned a bot-challenge page (403). I listed NaNDA through DataCite instead.
- LawAtlas `/datasets` is 404 and `/data-licensing` is 404; licence is therefore unconfirmed.
- DIRAC pages load their tables by script; I found no JSON endpoint and did not look for one beyond the page links.

### What each source holds and how it can be listed

| Source | Holds | Listing route |
|---|---|---|
| IAEA DIRAC | Directory of radiotherapy centres worldwide. Public: country-level aggregate views (centres, availability, equipment age). Facility-level detail is on request to academic/government/international bodies only; contacts and machine makes are withheld. | **Manual only.** No API or download found. |
| CMS Provider Data Catalog | 237 datasets (hospitals 75, physician office costs 85, dialysis 23, nursing homes 18, home health 11, clinicians 9, hospice 8, other 8). | **API.** DKAN metastore returns the whole catalog as DCAT JSON in one call. It carries title, theme, modified date and next update, but no spatial, temporal or licence field. |
| PDAPS | Opioid/drug-policy datasets (about 39 slugs on the index page): state laws with per-state `effective` and `through` dates (five read: 2001 to 2023 spans). 50 states plus DC; no local laws seen. | **Catalog page** (static slugs). No API. |
| LawAtlas | Temple CPHLR policy-surveillance datasets, same MonQcle platform as PDAPS. Each page states Valid From, Updated Through and jurisdiction count (25 to 53). One dataset (Local Eviction Laws) is city-level (30 cities). | **Catalog page** (`/explore-topics` shows only 13 slugs; the full list needs "View All Datasets", not tested). No API. |
| NaNDA | ICPSR/openICPSR series of tract and ZCTA measures, mostly 1990-2021 for the newer e-series. | **API via DataCite** (321 DOIs, about 28+ distinct families after merging versions). ICPSR and the NaNDA site are bot-blocked. |

**Contrary evidence / questions first**
- PDAPS and LawAtlas overlap: both carry a PDMP dataset (PDAPS `pdmp-mandates` 2014-2019, LawAtlas 2014-2023). Is LawAtlas the successor? I did not confirm; treat as one family until checked.
- The Prompt 2 note calls policy "priority 2", but the effective dates that make policy data usable are exactly what the pages expose, so cost per item is low and value per item is high. That is my reading, not a tested claim.
- 8 of the 10 NaNDA families I listed are not in the inventory (Land Cover and Health Care Services are). The inventory already holds 7 NaNDA rows (land cover, health care, traffic, grocery, recreation, broadband, socioeconomic). Matching is by family name only.

### Strongest additions

- **Care sites (radiotherapy):** nothing in CMS is a radiotherapy facility list. The closest are the 11 PPS-exempt cancer hospitals (`z8ax-x9j1`) and the CMS Radiation Oncology Office Visit Costs table (`288b-4bed`, not opened). DIRAC is the real radiotherapy source but is not machine-listable and its facility records are restricted. Best CMS additions otherwise: `hbf-map` (already geocoded, so `embedded` geometry, no crosswalk), and IRF, LTCH, VHA and hospice/home-health ZIP datasets (not in the inventory).
- **Policy:** the five PDAPS and ten LawAtlas datasets above, none in the inventory. Joining needs only state FIPS (plus effective dates), so no geometry dependency beyond TIGER states. The longest PDAPS spans (Good Samaritan 2007 to 2023, naloxone 2001 to 2022) are the most useful for a time-varying exposure.
- **NaNDA:** Street Connectivity, Parks, Roads, Polluting Sites, Transit Stops, Libraries, Law Enforcement, Social Services. All tract/ZCTA; dependency is Census TIGER tracts and ZCTAs, already a known unlock.

### Spike verdicts

| Source | List in full? | Estimated time |
|---|---|---|
| IAEA DIRAC | **Manual only.** Record as one inventory row (country-level aggregates public; facility data by request). Worth an email to dirac@iaea.org, which is Robert's call. | 15 min for the row; the request is outside this workflow |
| CMS Provider Data Catalog | **Yes.** One API call yields all 237 items; filter to those with a place key (my guess is about 60; not counted) (facility, ZIP or state). Add licence and years from each dataset's own page or data dictionary, which is the slow part. | about 1 h to list; 3 to 4 h to fill licence/years/place key |
| PDAPS | **Yes, with a change of method.** 39 slugs from the index, but get effective dates from one lightweight page or the data dictionary, not from the 7 to 111 MB pages. | about 1.5 h, after finding a lighter route |
| LawAtlas | **Yes.** Pages are small (about 40 KB) and uniform (Valid From / Through / jurisdictions). Need the full dataset list first (View All Datasets), and licence is unresolved. | about 2 h (list size unknown, estimate assumes 50 to 100 datasets) |
| NaNDA | **Yes via DataCite**, but licence and exact years need ICPSR pages, which are bot-blocked. Verify in a browser pass if licence is required. | about 1 h to list; licence needs the browser queue |

Files written: `landscape/spike-2.1-2026-10-29.csv` and this section. Raw probes stayed in the scratchpad; nothing was downloaded to the workspace.
