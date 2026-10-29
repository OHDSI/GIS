# Numbers check (2026-10-28)

**This assumes:** the four reports below are checked as they stand; every recomputed value comes from the CSV/JSON files named in the last column (`inventory-refined-2026-10-28.csv`, `inventory-combined-2026-10-28.csv`, `_to_delete/inventory-refined-2026-10-23-before-close.csv` for the earlier counts, the part B results, the round 2 files); a mismatch is fixed in the markdown only when it is a clear typo, otherwise it is listed under 'Needs Robert'.

Script: `scripts/numbers_check_2026_10_28.py` (re-runnable; reads each claim out of the document text). **339 claims checked: 327 match, 12 do not.**

Files: CR = `close-report-2026-10-28.md`; IS = `ticket-2026-10-28/ISSUE-update-2026-10-28.md`; BS = `browser-sample-2026-10-28.md`; R2 = `round2/round2-report-2026-10-28.md`.

## The counts named in the brief

| claim | file | claimed | recomputed | match |
|---|---|---|---|---|
| CR funnel: harvested | close-report-2026-10-28.md | 3337 | 3337 | ✓ |
| CR funnel: after de-duplication | close-report-2026-10-28.md | 3160 | 3160 | ✓ |
| CR funnel: curated or lead with a stated unit | close-report-2026-10-28.md | 1018 | 1018 | ✓ |
| CR funnel: kept after trimming | close-report-2026-10-28.md | 570 | 570 | ✓ |
| CR funnel: kept | close-report-2026-10-28.md | 571 | 571 | ✓ |
| CR read by part B | close-report-2026-10-28.md | 430 | 430 | ✓ |
| CR not read: total | close-report-2026-10-28.md | 131 | 131 | ✓ |
| CR not read: browser queue | close-report-2026-10-28.md | 77 | 77 | ✓ |
| CR not read: dead | close-report-2026-10-28.md | 28 | 28 | ✓ |
| CR not read: no URL | close-report-2026-10-28.md | 1 | 1 | ✓ |
| CR not read: left in the close queue | close-report-2026-10-28.md | 25 | 25 | ✓ |
| CR funnel: checked in a browser only, not read by part B | close-report-2026-10-28.md | 10 | 10 | ✓ |
| CR verified: total | close-report-2026-10-28.md | 189 | 189 | ✓ |
| CR browser sample: visited | close-report-2026-10-28.md | 23 | 23 | ✓ |
| CR browser sample: opened | close-report-2026-10-28.md | 18 | 18 | ✓ |
| R2: new rows | round2/round2-report-2026-10-28.md | 24 | 24 | ✓ |
| R2 link health: healthy | round2/round2-report-2026-10-28.md | 14 | 14 | ✓ |
| R2 link health: degraded | round2/round2-report-2026-10-28.md | 7 | 7 | ✓ |
| R2 link health: blocked | round2/round2-report-2026-10-28.md | 3 | 3 | ✓ |
| CR tiers: Gold | close-report-2026-10-28.md | 33 | 33 | ✓ |
| CR tiers: Silver | close-report-2026-10-28.md | 156 | 156 | ✓ |
| CR tiers: Bronze | close-report-2026-10-28.md | 192 | 192 | ✓ |
| CR tiers: Browser needed | close-report-2026-10-28.md | 150 | 150 | ✓ |
| CR tiers: Failed | close-report-2026-10-28.md | 40 | 40 | ✓ |

## Mismatches (12)

| # | claim | file | claimed | recomputed | note |
|---|---|---|---|---|---|
| 227 | IS licences: datasets covered (licence_confirmed filled) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 205 |  |
| 228 | IS licences: unknown | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 184 |  |
| 229 | IS licences: open | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 105 |  |
| 230 | IS licences: attribution | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 26 |  |
| 231 | IS licences: non-commercial | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 19 |  |
| 232 | IS licences: restricted | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 15 |  |
| 233 | IS licences: registration | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 11 |  |
| 234 | IS licences: sum of the listed classes vs 'cover N datasets' | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 205 | 361 | the breakdown is of all rows with a class (incl. 'unknown'), so it does not sum to the 205 in the same sentence |
| 283 | BS suggested statuses carried in the refined CSV (rows where browser_tier / trim = suggestion) | browser-sample-2026-10-28.md | 22 | 21 | differences: us_hud_public_housing_developments: suggested Failed, refined CSV no browser_tier (tier Browser needed) |
| 320 | R2 link health: healthy rows that 'pass the access-URL check' (strict: chk_access_url = pass) | round2/round2-report-2026-10-28.md | NOT FOUND | 9 | chk_access_url among the 14 healthy rows: {'n.a.': 4, 'pass': 9, 'warn': 1}; pass + n.a. = 13 |
| 330 | R2: rows that 'pass every link check' (strict: no warn or fail among all ten checks) | round2/round2-report-2026-10-28.md | NOT FOUND | 0 | round2/verify-A-report-2026-10-28.md says all_passing_A is 0 of 24 |
| 332 | R2: blocked rows said to be in round2/browser-queue-2026-10-28.csv (NHS ODS DSE, Health NZ, KMHFL) | round2/round2-report-2026-10-28.md | NOT FOUND | 2 | queue file lists: gb_nhs_ods_dse_organisations, nz_healthnz_facility_code_table |

## Fixed in the markdown

None. Every mismatch below is a stale or loosely worded figure, not a one-character slip, so none was edited. (The 'Failed 4' line, the licence sentence and the round 2 figures need a decision or the right definition.)

## Needs Robert

1. **Browser-sample statuses: 'Failed 4' is really 3** (CR 'Browser sample' paragraph; IS 'Browser sample' bullet). The refined CSV carries Silver 12, Failed 3, Gold 1, Bronze 1, Browser needed 1 (+ 3 trimmed). `us_hud_public_housing_developments` was suggested Failed ('login required / may be gone') but was never applied: the refine script only applies browser rows whose `opens` starts with yes or no. It is still Browser needed; `us_hud_egis_open_data` ('a portal, not a dataset', BS) has no suggested status and is also still Browser needed. Either apply Failed (and decide eGIS), which moves the tier counts (public housing alone: Browser needed 149, Failed 41), or change the text to 'Failed 3'. I changed neither, because the 33 / 156 / 192 / 150 / 40 tier counts are quoted everywhere.
2. **IS licence sentence**: 'Licences read on the page now cover 205 datasets: unknown 184, open 105, ...' The classes add up to 361, not 205. The 205 are the rows with a `license_confirmed` value: open 105, attribution 26, non-commercial 19, restricted 15, registration 11, one mixed Census/GEOSTAT row, and 28 whose class is 'unknown'. The other 156 of the 184 'unknown' have no licence statement at all (they are the `chk_license` fails). Suggested wording: 'Licences found on the page cover 205 datasets (open 105, attribution 26, non-commercial 19, restricted 15, registration 11, 28 unclassified, 1 mixed); 156 more were read and state none'.
3. **R2 confidence counts**: the report says high 7, medium 11, low 6; the data give high 5, medium 12, low 7 for the 24 new rows (6 / 12 / 7 for all 25 candidates). The 'low' rows are not only the three blocked ones.
4. **R2 'also pass the access-URL check'**: 13 of the 14 healthy rows is only true if n.a. counts as a pass. Strictly 9 pass, 4 have no access URL (n.a.), 1 warns.
5. **R2 'all-pass' / '13 pass every link check'**: `verify-A-report-2026-10-28.md` says 0 of 24 pass every applicable check (persistent ID and Wayback checks warn or fail on nearly all). 13 is reproduced only by reading it as the first six checks (live, redirect, TLS, soft-404, withdrawn, access URL) among the healthy rows. The report should say which reading it means before 'all-pass' is quoted for FINESS and the Geoscience Australia layer.
6. **R2 browser queue**: the report says the three blocked rows (NHS ODS DSE, Health NZ, KMHFL Kenya) are in `round2/browser-queue-2026-10-28.csv`; the file has 2 rows (KMHFL, the timeout, is missing; `verify-A-run.log` also says 2). Add KMHFL to the queue file, or reword.
7. **R2 'This assumes' line**: 'inventory-refined-2026-10-28.csv (574 rows, the same ids as the 10-23 file)'. The 10-28 file has 571 rows (574 is the 10-23 file; three rows were trimmed after the browser check). The same wording is in the `merge_round2.py` comment. Suggested text: '(571 rows: the 574 ids of the 10-23 file less the three trimmed after the browser check)'.
8. **BS Gold wording**: 'Gold: HUD CHAS ..., COI 3.0 (promote once the license is confirmed)' names two Gold, but its own suggested-status table (and the refined CSV) make COI Silver and only HUD CHAS Gold. The 13 total is right either way.

