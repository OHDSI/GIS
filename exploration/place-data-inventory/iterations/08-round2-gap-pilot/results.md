# Round 2 preview: gap sweeps (2026-10-28), a pilot

**This assumes:** the round-1 inventory is `inventory-refined-2026-10-28.csv` (571 rows: the 574 ids of the 10-23 file less the three trimmed after the browser check); the trim rules are those of `trim-2026-10-22-report.md`; nothing here is merged into the inventory. Everything written by this run is under `docs/discovery/round2/`.

**What ran.** One of the five planned sweeps completed: **sweep 1, health-facility registries** (cap 30; 44 searches, 57 pages read, 18 minutes, 2026-10-28 19:56 to 20:14 UTC). Sweeps 2 to 5 were launched twice and stopped both times by the usage limit (five agents in parallel at about 20:15 UTC, then two at about 20:45 UTC). Robert then paused them for budget. Two of the stopped agents had saved partial files before they were cut off: `sweeps/sweep2-transport.json` (15 rows, marked finished) and `sweeps/sweep3-hazards.json` (4 rows, not finished). **Per instruction they are not merged and not link-checked**; they are listed at the end so the rows are not lost.

## Sweep 1: health-facility registries

| | count |
|---|---|
| Candidates written by the sweep | 25 |
| Kept after the trim rules (all 2015 or later, national, maintained) | 25 |
| Already in inventory (matched by URL): HRSA health-center sites = `us_hrsa_health_center_sites` | 1 |
| **New** | **24** |
| Also recognised as round-1 products and not written as rows | 4 (GRID3 Nigeria v3.0 is newer than the round-1 record; the HDX mirror of the KEMRI-Wellcome database; HRSA HPSA/MUA; NHS ODS GP practices) |

