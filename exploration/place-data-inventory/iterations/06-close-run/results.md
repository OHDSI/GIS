# Close report: first-round assessment of the place-based data inventory (2026-10-28)

**This assumes:** the 2026-10-23 refined set (574 kept rows) is the scope; part A results are unchanged (2026-10-21 run plus the 2026-10-22 re-check); part B is an agent reading the landing page and at most one documentation page per dataset (no downloads, no bot-protection workarounds, no guessing: every confirmed value has an evidence URL); recency cut-off 2000 (Robert, 2026-10-22). Duplicate decisions were made from the listings (title, publisher, URL, coverage, unit, years), without re-reading pages.

## Funnel

| Step | Datasets |
|---|---|
| Harvested | 3,337 |
| After de-duplication | 3,160 |
| Curated, or a lead with a stated unit | 1,018 |
| Kept after trimming | 570 |
| + mirrors / successors of withdrawn tools | 4 |
| − dropped as duplicates (2026-10-28) | 0 |
| − trimmed after a browser check (2026-10-28) | 3 |
| Kept | 571 |
| **Read by part B: 430 of 571** (22 Oct: 255; 28 Oct: 175; blocked at the content step: 80) | 430 |
| Checked in a real browser only, not read by part B (agent in the Claude desktop browser pane; sample of the browser queue, 2026-10-28)¹ | 10 |
| Not read: browser queue 77, dead 28, no URL 1, left in the close queue 25 | 131 |
| **Verified: Gold 33 + Silver 156** | **189** |

¹ Browser sample: 23 rows visited. 3 were trimmed, leaving 18 in the kept set with a `browser_tier`; 8 of those had also been read by part B and are counted there, so 10 appear on this line. 430 + 10 + 131 = 571.

## Tiers before and after

| Tier | 2026-10-23 | 2026-10-28 | of which shortlist |
|---|---|---|---|
| Gold | 19 | 33 | 13 |
| Silver | 92 | 156 | 47 |
| Bronze | 301 | 192 | 60 |
| Browser needed | 130 | 150 | 36 |
| Failed | 32 | 40 | 14 |

Movements: Bronze → Silver: 52, Bronze → Browser needed: 40, Bronze → Gold: 13, Browser needed → Silver: 12, Bronze → Failed: 5, Browser needed → Failed: 3, Browser needed → Gold: 1, Browser needed → Bronze: 1.

## Step 1: part B on the remaining live rows

Queue `partB/queue-close.json`: 200 Bronze rows never read (the one Bronze row without a URL was excluded), ordered health 3 with unknown/non-linkable unit (47), health 2 needing a count/distance step (20), health 2 needing raster (50), reference layers (57), the rest. Done: 175 of 200 in 35 agent runs (7 batches); 25 left: us_mdc_bus_stops, us_mdc_county_library, us_mdc_county_zoning, us_mdc_fire_stations, us_mdc_metrorail_stations, us_mdc_parcels, us_mdc_police_stations, gaia_mdc_streets, pe_minam_red_vial, global_adrc_glide, us_mdc_fema_flood_zone, global_munichre_natcatservice….

Results on the newly read rows: Bronze 66, Silver 52, Browser needed 40, Gold 12, Failed 5 (blocked at the content step: 40, now Browser needed).

Part B (content, all kept rows, 22 and 28 Oct):

| Check | pass | warn | fail | n.a. | not_checked |
|---|---|---|---|---|---|
| `chk_license` | 126 | 48 | 173 | 0 | 224 |
| `chk_temporal` | 219 | 85 | 0 | 0 | 267 |
| `chk_recency` | 249 | 42 | 9 | 0 | 271 |
| `chk_cadence` | 104 | 153 | 0 | 0 | 314 |
| `chk_version` | 177 | 83 | 0 | 0 | 311 |
| `chk_unit` | 230 | 72 | 0 | 0 | 269 |
| `chk_coverage` | 247 | 76 | 3 | 0 | 245 |
| `chk_access` | 249 | 41 | 21 | 0 | 260 |
| `chk_join_key` | 152 | 120 | 2 | 0 | 297 |
| `chk_format_gaia` | 152 | 131 | 8 | 0 | 280 |