## Also noticed (not counts)

- IS file-move table: the 3 rows trimmed by the browser check also moved into `4-trimmed.csv` (from: to investigate 3), but the table counts only the Failed-tier rows (7 + 1), so it omits them.
- BS says `us_hud_egis_open_data` (HUD eGIS) 'a portal, not a dataset' should be trimmed or reclassified, but it has no row in the suggested-status table and the refined CSV still has it at Browser needed (browser_tier empty).
- BS says Gold: HUD CHAS and COI 3.0; its own suggested-status table (and the refined CSV) make only HUD CHAS Gold, and COI Silver.
- `README.md` status paragraph (not one of the four reports): says 430 of 574 rows and 256 of 22 Oct; the files give 430 of 571 and 255. Left as is (outside the four reports); the old STATUS.md row had the same 574.
- R2 says the Scottish hospital codes file (`gb_phs_hospital_codes`) 'could join as a table now', but the row carries gaia_fit = needs_aggregation like the other 23 (the sweep's field, not changed here).

## All 339 claims

| # | claim | file | claimed | recomputed | match | source / note |
|---|---|---|---|---|---|---|
| 1 | CR 'This assumes': size of the 10-23 refined set | close-report-2026-10-28.md | 574 | 574 | ✓ | _to_delete/inventory-refined-2026-10-23-before-close.csv |
| 2 | CR funnel: harvested | close-report-2026-10-28.md | 3337 | 3337 | ✓ | _to_delete/harvest-2026-10-20-before-dedupe.csv (rows); = 3,160 + 177 in harvest-removed-duplicates.csv |
| 3 | CR funnel: after de-duplication | close-report-2026-10-28.md | 3160 | 3160 | ✓ | harvest-2026-10-20.csv (rows) |
| 4 | CR funnel: curated or lead with a stated unit | close-report-2026-10-28.md | 1018 | 1018 | ✓ | trim-2026-10-22.csv (rows); verify-A-2026-10-21.csv has the same 1,018 |
| 5 | CR funnel: kept after trimming | close-report-2026-10-28.md | 570 | 570 | ✓ | trim-2026-10-22.csv (keep = Y) |
| 6 | CR funnel: mirrors added | close-report-2026-10-28.md | 4 | 4 | ✓ | partB/mirrors-2026-10-23.csv (rows) |
| 7 | CR funnel: dropped as duplicates | close-report-2026-10-28.md | 0 | 0 | ✓ | dupe-review-2026-10-28.csv (alternates that were kept rows in the 10-23 file) |
| 8 | CR funnel: trimmed after a browser check | close-report-2026-10-28.md | 3 | 3 | ✓ | trim-2026-10-22.csv keep=Y rows absent from the refined CSV |
| 9 | CR funnel: kept | close-report-2026-10-28.md | 571 | 571 | ✓ | inventory-refined-2026-10-28.csv (rows) |
| 10 | CR read by part B | close-report-2026-10-28.md | 430 | 430 | ✓ | inventory-refined-2026-10-28.csv (partB_source, partB_blocked) |
| 11 | CR … of (kept rows) | close-report-2026-10-28.md | 571 | 571 | ✓ | inventory-refined-2026-10-28.csv (partB_source, partB_blocked) |
| 12 | CR … read on 22 Oct | close-report-2026-10-28.md | 255 | 255 | ✓ | inventory-refined-2026-10-28.csv (partB_source, partB_blocked) |
| 13 | CR … read on 28 Oct | close-report-2026-10-28.md | 175 | 175 | ✓ | inventory-refined-2026-10-28.csv (partB_source, partB_blocked) |
| 14 | CR … blocked at the content step | close-report-2026-10-28.md | 80 | 80 | ✓ | inventory-refined-2026-10-28.csv (partB_source, partB_blocked) |
| 15 | CR funnel: checked in a browser only, not read by part B | close-report-2026-10-28.md | 10 | 10 | ✓ | inventory-refined-2026-10-28.csv (browser_tier set and no partB_source) |
| 16 | CR not read: browser queue | close-report-2026-10-28.md | 77 | 77 | ✓ | inventory-refined-2026-10-28.csv (no partB_source and no browser_tier; url_health; partB/queue-close.json); recomputed on rows that are neither read nor browser-checked, so the three lines are disjoint |
| 17 | CR not read: dead | close-report-2026-10-28.md | 28 | 28 | ✓ | inventory-refined-2026-10-28.csv (no partB_source and no browser_tier; url_health; partB/queue-close.json) |
| 18 | CR not read: no URL | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv (no partB_source and no browser_tier; url_health; partB/queue-close.json) |
| 19 | CR not read: left in the close queue | close-report-2026-10-28.md | 25 | 25 | ✓ | inventory-refined-2026-10-28.csv (no partB_source and no browser_tier; url_health; partB/queue-close.json) |
| 20 | CR not read: total | close-report-2026-10-28.md | 131 | 131 | ✓ | inventory-refined-2026-10-28.csv (no partB_source and no browser_tier; url_health; partB/queue-close.json) |
| 21 | CR 430 + 10 + 131 = | close-report-2026-10-28.md | 571 | 571 | ✓ | inventory-refined-2026-10-28.csv |
| 22 | CR verified: Gold | close-report-2026-10-28.md | 33 | 33 | ✓ | inventory-refined-2026-10-28.csv |
| 23 | CR verified: Silver | close-report-2026-10-28.md | 156 | 156 | ✓ | inventory-refined-2026-10-28.csv |
| 24 | CR verified: total | close-report-2026-10-28.md | 189 | 189 | ✓ | inventory-refined-2026-10-28.csv |
| 25 | CR footnote: rows visited | close-report-2026-10-28.md | 23 | 23 | ✓ | browser-sample-2026-10-28.csv; inventory-refined-2026-10-28.csv |
| 26 | CR footnote: trimmed | close-report-2026-10-28.md | 3 | 3 | ✓ | browser-sample-2026-10-28.csv; inventory-refined-2026-10-28.csv |
| 27 | CR footnote: kept with a browser_tier | close-report-2026-10-28.md | 18 | 18 | ✓ | browser-sample-2026-10-28.csv; inventory-refined-2026-10-28.csv |
| 28 | CR footnote: also read by part B | close-report-2026-10-28.md | 8 | 8 | ✓ | browser-sample-2026-10-28.csv; inventory-refined-2026-10-28.csv |
| 29 | CR tiers: Gold 10-23 | close-report-2026-10-28.md | 19 | 19 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 30 | CR tiers: Gold 10-28 | close-report-2026-10-28.md | 33 | 33 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 31 | CR tiers: Gold of which shortlist | close-report-2026-10-28.md | 13 | 13 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 32 | CR tiers: Silver 10-23 | close-report-2026-10-28.md | 92 | 92 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 33 | CR tiers: Silver 10-28 | close-report-2026-10-28.md | 156 | 156 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 34 | CR tiers: Silver of which shortlist | close-report-2026-10-28.md | 47 | 47 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 35 | CR tiers: Bronze 10-23 | close-report-2026-10-28.md | 301 | 301 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 36 | CR tiers: Bronze 10-28 | close-report-2026-10-28.md | 192 | 192 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 37 | CR tiers: Bronze of which shortlist | close-report-2026-10-28.md | 60 | 60 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 38 | CR tiers: Browser needed 10-23 | close-report-2026-10-28.md | 130 | 130 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 39 | CR tiers: Browser needed 10-28 | close-report-2026-10-28.md | 150 | 150 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 40 | CR tiers: Browser needed of which shortlist | close-report-2026-10-28.md | 36 | 36 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 41 | CR tiers: Failed 10-23 | close-report-2026-10-28.md | 32 | 32 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 42 | CR tiers: Failed 10-28 | close-report-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 43 | CR tiers: Failed of which shortlist | close-report-2026-10-28.md | 14 | 14 | ✓ | inventory-refined-2026-10-28.csv; _to_delete/inventory-refined-2026-10-23-before-close.csv (priority = shortlist) |
| 44 | CR tier movement: Bronze → Silver | close-report-2026-10-28.md | 52 | 52 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 45 | CR tier movement: Bronze → Browser needed | close-report-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 46 | CR tier movement: Bronze → Gold | close-report-2026-10-28.md | 13 | 13 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 47 | CR tier movement: Browser needed → Silver | close-report-2026-10-28.md | 12 | 12 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 48 | CR tier movement: Bronze → Failed | close-report-2026-10-28.md | 5 | 5 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 49 | CR tier movement: Browser needed → Failed | close-report-2026-10-28.md | 3 | 3 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 50 | CR tier movement: Browser needed → Gold | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 51 | CR tier movement: Browser needed → Bronze | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv vs 10-23 refined file |
| 52 | CR queue: rows in partB/queue-close.json | close-report-2026-10-28.md | 200 | 200 | ✓ | partB/queue-close.json |
| 53 | CR queue: health 3, unit unknown/non-linkable | close-report-2026-10-28.md | 47 | 47 | ✓ | partB/queue-close.json + 10-23 refined file |
| 54 | CR queue: health 2, count/distance step | close-report-2026-10-28.md | 20 | 20 | ✓ | partB/queue-close.json + 10-23 refined file |
| 55 | CR queue: health 2, raster | close-report-2026-10-28.md | 50 | 50 | ✓ | partB/queue-close.json + 10-23 refined file |
| 56 | CR queue: reference layers (health 1) | close-report-2026-10-28.md | 57 | 57 | ✓ | partB/queue-close.json + 10-23 refined file |
| 57 | CR close queue: done | close-report-2026-10-28.md | 175 | 175 | ✓ | partB/results/D*.json; partB/queue-close.json |
| 58 | CR close queue: size | close-report-2026-10-28.md | 200 | 200 | ✓ | partB/results/D*.json; partB/queue-close.json |
| 59 | CR close queue: agent runs | close-report-2026-10-28.md | 35 | 35 | ✓ | partB/results/D*.json; partB/queue-close.json |
| 60 | CR close queue: batches | close-report-2026-10-28.md | 7 | 7 | ✓ | partB/results/D*.json; partB/queue-close.json |
| 61 | CR close queue: left | close-report-2026-10-28.md | 25 | 25 | ✓ | partB/results/D*.json; partB/queue-close.json |
| 62 | CR close queue: first 12 ids left (in order) | close-report-2026-10-28.md | us_mdc_bus_stops, us_mdc_county_library, us_mdc_county_zoning, us_mdc_fire_stations, us_mdc_metrorail_stations, us_mdc_parcels, us_mdc_police_stations, gaia_mdc_streets, pe_minam_red_vial, global_adrc_glide, us_mdc_fema_flood_zone, global_munichre_natcatservice | us_mdc_bus_stops, us_mdc_county_library, us_mdc_county_zoning, us_mdc_fire_stations, us_mdc_metrorail_stations, us_mdc_parcels, us_mdc_police_stations, gaia_mdc_streets, pe_minam_red_vial, global_adrc_glide, us_mdc_fema_flood_zone, global_munichre_natcatservice | ✓ | partB/queue-close.json order; compared as text |
| 63 | CR newly read: Bronze | close-report-2026-10-28.md | 66 | 66 | ✓ | inventory-refined-2026-10-28.csv (partB_source starts with D) |
| 64 | CR newly read: Silver | close-report-2026-10-28.md | 52 | 52 | ✓ | inventory-refined-2026-10-28.csv (partB_source starts with D) |
| 65 | CR newly read: Browser needed | close-report-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv (partB_source starts with D) |
| 66 | CR newly read: Gold | close-report-2026-10-28.md | 12 | 12 | ✓ | inventory-refined-2026-10-28.csv (partB_source starts with D) |
| 67 | CR newly read: Failed | close-report-2026-10-28.md | 5 | 5 | ✓ | inventory-refined-2026-10-28.csv (partB_source starts with D) |
| 68 | CR newly read: blocked at the content step | close-report-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv (partB_source starts with D) |
| 69 | CR part B chk_license: pass | close-report-2026-10-28.md | 126 | 126 | ✓ | inventory-refined-2026-10-28.csv |
| 70 | CR part B chk_license: warn | close-report-2026-10-28.md | 48 | 48 | ✓ | inventory-refined-2026-10-28.csv |
| 71 | CR part B chk_license: fail | close-report-2026-10-28.md | 173 | 173 | ✓ | inventory-refined-2026-10-28.csv |
| 72 | CR part B chk_license: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 73 | CR part B chk_license: not_checked | close-report-2026-10-28.md | 224 | 224 | ✓ | inventory-refined-2026-10-28.csv |
| 74 | CR part B chk_temporal: pass | close-report-2026-10-28.md | 219 | 219 | ✓ | inventory-refined-2026-10-28.csv |
| 75 | CR part B chk_temporal: warn | close-report-2026-10-28.md | 85 | 85 | ✓ | inventory-refined-2026-10-28.csv |
| 76 | CR part B chk_temporal: fail | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 77 | CR part B chk_temporal: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 78 | CR part B chk_temporal: not_checked | close-report-2026-10-28.md | 267 | 267 | ✓ | inventory-refined-2026-10-28.csv |
| 79 | CR part B chk_recency: pass | close-report-2026-10-28.md | 249 | 249 | ✓ | inventory-refined-2026-10-28.csv |
| 80 | CR part B chk_recency: warn | close-report-2026-10-28.md | 42 | 42 | ✓ | inventory-refined-2026-10-28.csv |
| 81 | CR part B chk_recency: fail | close-report-2026-10-28.md | 9 | 9 | ✓ | inventory-refined-2026-10-28.csv |
| 82 | CR part B chk_recency: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 83 | CR part B chk_recency: not_checked | close-report-2026-10-28.md | 271 | 271 | ✓ | inventory-refined-2026-10-28.csv |
| 84 | CR part B chk_cadence: pass | close-report-2026-10-28.md | 104 | 104 | ✓ | inventory-refined-2026-10-28.csv |
| 85 | CR part B chk_cadence: warn | close-report-2026-10-28.md | 153 | 153 | ✓ | inventory-refined-2026-10-28.csv |
| 86 | CR part B chk_cadence: fail | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 87 | CR part B chk_cadence: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 88 | CR part B chk_cadence: not_checked | close-report-2026-10-28.md | 314 | 314 | ✓ | inventory-refined-2026-10-28.csv |
| 89 | CR part B chk_version: pass | close-report-2026-10-28.md | 177 | 177 | ✓ | inventory-refined-2026-10-28.csv |
| 90 | CR part B chk_version: warn | close-report-2026-10-28.md | 83 | 83 | ✓ | inventory-refined-2026-10-28.csv |
| 91 | CR part B chk_version: fail | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 92 | CR part B chk_version: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 93 | CR part B chk_version: not_checked | close-report-2026-10-28.md | 311 | 311 | ✓ | inventory-refined-2026-10-28.csv |
| 94 | CR part B chk_unit: pass | close-report-2026-10-28.md | 230 | 230 | ✓ | inventory-refined-2026-10-28.csv |
| 95 | CR part B chk_unit: warn | close-report-2026-10-28.md | 72 | 72 | ✓ | inventory-refined-2026-10-28.csv |
| 96 | CR part B chk_unit: fail | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 97 | CR part B chk_unit: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 98 | CR part B chk_unit: not_checked | close-report-2026-10-28.md | 269 | 269 | ✓ | inventory-refined-2026-10-28.csv |
| 99 | CR part B chk_coverage: pass | close-report-2026-10-28.md | 247 | 247 | ✓ | inventory-refined-2026-10-28.csv |
| 100 | CR part B chk_coverage: warn | close-report-2026-10-28.md | 76 | 76 | ✓ | inventory-refined-2026-10-28.csv |
| 101 | CR part B chk_coverage: fail | close-report-2026-10-28.md | 3 | 3 | ✓ | inventory-refined-2026-10-28.csv |
| 102 | CR part B chk_coverage: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 103 | CR part B chk_coverage: not_checked | close-report-2026-10-28.md | 245 | 245 | ✓ | inventory-refined-2026-10-28.csv |
| 104 | CR part B chk_access: pass | close-report-2026-10-28.md | 249 | 249 | ✓ | inventory-refined-2026-10-28.csv |
| 105 | CR part B chk_access: warn | close-report-2026-10-28.md | 41 | 41 | ✓ | inventory-refined-2026-10-28.csv |
| 106 | CR part B chk_access: fail | close-report-2026-10-28.md | 21 | 21 | ✓ | inventory-refined-2026-10-28.csv |
| 107 | CR part B chk_access: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 108 | CR part B chk_access: not_checked | close-report-2026-10-28.md | 260 | 260 | ✓ | inventory-refined-2026-10-28.csv |
| 109 | CR part B chk_join_key: pass | close-report-2026-10-28.md | 152 | 152 | ✓ | inventory-refined-2026-10-28.csv |
| 110 | CR part B chk_join_key: warn | close-report-2026-10-28.md | 120 | 120 | ✓ | inventory-refined-2026-10-28.csv |
| 111 | CR part B chk_join_key: fail | close-report-2026-10-28.md | 2 | 2 | ✓ | inventory-refined-2026-10-28.csv |
| 112 | CR part B chk_join_key: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 113 | CR part B chk_join_key: not_checked | close-report-2026-10-28.md | 297 | 297 | ✓ | inventory-refined-2026-10-28.csv |
| 114 | CR part B chk_format_gaia: pass | close-report-2026-10-28.md | 152 | 152 | ✓ | inventory-refined-2026-10-28.csv |
| 115 | CR part B chk_format_gaia: warn | close-report-2026-10-28.md | 131 | 131 | ✓ | inventory-refined-2026-10-28.csv |
| 116 | CR part B chk_format_gaia: fail | close-report-2026-10-28.md | 8 | 8 | ✓ | inventory-refined-2026-10-28.csv |
| 117 | CR part B chk_format_gaia: n.a. | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 118 | CR part B chk_format_gaia: not_checked | close-report-2026-10-28.md | 280 | 280 | ✓ | inventory-refined-2026-10-28.csv |
| 119 | CR Gold/Silver by theme boundaries: Gold | close-report-2026-10-28.md | 4 | 4 | ✓ | inventory-refined-2026-10-28.csv |
| 120 | … Silver | close-report-2026-10-28.md | 14 | 14 | ✓ | inventory-refined-2026-10-28.csv |
| 121 | … total | close-report-2026-10-28.md | 18 | 18 | ✓ | inventory-refined-2026-10-28.csv |
| 122 | CR Gold/Silver by theme built_environment: Gold | close-report-2026-10-28.md | 9 | 9 | ✓ | inventory-refined-2026-10-28.csv |
| 123 | … Silver | close-report-2026-10-28.md | 14 | 14 | ✓ | inventory-refined-2026-10-28.csv |
| 124 | … total | close-report-2026-10-28.md | 23 | 23 | ✓ | inventory-refined-2026-10-28.csv |
| 125 | CR Gold/Silver by theme climate_hazard: Gold | close-report-2026-10-28.md | 2 | 2 | ✓ | inventory-refined-2026-10-28.csv |
| 126 | … Silver | close-report-2026-10-28.md | 25 | 25 | ✓ | inventory-refined-2026-10-28.csv |
| 127 | … total | close-report-2026-10-28.md | 27 | 27 | ✓ | inventory-refined-2026-10-28.csv |
| 128 | CR Gold/Silver by theme demographics: Gold | close-report-2026-10-28.md | 5 | 5 | ✓ | inventory-refined-2026-10-28.csv |
| 129 | … Silver | close-report-2026-10-28.md | 11 | 11 | ✓ | inventory-refined-2026-10-28.csv |
| 130 | … total | close-report-2026-10-28.md | 16 | 16 | ✓ | inventory-refined-2026-10-28.csv |
| 131 | CR Gold/Silver by theme environment: Gold | close-report-2026-10-28.md | 7 | 7 | ✓ | inventory-refined-2026-10-28.csv |
| 132 | … Silver | close-report-2026-10-28.md | 41 | 41 | ✓ | inventory-refined-2026-10-28.csv |
| 133 | … total | close-report-2026-10-28.md | 48 | 48 | ✓ | inventory-refined-2026-10-28.csv |
| 134 | CR Gold/Silver by theme food_access: Gold | close-report-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 135 | … Silver | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv |
| 136 | … total | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv |
| 137 | CR Gold/Silver by theme health_outcome: Gold | close-report-2026-10-28.md | 2 | 2 | ✓ | inventory-refined-2026-10-28.csv |
| 138 | … Silver | close-report-2026-10-28.md | 15 | 15 | ✓ | inventory-refined-2026-10-28.csv |
| 139 | … total | close-report-2026-10-28.md | 17 | 17 | ✓ | inventory-refined-2026-10-28.csv |
| 140 | CR Gold/Silver by theme other: Gold | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv |
| 141 | … Silver | close-report-2026-10-28.md | 2 | 2 | ✓ | inventory-refined-2026-10-28.csv |
| 142 | … total | close-report-2026-10-28.md | 3 | 3 | ✓ | inventory-refined-2026-10-28.csv |
| 143 | CR Gold/Silver by theme sdoh: Gold | close-report-2026-10-28.md | 2 | 2 | ✓ | inventory-refined-2026-10-28.csv |
| 144 | … Silver | close-report-2026-10-28.md | 25 | 25 | ✓ | inventory-refined-2026-10-28.csv |
| 145 | … total | close-report-2026-10-28.md | 27 | 27 | ✓ | inventory-refined-2026-10-28.csv |
| 146 | CR Gold/Silver by theme toxics: Gold | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv |
| 147 | … Silver | close-report-2026-10-28.md | 8 | 8 | ✓ | inventory-refined-2026-10-28.csv |
| 148 | … total | close-report-2026-10-28.md | 9 | 9 | ✓ | inventory-refined-2026-10-28.csv |
| 149 | CR dupes: groups flagged in the harvest | close-report-2026-10-28.md | 174 | 174 | ✓ | harvest-2026-10-20.csv (dup_group); dupe-review csv; 10-23 refined ids |
| 150 | CR dupes: groups touching a kept row | close-report-2026-10-28.md | 18 | 18 | ✓ | harvest-2026-10-20.csv (dup_group); dupe-review csv; 10-23 refined ids |
| 151 | CR dupes: … with two or more kept members | close-report-2026-10-28.md | 11 | 11 | ✓ | harvest-2026-10-20.csv (dup_group); dupe-review csv; 10-23 refined ids |
| 152 | CR dupes: X groups | close-report-2026-10-28.md | 6 | 6 | ✓ | dupe-review-2026-10-28.csv |
| 153 | CR dupes: distinct products | close-report-2026-10-28.md | 19 | 19 | ✓ | dupe-review-2026-10-28.csv |
| 154 | CR dupes: same product | close-report-2026-10-28.md | 4 | 4 | ✓ | dupe-review-2026-10-28.csv |
| 155 | CR dupes: host copy | close-report-2026-10-28.md | 1 | 1 | ✓ | dupe-review-2026-10-28.csv |
| 156 | CR dupes: kept rows dropped | close-report-2026-10-28.md | 0 | 0 | ✓ | dupe-review-2026-10-28.csv |
| 157 | CR dupes table: distinct-product groups | close-report-2026-10-28.md | 19 | 19 | ✓ | dupe-review-2026-10-28.csv |
| 158 | CR browser sample: visited | close-report-2026-10-28.md | 23 | 23 | ✓ | browser-sample-2026-10-28.csv |
| 159 | CR browser sample: opened | close-report-2026-10-28.md | 18 | 18 | ✓ | browser-sample-2026-10-28.csv |
| 160 | CR browser sample: rows sampled | close-report-2026-10-28.md | 25 | 25 | ✓ | browser-sample-2026-10-28.csv |
| 161 | CR statuses applied: Silver | close-report-2026-10-28.md | 12 | 12 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows; recomputed = what the refined CSV actually carries, not what browser-sample-2026-10-28.md suggests |
| 162 | CR statuses applied: Failed | close-report-2026-10-28.md | 3 | 3 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 163 | CR statuses applied: Trimmed | close-report-2026-10-28.md | 3 | 3 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 164 | CR statuses applied: Gold | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 165 | CR statuses applied: Bronze | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 166 | CR statuses applied: Browser needed | close-report-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 167 | CR mirror licence result: us_epa_ejscreen_pedp | close-report-2026-10-28.md | fail | fail | ✓ | inventory-refined-2026-10-28.csv (chk_license) |
| 168 | CR mirror licence result: us_ceq_cejst_pedp | close-report-2026-10-28.md | fail | fail | ✓ | inventory-refined-2026-10-28.csv (chk_license) |
| 169 | CR mirror licence result: us_hifld_next_pedp | close-report-2026-10-28.md | fail | fail | ✓ | inventory-refined-2026-10-28.csv (chk_license) |
| 170 | CR mirror licence result: us_usgs_3dhp | close-report-2026-10-28.md | pass | pass | ✓ | inventory-refined-2026-10-28.csv (chk_license) |
| 171 | CR the one Bronze row without a URL | close-report-2026-10-28.md | us_mdc_2024_dormir_study | us_mdc_2024_dormir_study | ✓ | inventory-refined-2026-10-28.csv (Bronze and url_health n.a.) |
| 172 | CR workbook: Summary formulas evaluated | close-report-2026-10-28.md | 242 | 242 | ✓ | place-data-inventory-2026-10-28.xlsx; formula cells in the Summary sheet (243) minus the funnel's =B15+C15, which the 10-28 evaluator did not cover |
| 173 | CR workbook: mismatches or errors | close-report-2026-10-28.md | 0 | 0 | ✓ | place-data-inventory-2026-10-28.xlsx |
| 174 | CR tokens: agent runs | close-report-2026-10-28.md | 35 | 35 | ✓ | partB/results/D*.json; partB/usage-close.json |
| 175 | CR tokens: rows | close-report-2026-10-28.md | 175 | 175 | ✓ | partB/results/D*.json; partB/usage-close.json |
| 176 | CR tokens: total (M) | close-report-2026-10-28.md | 2.71 | 2.71 | ✓ | partB/results/D*.json; partB/usage-close.json |
| 177 | CR tokens: D01 (k) | close-report-2026-10-28.md | 362 | 362 | ✓ | partB/usage-close.json |
| 178 | CR tokens: D02 (k) | close-report-2026-10-28.md | 371 | 371 | ✓ | partB/usage-close.json |
| 179 | CR tokens: D03 (k) | close-report-2026-10-28.md | 375 | 375 | ✓ | partB/usage-close.json |
| 180 | CR tokens: D04 (k) | close-report-2026-10-28.md | 399 | 399 | ✓ | partB/usage-close.json |
| 181 | CR tokens: D05 (k) | close-report-2026-10-28.md | 395 | 395 | ✓ | partB/usage-close.json |
| 182 | CR tokens: D06 (k) | close-report-2026-10-28.md | 387 | 387 | ✓ | partB/usage-close.json |
| 183 | CR tokens: D07 (k) | close-report-2026-10-28.md | 420 | 420 | ✓ | partB/usage-close.json |
| 184 | CR wall time: first D result written (UTC) | close-report-2026-10-28.md | 2026-10-28 19:51 | 2026-10-28 19:51 | ✓ | partB/results/D*.json (file times) |
| 185 | CR wall time: last D result written (UTC) | close-report-2026-10-28.md | 2026-10-28 20:45 | 2026-10-28 20:45 | ✓ | partB/results/D*.json (file times) |
| 186 | CR remains: browser queue rows | close-report-2026-10-28.md | 150 | 150 | ✓ | browser-queue-2026-10-28.csv; inventory-refined-2026-10-28.csv (D-batch rows with partB_blocked) |
| 187 | CR remains: browser queue domains | close-report-2026-10-28.md | 79 | 79 | ✓ | browser-queue-2026-10-28.csv; inventory-refined-2026-10-28.csv (D-batch rows with partB_blocked) |
| 188 | CR remains: JavaScript-only pages found today | close-report-2026-10-28.md | 40 | 40 | ✓ | browser-queue-2026-10-28.csv; inventory-refined-2026-10-28.csv (D-batch rows with partB_blocked) |
| 189 | CR remains: rows at licence fail | close-report-2026-10-28.md | 170 | 170 | ✓ | inventory-refined-2026-10-28.csv (chk_license = fail, not blocked) |
| 190 | CR remains: close-queue rows not read | close-report-2026-10-28.md | 25 | 25 | ✓ | partB/queue-close.json |
| 191 | IS: rows sent to the content check | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 175 | 175 | ✓ | inventory-refined-2026-10-28.csv |
| 192 | IS: of them JavaScript-only/challenge | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv |
| 193 | IS: read for content | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 430 | 430 | ✓ | inventory-refined-2026-10-28.csv |
| 194 | IS: … of (kept rows) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 571 | 571 | ✓ | inventory-refined-2026-10-28.csv |
| 195 | IS tiers: Gold was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 19 | 19 | ✓ | inventory-refined-2026-10-28.csv |
| 196 | IS tiers: Gold now | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 33 | 33 | ✓ | inventory-refined-2026-10-28.csv |
| 197 | IS tiers: Silver was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 92 | 92 | ✓ | inventory-refined-2026-10-28.csv |
| 198 | IS tiers: Silver now | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 156 | 156 | ✓ | inventory-refined-2026-10-28.csv |
| 199 | IS tiers: Bronze was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 301 | 301 | ✓ | inventory-refined-2026-10-28.csv |
| 200 | IS tiers: Bronze now | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 192 | 192 | ✓ | inventory-refined-2026-10-28.csv |
| 201 | IS tiers: Browser needed was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 130 | 130 | ✓ | inventory-refined-2026-10-28.csv |
| 202 | IS tiers: Browser needed now | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 150 | 150 | ✓ | inventory-refined-2026-10-28.csv |
| 203 | IS tiers: Failed was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 32 | 32 | ✓ | inventory-refined-2026-10-28.csv |
| 204 | IS tiers: Failed now | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv |
| 205 | IS tier movements = CR tier movements (text) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | Bronze → Silver: 52, Bronze → Browser needed: 40, Bronze → Gold: 13, Browser needed → Silver: 12, Bronze → Failed: 5, Browser needed → Failed: 3, Browser needed → Gold: 1, Browser needed → Bronze: 1 | Bronze → Silver: 52, Bronze → Browser needed: 40, Bronze → Gold: 13, Browser needed → Silver: 12, Bronze → Failed: 5, Browser needed → Failed: 3, Browser needed → Gold: 1, Browser needed → Bronze: 1 | ✓ | inventory-refined-2026-10-28.csv; compared as text |
| 206 | IS files: 1-verified rows | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 168 | 168 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/; ticket-2026-10-28/1-verified.csv has 168 rows |
| 207 | IS files: 1-verified was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 111 | 111 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/ |
| 208 | IS files: 2-to-investigate rows | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 288 | 288 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/; ticket csv has 288 |
| 209 | IS files: 2-to-investigate was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 355 | 355 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/ |
| 210 | IS files: 3-reference-layers rows | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 75 | 75 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/; ticket csv has 75 |
| 211 | IS files: 3-reference-layers was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 76 | 76 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/ |
| 212 | IS files: 4-trimmed rows | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 491 | 491 | ✓ | trim csv + inventory-refined-2026-10-28.csv; ticket-2026-10-23/; ticket csv has 491 |
| 213 | IS files: 4-trimmed was | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 480 | 480 | ✓ | trim csv + inventory-refined-2026-10-28.csv; ticket-2026-10-23/ |
| 214 | IS files: failed rows in 4-trimmed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv |
| 215 | IS files: dropped as duplicates | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 0 | 0 | ✓ | inventory-refined-2026-10-28.csv |
| 216 | IS file moves: to investigate → verified | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 57 | 57 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/ ids |
| 217 | IS file moves: to investigate → trimmed or failed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 7 | 7 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/ ids; the 3 rows trimmed after the browser check (also moved into 4-trimmed) are not in the doc's move table |
| 218 | IS file moves: reference layers → trimmed or failed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv; ticket-2026-10-23/ ids |
| 219 | IS newly read: sent | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 175 | 175 | ✓ | inventory-refined-2026-10-28.csv |
| 220 | IS newly read: read | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 135 | 135 | ✓ | inventory-refined-2026-10-28.csv |
| 221 | IS newly read: blocked | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 40 | 40 | ✓ | inventory-refined-2026-10-28.csv |
| 222 | IS newly read: n | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 135 | 135 | ✓ | inventory-refined-2026-10-28.csv |
| 223 | IS newly read: Bronze | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 66 | 66 | ✓ | inventory-refined-2026-10-28.csv |
| 224 | IS newly read: Silver | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 52 | 52 | ✓ | inventory-refined-2026-10-28.csv |
| 225 | IS newly read: Gold | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 12 | 12 | ✓ | inventory-refined-2026-10-28.csv |
| 226 | IS newly read: Failed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 5 | 5 | ✓ | inventory-refined-2026-10-28.csv |
| 227 | IS licences: datasets covered (licence_confirmed filled) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 205 | NOT FOUND | inventory-refined-2026-10-28.csv (license_confirmed, license_class) |
| 228 | IS licences: unknown | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 184 | NOT FOUND | inventory-refined-2026-10-28.csv (license_confirmed, license_class) |
| 229 | IS licences: open | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 105 | NOT FOUND | inventory-refined-2026-10-28.csv (license_confirmed, license_class) |
| 230 | IS licences: attribution | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 26 | NOT FOUND | inventory-refined-2026-10-28.csv (license_confirmed, license_class) |
| 231 | IS licences: non-commercial | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 19 | NOT FOUND | inventory-refined-2026-10-28.csv (license_confirmed, license_class) |
| 232 | IS licences: restricted | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 15 | NOT FOUND | inventory-refined-2026-10-28.csv (license_confirmed, license_class) |
| 233 | IS licences: registration | ticket-2026-10-28/ISSUE-update-2026-10-28.md | NOT FOUND | 11 | NOT FOUND | inventory-refined-2026-10-28.csv (license_confirmed, license_class) |
| 234 | IS licences: sum of the listed classes vs 'cover N datasets' | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 205 | 361 | ✗ | inventory-refined-2026-10-28.csv (license_class); the breakdown is of all rows with a class (incl. 'unknown'), so it does not sum to the 205 in the same sentence |
| 235 | IS: unit confirmed (chk_unit pass) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 230 | 230 | ✓ | inventory-refined-2026-10-28.csv |
| 236 | IS: unit corrected (chk_unit warn) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 72 | 72 | ✓ | inventory-refined-2026-10-28.csv |
| 237 | IS: years confirmed (chk_temporal pass) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 219 | 219 | ✓ | inventory-refined-2026-10-28.csv |
| 238 | IS: discontinued/pre-2000 (chk_recency fail) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 9 | 9 | ✓ | inventory-refined-2026-10-28.csv |
| 239 | IS: public_access registered/restricted (Gold/Silver/Bronze) | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 76 | 76 | ✓ | inventory-refined-2026-10-28.csv |
| 240 | IS dupes: groups reviewed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 24 | 24 | ✓ | dupe-review-2026-10-28.csv; harvest-2026-10-20.csv |
| 241 | IS dupes: distinct products | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 19 | 19 | ✓ | dupe-review-2026-10-28.csv; harvest-2026-10-20.csv |
| 242 | IS dupes: same product | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 4 | 4 | ✓ | dupe-review-2026-10-28.csv; harvest-2026-10-20.csv |
| 243 | IS dupes: host copy | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | dupe-review-2026-10-28.csv; harvest-2026-10-20.csv |
| 244 | IS dupes: groups touching a kept row | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 18 | 18 | ✓ | dupe-review-2026-10-28.csv; harvest-2026-10-20.csv |
| 245 | IS dupes: groups flagged in the harvest | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 174 | 174 | ✓ | dupe-review-2026-10-28.csv; harvest-2026-10-20.csv |
| 246 | IS dupes: kept rows dropped | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 0 | 0 | ✓ | dupe-review-2026-10-28.csv |
| 247 | IS browser sample: visited | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 23 | 23 | ✓ | browser-sample-2026-10-28.csv |
| 248 | IS browser sample: opened fine | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 18 | 18 | ✓ | browser-sample-2026-10-28.csv |
| 249 | IS browser sample: bot challenge | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | browser-sample-2026-10-28.csv |
| 250 | IS browser sample: sign-in or gone | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | browser-sample-2026-10-28.csv |
| 251 | IS browser sample: not found | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | browser-sample-2026-10-28.csv |
| 252 | IS browser sample: hosts unreachable | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 2 | 2 | ✓ | browser-sample-2026-10-28.csv |
| 253 | IS statuses applied: Silver | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 12 | 12 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 254 | IS statuses applied: Failed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 3 | 3 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 255 | IS statuses applied: Trimmed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 3 | 3 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 256 | IS statuses applied: Gold | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 257 | IS statuses applied: Bronze | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 258 | IS statuses applied: Browser needed | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 1 | 1 | ✓ | inventory-refined-2026-10-28.csv (browser_tier) + trimmed rows |
| 259 | IS: browser queue rows | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 150 | 150 | ✓ | browser-queue-2026-10-28.csv |
| 260 | IS: browser queue domains | ticket-2026-10-28/ISSUE-update-2026-10-28.md | 79 | 79 | ✓ | browser-queue-2026-10-28.csv |
| 261 | BS: rows skipped | browser-sample-2026-10-28.md | 2 | 2 | ✓ | browser-sample-2026-10-28.csv |
| 262 | BS: rows visited | browser-sample-2026-10-28.md | 23 | 23 | ✓ | browser-sample-2026-10-28.csv |
| 263 | BS: rows sampled | browser-sample-2026-10-28.md | 25 | 25 | ✓ | browser-sample-2026-10-28.csv |
| 264 | BS: opened fine | browser-sample-2026-10-28.md | 18 | 18 | ✓ | browser-sample-2026-10-28.csv |
| 265 | BS: … of visited | browser-sample-2026-10-28.md | 23 | 23 | ✓ | browser-sample-2026-10-28.csv |
| 266 | BS: … percent | browser-sample-2026-10-28.md | 78 | 78 | ✓ | browser-sample-2026-10-28.csv |
| 267 | BS: bot challenge | browser-sample-2026-10-28.md | 1 | 1 | ✓ | browser-sample-2026-10-28.csv |
| 268 | BS: sign-in required or gone | browser-sample-2026-10-28.md | 1 | 1 | ✓ | browser-sample-2026-10-28.csv |
| 269 | BS: page not found | browser-sample-2026-10-28.md | 1 | 1 | ✓ | browser-sample-2026-10-28.csv |
| 270 | BS: host unreachable | browser-sample-2026-10-28.md | 2 | 2 | ✓ | browser-sample-2026-10-28.csv |
| 271 | BS: the five result rows add up to the visited rows | browser-sample-2026-10-28.md | 23 | 23 | ✓ | table rows above |
| 272 | BS: would-be Gold or Silver | browser-sample-2026-10-28.md | 13 | 13 | ✓ | browser-sample-2026-10-28.csv (would_be column) |
| 273 | BS: … of visited | browser-sample-2026-10-28.md | 23 | 23 | ✓ | browser-sample-2026-10-28.csv (would_be column) |
| 274 | BS: rows the text calls Gold (HUD CHAS, COI 3.0) | browser-sample-2026-10-28.md | 2 | 2 | ✓ | browser-sample-2026-10-28.csv (would_be starts with Gold) |
| 275 | BS: should be trimmed or reclassified | browser-sample-2026-10-28.md | 5 | 5 | ✓ | browser-sample-2026-10-28.csv (would_be: trim, Portal, not linkable, Bronze) |
| 276 | BS: would-be Gold/Silver + trim/reclassify = rows opened | browser-sample-2026-10-28.md | 18 | 18 | ✓ | the two lines above |
| 277 | BS licences: open as stated (CC BY) | browser-sample-2026-10-28.md | 2 | 2 | ✓ | browser-sample-2026-10-28.csv |
| 278 | BS licences: US government, public domain assumed | browser-sample-2026-10-28.md | 7 | 7 | ✓ | browser-sample-2026-10-28.csv |
| 279 | BS licences: restricted (non-commercial, cite-as, commercial) | browser-sample-2026-10-28.md | 3 | 3 | ✓ | browser-sample-2026-10-28.csv |
| 280 | BS licences: not seen on the landing page | browser-sample-2026-10-28.md | 5 | 5 | ✓ | browser-sample-2026-10-28.csv |
| 281 | BS: remaining queue rows (10-23 queue minus the 25 sampled) | browser-sample-2026-10-28.md | 105 | 105 | ✓ | browser-queue-2026-10-23.csv (130 rows) minus the sample |
| 282 | BS suggested-status table: rows listed (25 sampled − 2 skipped − 1 with no suggestion) | browser-sample-2026-10-28.md | 22 | 22 | ✓ | browser-sample md table |
| 283 | BS suggested statuses carried in the refined CSV (rows where browser_tier / trim = suggestion) | browser-sample-2026-10-28.md | 22 | 21 | ✗ | inventory-refined-2026-10-28.csv (browser_tier); trim csv; differences: us_hud_public_housing_developments: suggested Failed, refined CSV no browser_tier (tier Browser needed) |
| 284 | R2: candidates written by the sweep | round2/round2-report-2026-10-28.md | 25 | 25 | ✓ | round2/round2-candidates-2026-10-28.csv |
| 285 | R2: kept after the trim rules | round2/round2-report-2026-10-28.md | 25 | 25 | ✓ | round2/round2-candidates-2026-10-28.csv (keep = Y) |
| 286 | R2: already in inventory | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | round2/round2-candidates-2026-10-28.csv (already_in_inventory) |
| 287 | R2: new rows | round2/round2-report-2026-10-28.md | 24 | 24 | ✓ | inventory-combined-2026-10-28.csv (round = 2-pilot) |
| 288 | R2: the round 1 id the HRSA candidate matches | round2/round2-report-2026-10-28.md | us_hrsa_health_center_sites | us_hrsa_health_center_sites | ✓ | round2/round2-candidates-2026-10-28.csv |
| 289 | R2: recognised as round-1 products and not written | round2/round2-report-2026-10-28.md | 4 | 4 | ✓ | round2/sweeps-meta.json (overlap_round1) |
| 290 | R2 sweep 1: searches | round2/round2-report-2026-10-28.md | 44 | 44 | ✓ | round2/sweeps-meta.json |
| 291 | R2 sweep 1: pages read | round2/round2-report-2026-10-28.md | 57 | 57 | ✓ | round2/sweeps-meta.json |
| 292 | R2 sweep 1: minutes | round2/round2-report-2026-10-28.md | 18 | 18 | ✓ | round2/sweeps-meta.json |
| 293 | R2 sweep 1: start (UTC) | round2/round2-report-2026-10-28.md | 19:56 | 19:56 | ✓ | round2/sweeps-meta.json |
| 294 | R2 sweep 1: end (UTC) | round2/round2-report-2026-10-28.md | 20:14 | 20:14 | ✓ | round2/sweeps-meta.json |
| 295 | R2 coverage: US | round2/round2-report-2026-10-28.md | 4 | 4 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 296 | R2 coverage: GB | round2/round2-report-2026-10-28.md | 4 | 4 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 297 | R2 coverage: CA | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 298 | R2 coverage: AU | round2/round2-report-2026-10-28.md | 2 | 2 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 299 | R2 coverage: NZ | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 300 | R2 coverage: DE | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 301 | R2 coverage: FR | round2/round2-report-2026-10-28.md | 2 | 2 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 302 | R2 coverage: ES | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 303 | R2 coverage: BR | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 304 | R2 coverage: IN | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 305 | R2 coverage: KE | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 306 | R2 coverage: NG | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 307 | R2 coverage: sub-Saharan Africa | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 308 | R2 coverage: SL | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 309 | R2 coverage: ZM | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 310 | R2 coverage: global | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | inventory-combined-2026-10-28.csv (id prefix) |
| 311 | R2 coverage: the sixteen groups add up to the new rows | round2/round2-report-2026-10-28.md | 24 | 24 | ✓ | inventory-combined-2026-10-28.csv |
| 312 | R2 confidence: high | round2/round2-report-2026-10-28.md | 5 | 5 | ✓ | inventory-combined-2026-10-28.csv (24 new rows); the 25 candidates give high 6, medium 12, low 7 |
| 313 | R2 confidence: medium | round2/round2-report-2026-10-28.md | 12 | 12 | ✓ | inventory-combined-2026-10-28.csv (24 new rows) |
| 314 | R2 confidence: low | round2/round2-report-2026-10-28.md | 7 | 7 | ✓ | inventory-combined-2026-10-28.csv (24 new rows) |
| 315 | R2: all 24 are point or address data (finest_unit) | round2/round2-report-2026-10-28.md | 24 | 24 | ✓ | inventory-combined-2026-10-28.csv |
| 316 | R2: all 24 have gaia_fit = needs_aggregation | round2/round2-report-2026-10-28.md | 24 | 24 | ✓ | inventory-combined-2026-10-28.csv |
| 317 | R2 link health: healthy | round2/round2-report-2026-10-28.md | 14 | 14 | ✓ | round2/verify-A-2026-10-28.csv |
| 318 | R2 link health: degraded | round2/round2-report-2026-10-28.md | 7 | 7 | ✓ | round2/verify-A-2026-10-28.csv |
| 319 | R2 link health: blocked | round2/round2-report-2026-10-28.md | 3 | 3 | ✓ | round2/verify-A-2026-10-28.csv |
| 320 | R2 link health: healthy rows that 'pass the access-URL check' (strict: chk_access_url = pass) | round2/round2-report-2026-10-28.md | NOT FOUND | 9 | NOT FOUND | round2/verify-A-2026-10-28.csv; chk_access_url among the 14 healthy rows: {'n.a.': 4, 'pass': 9, 'warn': 1}; pass + n.a. = 13 |
| 321 | R2: the 7 degraded rows are the 3 CMS + NPPES, CQC, Spain, CNES it names | round2/round2-report-2026-10-28.md | 7 | 7 | ✓ | round2/verify-A-2026-10-28.csv |
| 322 | R2: CMS provider-data download URLs that answer 404 (dialysis, home health, hospice) | round2/round2-report-2026-10-28.md | 3 | 3 | ✓ | round2/verify-A-2026-10-28.csv |
| 323 | R2: the four rows said to have no machine-readable metadata (NPPES, CQC, Spain, CNES) have chk_machine_metadata = fail | round2/round2-report-2026-10-28.md | 4 | 4 | ✓ | round2/verify-A-2026-10-28.csv |
| 324 | R2: withdrawn pages | round2/round2-report-2026-10-28.md | 0 | 0 | ✓ | round2/verify-A-2026-10-28.csv (chk_withdrawn warn or fail) |
| 325 | R2: Wayback snapshots exist for | round2/round2-report-2026-10-28.md | 18 | 18 | ✓ | round2/verify-A-2026-10-28.csv (wayback_url) |
| 326 | R2: … of | round2/round2-report-2026-10-28.md | 24 | 24 | ✓ | round2/verify-A-2026-10-28.csv (wayback_url) |
| 327 | R2: log entries in verify-log-round2.csv | round2/round2-report-2026-10-28.md | 240 | 240 | ✓ | round2/verify-log-round2.csv |
| 328 | R2: run id | round2/round2-report-2026-10-28.md | A-round2-20261028 | A-round2-20261028 | ✓ | round2/verify-log-round2.csv; round2/verify-A-run.log |
| 329 | R2: run minutes | round2/round2-report-2026-10-28.md | 1.9 | 1.9 | ✓ | round2/verify-log-round2.csv; round2/verify-A-run.log |
| 330 | R2: rows that 'pass every link check' (strict: no warn or fail among all ten checks) | round2/round2-report-2026-10-28.md | NOT FOUND | 0 | NOT FOUND | round2/verify-A-2026-10-28.csv; round2/verify-A-report-2026-10-28.md says all_passing_A is 0 of 24 |
| 331 | R2: same claim, reading 'every link check' as the first six checks (live, redirect, TLS, soft-404, withdrawn, access URL) at pass or n.a., among the 14 healthy rows | round2/round2-report-2026-10-28.md | 13 | 13 | ✓ | round2/verify-A-2026-10-28.csv; the report does not define the term; over all 24 rows the same reading gives 17 |
| 332 | R2: blocked rows said to be in round2/browser-queue-2026-10-28.csv (NHS ODS DSE, Health NZ, KMHFL) | round2/round2-report-2026-10-28.md | NOT FOUND | 2 | NOT FOUND | round2/browser-queue-2026-10-28.csv; queue file lists: gb_nhs_ods_dse_organisations, nz_healthnz_facility_code_table |
| 333 | R2: sweep2-transport.json rows | round2/round2-report-2026-10-28.md | 15 | 15 | ✓ | round2/sweeps/sweep2-transport.json |
| 334 | R2: sweep2-transport.json marked finished (1 = yes) | round2/round2-report-2026-10-28.md | 1 | 1 | ✓ | round2/sweeps/sweep2-transport.json (status) |
| 335 | R2: sweep3-hazards.json rows | round2/round2-report-2026-10-28.md | 4 | 4 | ✓ | round2/sweeps/sweep3-hazards.json |
| 336 | R2: sweep3-hazards.json marked finished (1 = yes) | round2/round2-report-2026-10-28.md | 0 | 0 | ✓ | round2/sweeps/sweep3-hazards.json (status) |
| 337 | R2 files: rows in round2-candidates csv | round2/round2-report-2026-10-28.md | 25 | 25 | ✓ | round2/round2-candidates-2026-10-28.csv |
| 338 | R2 'This assumes': rows in inventory-refined-2026-10-28.csv | round2/round2-report-2026-10-28.md | 571 | 571 | ✓ | inventory-refined-2026-10-28.csv; the 574 is the 10-23 file (before the 3 browser-check trims); the 10-28 file has 571 |
| 339 | R2: 'of 25 candidates were new' | round2/round2-report-2026-10-28.md | 24 | 24 | ✓ | inventory-combined-2026-10-28.csv |