Coverage of the 24 new rows: US 4 (NPPES, CMS dialysis, home health, hospice), GB 4 (NHS ODS organisations, CQC care directory, Scottish hospital codes, HIW Wales register), CA 1, AU 2, NZ 1, DE 1, FR 2, ES 1, BR 1, IN 1, KE 1, NG 1, sub-Saharan Africa 1, SL 1, ZM 1, global 1 (Healthsites.io). Confidence: high 5, medium 12, low 7 (the low rows are those whose pages were blocked, so fields came from snippets or mirrors). All 24 are point or address data, so `gaia_fit = needs_aggregation` (distance or count to the patient's area); the address-only ones (CMS, NHS ODS, CQC, Destatis, Spain, NZ) also need geocoding. One exception worth noting: the Scottish hospital codes file carries data zone and council area codes, so it could join as a table now.

## Link health (part A, 24 new rows; `verify-A-2026-10-28.csv`, 240 log entries in `verify-log-round2.csv`, run `A-round2-20261028`, 1.9 minutes)

| url_health | rows | what it means here |
|---|---|---|
| healthy | 14 | live, names the dataset, no withdrawal language; 9 also pass the access-URL check, 4 have no access URL to check, 1 warns |
| degraded | 7 | live but: the three CMS provider-data download URLs the sweep recorded answer **404** (dialysis, home health, hospice: the landing pages are JavaScript apps, the URLs need re-reading in a browser); NPPES, CQC, Spain and CNES have no machine-readable metadata; CNES and CQC have no download URL on the page |
| blocked | 3 | NHS ODS DSE (403), Health NZ code tables (robots.txt), KMHFL Kenya (timeout; the open.africa mirror answers 403). NHS ODS and Health NZ are in `browser-queue-2026-10-28.csv`; KMHFL (timeout) is not yet |

No withdrawn pages. Wayback snapshots exist for 18 of 24. The NPPES download page said "down for maintenance" on the day, so NPPES fields came from the CMS data-dissemination page instead.

## Best new finds (new, link-healthy, and with coordinates or a licence read from the page)

1. **FINESS extraction (France, ANS/Ministry)**: every health, social and medico-social establishment with projected coordinates, Licence Ouverte, data to 2026-05; plus the **Atlasanté t_finess** geocoded version (re-geocoded every two months). Both pass the core link checks (live, redirect, TLS, soft-404, withdrawn, access URL); like every round 2 row, they warn on persistent ID or archive.
2. **National HealthDirect Health Facilities (Geoscience Australia)**: hospitals, GPs and pharmacies as points, CC BY 4.0, 2025 extract, WFS/WMS. All-pass. The full **NHSD services directory** snapshots (2023 to 2026) exist too but are restricted.
3. **Open Database of Healthcare Facilities (Statistics Canada)**: about 7,000 facilities with coordinates and postal codes, Open Government Licence Canada. One snapshot (2019-20); StatCan says it is not exhaustive.
4. **KEMRI-Wellcome / WHO public health facilities in sub-Saharan Africa**: 98,745 geocoded public facilities in 50 countries, CC BY 4.0, 2019 release. The round-1 inventory has only per-country HDX lists.
5. **Hospital Codes, Scotland (Public Health Scotland)**: all NHS hospitals with data zone, council and health board codes, OGL, monthly. Joins as a table.
6. **Krankenhausverzeichnis (Destatis)**: all German hospitals and rehabilitation facilities with address and bed structure, annual, 2024 edition. Address only.
7. **Healthsites.io**: global OSM-based facility layer with per-country downloads and an API, ODbL, continuously updated.
8. **NPPES NPI file (CMS)**: every US provider and organisation with an NPI, monthly full file plus weekly updates, address only (over 4 GB zip).
9. **National Hospital Directory with Geo Code (NIHFW India, data.gov.in)**: NIN facility directory with coordinates, GODL licence, monthly.
10. **GRID3 Sierra Leone** (2023, government-approved) and **GRID3 Zambia** (2020, CC BY 4.0) national facility layers.

## What sweep 1 could not find

Ireland (HSE lists: data.gov.ie records 404), South Africa NHFR (no official page), Mexico CLUES (page not fetched), Italy (no dataset page in one search), HRSA rural health clinics (not on the download page), a CIHI facility file (none; ODHF is the Canadian file), AIHW MyHospitals locations (data.gov.au blocks scripts), Healthsites.io per-country HDX exports, the NZ certified-providers list.

## Plan for sweeps 2 to 5 (cap 15 each, same brief: `SWEEP-BRIEF.md`)

| Sweep | Scope | Partial file on disk |
|---|---|---|
| 2 Transport and access | Road links with traffic volume (DfT AADF, BASt, France TMJA); GTFS aggregators and stops (Mobility Database, NaPTAN, BODS); travel time to care (MAP 2020, WorldPop 2025, DfT journey times, StatCan proximity); walkability outside the US (Can-ALE, ABS remoteness, a Europe-wide index) | 15 rows, finished, not merged or checked; one flagged as the generic round-1 MAP row |
| 3 Hazards as multi-year series | Fire perimeter history, MCD64A1, Global Fire Atlas, GFAS; DFO flood archive, Copernicus EMS and GFM, EA recorded flood outlines, HANZE; extreme-heat days by county (EPHT), UHE-Daily, ERA5-HEAT; Canadian Disaster Database, USDA designations | 4 rows (fire only), not finished |
| 4 Food access outside the US | CDRC e-food desert and Priority Places indices, FSA hygiene-rating outlets, StatCan proximity (grocery), Can-FED, PROOF, Australian food-environment products, RIVM, CONEVAL, FEWS NET, IPC on HDX | none |
| 5 Sub-national health outcomes outside the US | ONS life expectancy and MSOA deaths, OHID Local Health, QOF, ScotPHO; CCHS by health region, CCDSS; PHIDU, AIHW MORT, Australian Cancer Atlas; Eurostat hlth_cd and demo_r by NUTS2, ECIS, RIVM, Socialstyrelsen, Géodes; Global Data Lab, DHS spatial repository, NFHS-5 districts, KCHS, DATASUS SIM | none |

Each sweep at cap 15 took about 20 minutes of agent time when it ran; the part-A check is two minutes per 25 rows. Run them one at a time, not in parallel, so a usage stop loses at most one sweep. Sweep 1 suggests the gap is real: 24 of 25 candidates were new, 13 pass the core link checks (none passes all ten, mostly for lack of a persistent ID or archive copy), and most are national registries with coordinates, which round 1 had only for the US, Mekong countries and a few HDX lists. A full round 2 looks worth it for sweeps 1, 2 and 5 on this evidence; sweeps 3 and 4 are untested.

## Time and usage

About 70 minutes wall time (setup, one sweep, link check, merge, report). Token counts are not available to this session; it hit the usage limit twice while agents ran.

## Files (all under `docs/discovery/round2/`)

`round2-candidates-2026-10-28.csv` (25 rows: round-1 columns plus `finest_unit`, `health_relevance`, `gaia_fit`, `keep`, `trim_reason`, `sweep`, `latest_year`, `already_in_inventory`, `merge_note`, and the part-A columns); `verify-A-2026-10-28.csv`, `verify-log-round2.csv`, `verify-A-report-2026-10-28.md`, `browser-queue-2026-10-28.csv` (part A); `sweeps/sweep1-facilities.json` (the sweep's own file, with `could_not_find` and `blocked_pages`), `sweeps/sweep2-transport.json` and `sweeps/sweep3-hazards.json` (partial, unmerged); `sweeps-meta.json`; `SWEEP-BRIEF.md` (the agent brief); `merge_round2.py` (`--with-A --sweeps sweep1-facilities` reproduces the CSV); `verify_links_round2.py` (the link checker, output paths only changed); `rows-for-A.csv`, `verify-A-run.log`.