## Gold and Silver by theme

| Theme | Gold | Silver | Total |
|---|---|---|---|
| boundaries | 4 | 14 | 18 |
| built_environment | 9 | 14 | 23 |
| climate_hazard | 2 | 25 | 27 |
| demographics | 5 | 11 | 16 |
| environment | 7 | 41 | 48 |
| food_access | 0 | 1 | 1 |
| health_outcome | 2 | 15 | 17 |
| other | 1 | 2 | 3 |
| sdoh | 2 | 25 | 27 |
| toxics | 1 | 8 | 9 |

## Step 2: duplicate decisions

Of the 174 groups flagged in the harvest, only 18 touch a kept row (11 with two or more kept members); the rest were trimmed on 2026-10-22 or stayed as leads. A scan of the kept set for rows sharing a landing page added 6 groups (X-numbered). Decisions (`dupe-review-2026-10-28.csv`): distinct products 19, same product 4, host copy 1. Kept rows dropped: 0. Where the alternate was already outside the kept set, its URL was recorded on the primary (notes, or `access_url` when empty: ca_statcan_cimd).

| group | decision | ids |
|---|---|---|
| D0001 | same product | us_nasa_haqast_tropomi_no2_conus_monthly; nasa_cmr_haq_tropomi_no2_conus_m_l3 |
| D0004 | same product | us_cdc_covid_community_levels; co_datosgovco_data_united_states_covid_19_community_levels_by_county |
| D0006 | same product | us_nyc_street_tree_census_2015; us_socrata_data_2015_street_tree_census_tree_data |
| D0007 | same product | ca_statcan_cimd; ca_opencanada_canadian_index_of_multiple_deprivation_2021 |
| D0027 | host copy | global_globio_grip; global_globio_grip4_roads |
| 19 groups | distinct products | flag cleared |

## Browser sample (agent in a real browser, 2026-10-28)

