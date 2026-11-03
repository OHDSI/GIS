# Fixes, tier drift and Miami-Dade pass, report 2026-11-03 (iteration #24)

In chat, after P5 and P6. Records in `run-2026-11-03/pending/` (one `.jsonl` per step, each with a `-tier-moves.csv`), applied with `scripts/apply_records_2026_11_02.py`.

| Step | Records | Master | Result |
|---|---|---|---|
| e NaNDA licences | 11 | -p5a | Two study pages read by Robert (208907, 208684): CC BY-NC 4.0, so licence warn (non-commercial). 8 more studies in the same 2xxxxx deposit series stamped as **inferred from siblings** (own page not read). The older ICPSR release 38580 shows no licence: licence fail, Silver to Bronze. The other 6 older studies (icpsr38xxx) are not stamped. |
| f Catalog-draft fixes | 2 | -p6a | COI: geometry dependency is TIGER/Line 2020 tracts on `geoid20` (was "TIGER ZCTAs"). UCMR 5: joins EPA PWS service areas on PWSID (ZIP route kept as alternate). |
| g P4 utility layers | 3 | -p6b | The three Miami-Dade utility-coordination layers from P4 are kept, marked low health relevance (Robert: only the Miami-Dade rows from the existing catalog are first-class). |
| h Tier drift | 1 | -p6c | 11 rows had a stored tier different from `tier_of()`; all were deliberate holds (below). UCMR (generic row) cap lifted: Silver to Gold. |
| i Miami-Dade pass | 24 | -p6d | County Hub search API and feature-service metadata, read in the built-in browser. |
| j Cooling Centers | 1 new | -p6e | New row for a gaiaCatalog entry that had none. |

**Totals (excluding `2-pilot`):** Gold 156 to 157, Silver 468 to 471, Bronze 107 to 105, Failed 30 to 29. Gold + Silver 624 to 628. 805 rows.

## Tier drift (11 rows)

P6 found 11 rows whose stored tier differs from a fresh `tier_of()`. None is a bug; all are holds that exist only as stored values, so any future re-tier of these rows would silently promote them.

- **GHGRP, UCMR generic** (Silver; `tier_of` says Gold): capped 2026-10-29, "geometry dependency TBD". UCMR's dependency is now confirmed (EPA PWS service areas on PWSID, found in the UCMR 3 and 5 files), so under the 2026-10-30 rule the cap is lifted: **UCMR to Gold**. GHGRP still depends on the FRS crosswalk and stays Silver.
- **Census MDI, NIEHS CHORDS** (Bronze; `tier_of` says Silver): hand caps (a paper with no data files; a catalogue, not a dataset). Kept.
- **7 backfill rows from #16** (Bronze; `tier_of` says Silver): the #16 job set these tiers itself; most have access fail or warn, which `tier_of`'s Silver rule ignores. Kept Bronze. Two (Portugal EDI parishes, CyAN cyanobacteria) would be Silver despite **access fail**: an example for TODO 4.10.
- **Fix later:** add a `tier_cap` column (value plus reason) that `tier_of` respects.

## Miami-Dade pass (36 rows from the existing catalog)

- **Licence.** The county Hub's site-wide Terms of Use (https://opendata.miamidade.gov/pages/terms-of-use) is the same "as is" disclaimer as each item's licence field: no licence grant and no use restriction. 18 rows keep licence **warn**, now with the terms page as evidence. Whether a disclaimer-only open-data portal counts as open is a WG question (TODO 4.8/4.9). The Open Data Policy page only points to county legislation.
- **Temporal warn** on the Hub rows is the "current snapshot" rule (living layers), not a missing read.
- **Hospitals** (Silver, nothing checked before): read; 28 points with bed counts and an emergency-room flag, edited 2026-11-02. Stays Silver (licence warn).
- **FQHCs** (Bronze): read; 22 points, last edited 2018-11-13 (recency warn). **Bronze to Silver.**
- **Community health centers** (Failed): **the 2026-10-29 browser pass was wrong.** The gaiaCatalog entry is a derived layer: the Property Appraiser parcel view (`PaGISView_gdb`) filtered to `DOR_DESC = 'CHARITABLE - EXEMPT : HEALTH CARE'` (37 parcels today). The Commercial Property landing link points at that source family on purpose. **Failed to Silver.**
- **County zoning** (Bronze, licence fail on the MapServer page): the Hub item "County Zoning" (`ZonepolyU_gdb`, 4,017 polygons, edited 2026-11-02) taken as the current form of the layer (not compared field by field). **Bronze to Silver.**
- **Park facilities** (Failed): no "Park Facility" layer on the Hub; nearest are County Operated Park - View (points) and Municipal Park. Successor not chosen: **needs Robert.**
- **Police stations:** its `in_gaia` pointed at `mdc_cooling_stations`, a different dataset. Link removed.
- **Cooling Centers (new row, Silver):** gaiaCatalog `mdc_cooling_stations` had no inventory row. Public ArcGIS Online item by Miami-Dade County: 65 libraries and parks sites, edited 2026-11-02.
- **Not changed:** UM-internal layers (DORMIR study, CCE land filters) and the SoundScore commercial product cannot be checked publicly; they stay Bronze. gaiaCatalog entries without inventory rows are only synthetic or test data (`synthetic_*`, `mdc_5000_addresses_normalized`), one survey (`kenya_ppd_survey_2014`) and the person-level registry, which stays out (TODO 4.3).

## Lessons

- A "wrong link" verdict on a catalog row should check the catalog's own ETL first: the gaiaCatalog `meta_json-ld` and ETL scripts name the exact service and filter.
- Map inventory rows to gaiaCatalog entries by the entry's own source URL, not by title similarity.
