# Trim before verification part B (2026-10-22)

**This assumes:** the input is `verify-A-2026-10-21.csv` (1,018 rows). The rules below are applied by `scripts/trim_list.py`, plus a short by-eye list for the leads that survived the rules (reasons recorded). Nothing is deleted: every row stays in `trim-2026-10-22.csv` with `keep` and `trim_reason`.

**Result:** 570 kept, 448 trimmed. Kept: 543 curated and 27 leads. Shortlist rows kept: 168 (was 211).

## Rules

| Rule | Applies to | Rows hit (a row can hit several) |
|---|---|---|
| Latest year before 2000 (from dates, versions or title), unless reference geography (boundaries, health relevance 1) or ongoing; medical data goes back to about 2000 (Robert, 2026-10-22) | all | 7 |
| Lead whose latest year is before 2015 (a facility list or survey snapshot that has gone stale) | leads | 43 |
| Part A found withdrawal language on the page | all | 13 |
| Catalog or portal, not a dataset | all | 13 |
| Viewer or tool, not a dataset | all | 12 |
| Health relevance 0 (synthetic, test, sensitive, non-terrestrial) | all | 15 |
| Title names a single dated event (a fire, flood or storm on a date) | leads | 5 |
| Publisher is a city, council, metro region or similar | leads | 69 |
| Title is a lone statistic "by district" with no place or programme | leads | 2 |
| Unit inferred from a generic word (network, site, region) | leads | 125 |
| Health relevance below 3 | leads | 260 |
| No year anywhere in the listing | leads | 218 |
| Survived the rules but is a sub-national snapshot, forecast, survey or odd catalog record | leads | 12 |

## What is left

| Theme | Kept |
|---|---|
| environment | 99 |
| sdoh | 77 |
| climate_hazard | 72 |
| built_environment | 69 |
| demographics | 58 |
| health_outcome | 57 |
| boundaries | 54 |
| other | 37 |
| toxics | 32 |
| food_access | 15 |

URL health of kept rows (part A): healthy 249, degraded 202, blocked 80, dead 38, n.a. 1.

Latest year of kept rows: 2020+ 258, current 162, unknown 92, 2015-19 35, 2000-14 23. Rows with no year are curated; part B confirms their dates.

## Your three examples

- Wildfire in Municipality of Koper, Slovenia (2022-08-10): trimmed (single event).
- Unemployment rate (15 to 74 years) by District: trimmed (lone indicator, no dates).
- Geoecology: County-Level Environmental Data for the US, 1941-1981: trimmed (stale, 1981).

## Knobs

- Recency cut-off: 2000 for curated rows (Robert, 2026-10-22: medical data goes back to about 2000) and 2015 for leads (one-off lists go stale). Both are constants in `scripts/trim_list.py`.