25 Browser-needed rows were opened in a real browser by an agent (Claude, in the desktop app's browser pane; no downloads, sign-ins or CAPTCHA attempts) (`browser-sample-2026-10-28.md`, `.csv`): 23 visited, 18 opened. The suggested status changes were applied: Silver 12, Failed 3, Trimmed 3, Gold 1, Bronze 1, Browser needed 1; two rows stay Browser needed without an applied status (HUD public housing, sign-in or gone; HUD eGIS, a portal). Fields read in the browser (licence, years, unit, access, formats) are in the refined CSV with the note 'browser check 2026-10-28'; `browser_tier` records the applied status. `us_ahrq_sdoh_database` was repointed to the AHRQ Community-Level Health (CLH) Database page. NRDC stays Browser needed (Cloudflare challenge).

## Step 3: loose ends

Mirror licences (pages read 2026-10-28):

| row | licence | result | where looked |
|---|---|---|---|
| `us_epa_ejscreen_pedp` | none stated | fail | https://screening-tools.com/epa-ejscreen;<br> https://screening-tools.com/about |
| `us_ceq_cejst_pedp` | none stated | fail | https://public-environmental-data-partners.github.io/j40-cejst-2/en/downloads;<br> https://public-environmental-data-partners.github.io/j40-cejst-2/en/about;<br> https://github.com/public-environmental-data-partners/j40-cejst-2;<br> https://raw.githubusercontent.com/Public-Environmental-Data-Partners/j40-cejst-2/main/LICENSE.md |
| `us_hifld_next_pedp` | none stated | fail | https://hifld.publicenvirodata.org;<br> https://hifld.publicenvirodata.org/about |
| `us_usgs_3dhp` | public domain (USGS-produced data; credit requested: 'Credit: U.S. Geological Survey') | pass | https://www.usgs.gov/information-policies-and-instructions/copyrights-and-credits;<br> https://www.usgs.gov/3d-hydrography-program;<br> https://www.usgs.gov/3d-hydrography-program/access-3dhp-data-products |

Suggested question to PEDP (no general contact address on the pages; the About page lists fundraising@publicenvirodata.org, and the CEJST and HIFLD Next pages have feedback forms): *"Under what licence or terms do you make the EJScreen reconstruction (screening-tools.com/epa-ejscreen and the Harvard Dataverse deposit), the CEJST v2.0 copy and HIFLD Next available for reuse? The federal originals were US Government works in the public domain; could you state that, or your own terms, on each page or in the repository?"*

Notes for Tim updated: `notes-for-tim-2026-10-28.md` (draft, not sent). Decision memo: `decisions-needed-2026-10-28.md`.

## Choices made (decided without asking)

- The close queue excludes the one Bronze row without a URL (`us_mdc_2024_dormir_study`); dead and blocked rows were already outside Bronze.
- Batches of 25 were run with 5 agents each as before, but consecutive batches overlapped (the next batch started once most agents of the previous one had returned) to fit the time-box.
- Part B was stopped on Robert's instruction after a usage limit cut batches D07 and D08 short: valid result files were kept, agents still running were stopped, and no further batches were launched. D07-a2's file was invalid when first checked and valid after the agent rewrote it, so it is included.
- The browser sample's suggested statuses are applied as tier overrides (`browser_tier`); the check columns record what the page showed (for example 'public domain, assumed' is a licence warn, not a pass), so a Gold here can carry a licence warn.
- Rows that the content step found to be JavaScript-only shells or challenge pages are `blocked` and move to Browser needed, as on 2026-10-23.
- Duplicate groups where only one member survived the trim are recorded as decided (the alternate's URL noted on the primary) rather than ignored; no kept row was dropped, because every pair of kept rows turned out to be distinct products.
- The six X-groups from the same-landing-page scan are an addition to the brief; all were judged distinct, so nothing changed.
- The USGS 3DHP mirror's licence was filled from the publisher-level USGS Copyrights and Credits page, as the brief asked for a terms page; this is the only row whose licence comes from a publisher-level page. The same rule has not been applied to the 100-odd US federal rows whose pages state nothing (still Robert's call; see the decision memo and next steps).
- The three PEDP mirrors stay at `chk_license` fail (nothing stated), with the conflicting code licences on the CEJST repository recorded in the detail.
- `verified_on` for rows read on 28 Oct is 2026-10-28; rows read on 22 Oct keep 2026-10-22.
- The ticket's `1-verified.csv` gained `finest_unit_confirmed`, `join_key_confirmed` and `evidence` columns; `link_status_2026_10_22` was renamed `link_status`.
- The workbook's funnel line 'Verified (Gold + Silver)' now points at the tier totals; in the 2026-10-23 workbook it referenced a Gaia-fit count cell (a bug in the 10-23 script; the CSVs and reports were unaffected).
- Workbook recalculation: LibreOffice is not installed; every Summary formula was evaluated by a small Python evaluator against the sheet values and compared with the Python counts (242 Summary formulas evaluated; 0 mismatches or errors). Excel will recalculate on open (fullCalcOnLoad).

## Time and tokens

- Part B close run: 35 agent runs (5 rows each), 175 rows; subagent usage as reported by the harness: 2.71M tokens (D01 362k, D02 371k, D03 375k, D04 399k, D05 395k, D06 387k, D07 420k), plus the coordinating session. Steps 2–4 used no LLM apart from the coordinator.
- Wall time: run started 2026-10-28 19:48 UTC; first D result written 2026-10-28 19:51, last 2026-10-28 20:45 UTC; package written 2026-10-28 20:49 UTC.

## What remains

- Browser queue: 150 rows on 79 domains (`browser-queue-2026-10-28.csv`), including the 40 JavaScript-only pages found today. `browser-sample-prompt-2026-10-28.md` has a sample.
- Round-2 gap sweeps (`docs/discovery/round2/`, separate session): health-facility registries, transport, hazards, food access outside the US, sub-national health outcomes.
- Robert's decisions (`decisions-needed-2026-10-28.md`): the two gaiaCatalog entries, the manuscript's '113 curated datasets' wording, the three PEDP mirrors without a licence; and the licence policy for US federal pages that state nothing (170 rows at fail).
- 25 close-queue rows not read (if any): same method, `partB/batches/D*.json`.
- Promotion of the Gold/Silver rows into the catalog pipeline; send the notes for Tim once read.
- Monthly re-run of `verify_links.py`.
