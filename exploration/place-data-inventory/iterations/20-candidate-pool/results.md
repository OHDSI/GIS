# Iteration #20: working the DataCite candidate pool (2026-11-03)

**Question:** how many of the untouched `likely_relevant` DataCite candidates (landscape #12) become verified rows cheaply, reading repository APIs instead of landing pages?

**Scope rules (set before collecting):** triage `likely_relevant`; published 2000 or later; a place unit in the title or a geolocation; one row per product family; drop paper supplements about clinical or qualitative studies, single-site studies and village surveys. Caps: 150 families enriched, 60 shortlisted, 30 rows.

**Result:** 27 new rows (round `20-candidates`): **Gold 9, Silver 18**. Inventory 726 rows; Gold 111 → 120, Silver 409 → 427; Gold + Silver 520 → 547. About an hour in chat.

| Step | File | What |
|---|---|---|
| A | `a-families.csv`, `a-top150.csv` | 1,042 uncovered candidates → 734 product families → 540 in scope; ranked by anchor priority, citations, regional gap and geolocation |
| B | (DataCite API in the browser) | rights, type, geolocation, formats, host and supplement flag for the top 150 |
| C | `c-candidates.jsonl` → `inventory-combined-2026-11-03a.csv` | 27 rows read from Zenodo, figshare, Dataverse (Harvard, Recherche Data Gouv) APIs, or DataCite records where no repository API answered |
| D | `d-withdrawn.jsonl` → `-11-03b` | withdrawn check from the live repository record for 13 rows; 9 move to Gold |

**Added:**
- 9 Gold: SA public and private hospital locations (Australia), Brazilian Semiarid heat index (municipal), South Korea district WBGT, GRIPHO Italy hourly rainfall, global all-weather 1 km LST, ChinaHighTEM, PISCOp Peru rainfall, harmonized European disposable income (120,000+ local units).
- 18 Silver: 8 NaNDA products (civic and religious, liquor/tobacco/cannabis, dollar stores, retail, eating and drinking, post offices and banks, personal care, school districts), Nigeria housing affordability (LGA/ward), US housing condition scores (tract/ZCTA/H3), China hospital accessibility (1 km; "past version"), Bangladesh district MPI (replication package), US decomposed PM2.5/NO2 by block group, Brazil geocoded primary care clinics, WorldPop 1 km poverty (6 countries), Eurostat material and social deprivation (NUTS 2), Mexico rainfall by admin unit, US ZIP-to-tract crosswalk (Redivis; lead for 2.3).

**Findings:**
- **Coverage was understated.** Matching candidates by exact DOI found 44 of 1,087 in the inventory; normalized DOIs plus title matching found **115 (11%)**. 972 remain uncovered (about 945 after this run).
- **Repository APIs are the cheap route.** Zenodo, figshare and Dataverse records carry the licence, files, versions and a description, so licence, unit, years and access are settled in one call. DataCite alone usually lacks rights (NaNDA, Eurostat) and gives publication years, not coverage (as #12 found).
- **NaNDA is behind a bot check** on all three hosts (ICPSR, openICPSR, nanda.isr.umich.edu). One person-read of a NaNDA terms page would settle licence and access for about 25 rows.
- The ranking still let in clinical paper supplements (Taylor & Francis figshare) and microdata (HILDA); the DataCite `IsSupplementTo` flag and the host catch most of them.

**Verdict: scale, with changes.** About 27 rows per hour, 9 of them Gold. Next pass: the remaining ~510 in-scope families, Zenodo/figshare/Dataverse first (API-readable), NaNDA after Robert's terms read, and the supplement/microdata filter applied in step A.
