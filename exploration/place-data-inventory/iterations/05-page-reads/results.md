# Refine report: verified place-based data inventory (2026-10-23)

**This assumes:** the trimmed list of 2026-10-22 (570 kept rows) is the scope; part A results are the 2026-10-21 run plus the 2026-10-22 re-check; part B is an agent reading the landing page and at most one documentation page per dataset (no downloads, no bot-protection workarounds, no guessing: every confirmed value has an evidence URL); recency cut-off 2000 (Robert, 2026-10-22).

## Funnel

| Step | Datasets |
|---|---|
| Harvested | 3,337 |
| After de-duplication | 3,160 |
| Curated, or a lead with a stated unit | 1,018 |
| Kept after trimming | 570 |
| + mirrors / successors of withdrawn tools | 4 |
| Read for content (part B): 126 shortlist + 126 step-3 rows + 4 mirrors | 256 (41 blocked at the content step) |
| **Verified: Gold 19 + Silver 92** | **111** |

## Per-check results (all kept rows)

Part A (links, 2026-10-21/22):

| Check | pass | warn | fail | n.a. | not_checked |
|---|---|---|---|---|---|
| `chk_link_live` | 458 | 82 | 33 | 1 | 0 |
| `chk_redirect` | 545 | 0 | 0 | 27 | 2 |
| `chk_tls` | 544 | 0 | 9 | 19 | 2 |
| `chk_soft404` | 389 | 66 | 3 | 47 | 69 |
| `chk_withdrawn` | 400 | 0 | 1 | 47 | 126 |
| `chk_access_url` | 349 | 28 | 45 | 152 | 0 |
| `chk_format_match` | 150 | 185 | 3 | 236 | 0 |
| `chk_machine_metadata` | 91 | 209 | 158 | 47 | 69 |
| `chk_persistent_id` | 66 | 394 | 0 | 0 | 114 |
| `chk_archived` | 520 | 9 | 44 | 1 | 0 |

Part B (content, 2026-10-22):

| Check | pass | warn | fail | n.a. | not_checked |
|---|---|---|---|---|---|
| `chk_license` | 76 | 28 | 101 | 0 | 369 |
| `chk_temporal` | 135 | 52 | 0 | 0 | 387 |
| `chk_recency` | 156 | 27 | 4 | 0 | 387 |
| `chk_cadence` | 65 | 99 | 0 | 0 | 410 |
| `chk_version` | 110 | 60 | 0 | 0 | 404 |
| `chk_unit` | 157 | 30 | 0 | 0 | 387 |
| `chk_coverage` | 149 | 51 | 2 | 0 | 372 |
| `chk_access` | 142 | 30 | 13 | 0 | 389 |
| `chk_join_key` | 86 | 86 | 1 | 0 | 401 |
| `chk_format_gaia` | 80 | 93 | 7 | 0 | 394 |

Part C (workspace):

| Check | pass | warn | fail | n.a. | not_checked |
|---|---|---|---|---|---|
| `chk_in_gaia` | 35 | 0 | 0 | 539 | 0 |
| `chk_recipe_health` | 4 | 0 | 2 | 539 | 29 |

## Tiers

| Tier | Datasets | of which shortlist |
|---|---|---|
| Gold | 19 | 11 |
| Silver | 92 | 39 |
| Bronze | 301 | 60 |
| Browser needed | 130 | 48 |
| Failed | 32 | 14 |

## Gold and Silver by theme

| Theme | Gold | Silver | Total |
|---|---|---|---|
| built_environment | 3 | 2 | 5 |
| climate_hazard | 1 | 14 | 15 |
| demographics | 4 | 8 | 12 |
| environment | 6 | 37 | 43 |
| food_access | 0 | 1 | 1 |
| health_outcome | 2 | 9 | 11 |
| other | 1 | 0 | 1 |
| sdoh | 1 | 13 | 14 |
| toxics | 1 | 8 | 9 |

## Step 1: transient failures re-checked

24 kept rows with a 5xx, timeout, connection or DNS failure were re-run on 2026-10-22 (run `A-20261022T051300Z`). Recovered: 2 (global_gdl_area_database, global_gdl_shdi). Still failing: 9; still timing out or refusing the connection: 13.

| row | before | after | detail |
|---|---|---|---|
| br_datasus_transferencia_arquivos | warn | warn | connection: ('Connection aborted.', RemoteDisconnected('Remote end closed connec |
| de_bkg_vg250 | fail | fail | dns_failure: HTTPSConnectionPool(host='sg.geodatenzentrum.de', port=443): Max re |
| eu_elapse_lur_surfaces | warn | warn | timeout after retry (20 s x2) |
| fi_statfi_paavo | fail | fail | HTTP 502 |
| gaia_hh_rios_ana | warn | warn | timeout after retry (20 s x2) |
| gb_ons_census_2021_nomis | fail | fail | dns_failure: HTTPSConnectionPool(host='www.nomisweb.co.uk', port=443): Max retri |
| global_cru_ts | warn | warn | connection: ('Connection aborted.', RemoteDisconnected('Remote end closed connec |
| global_gdl_area_database | fail | pass | HTTP 200 |
| global_gdl_shdi | fail | pass | HTTP 200 |
| global_globio_grip | fail | fail | dns_failure: HTTPSConnectionPool(host='www.globio.info', port=443): Max retries  |
| global_sedac_human_modification | warn | warn | timeout after retry (20 s x2) |
| global_worldpop_population_100m | warn | warn | timeout after retry (20 s x2) |
| global_worldpop_population_1km | warn | warn | timeout after retry (20 s x2) |
| ie_pobal_hp_deprivation_index | warn | warn | timeout after retry (20 s x2) |
| pe_centrospoblados_inei | warn | fail | dns_failure: HTTPSConnectionPool(host='arcgis4.inei.gob.pe', port=6443): Max ret |
| pe_glaciares_ana | warn | warn | timeout after retry (20 s x2) |
| pe_idep_centros_poblados | fail | warn | timeout after retry (20 s x2) |
| pe_lagunas_ana | warn | warn | timeout after retry (20 s x2) |
| pt_ine_bgri | fail | fail | HTTP 502 |
| us_niehs_hhear | warn | warn | timeout after retry (20 s x2) |
| us_noaa_billion_dollar_disasters | fail | fail | HTTP 503 |
| us_noaa_climate_at_a_glance | fail | fail | HTTP 503 |
| us_sedac_di_pm25_1km_2000_2016 | warn | warn | timeout after retry (20 s x2) |
| us_walkscore | fail | fail | HTTP 503 |

TLS failures (9) were diagnosed with openssl against certifi 2026.10.19: `ke_knbs_census_2019` tls_incomplete_chain; `in_orgi_census_2011_pca` tls_incomplete_chain; `ug_ubos_nphc_2024` tls_incomplete_chain; `bd_bbs_census_2022` tls_invalid; `it_istat_basi_territoriali` tls_handshake_failure; `it_istat_ivsm` tls_handshake_failure; `pe_catastrominero_ingemmet` tls_incomplete_chain; `pe_midagri_catastro_rural` tls_incomplete_chain; `global_who_euro_health_information_gateway` tls_incomplete_chain. None bypassed; all are in the browser queue.

## Step 3: part B beyond the shortlist

Both step-3 groups were read: health relevance 3 with a count/distance step (points and lines, 52 rows) and health relevance 3 needing raster support (74 rows). The third group (health relevance 2, joins today) is empty: every such curated row is already on the shortlist. Rows dead or blocked after step 1 were not sent to agents.

## Mirrors added (step 4)

| new row | mirror of | page | tier |
|---|---|---|---|
| `us_epa_ejscreen_pedp` | us_epa_ejscreen | https://screening-tools.com/epa-ejscreen | Bronze |
| `us_ceq_cejst_pedp` | us_ceq_cejst | https://public-environmental-data-partners.github.io/j40-cejst-2/en/downloads | Bronze |
| `us_hifld_next_pedp` | us_hifld_hospitals; us_hifld_open_power_plants; us_hifld_open_natural_gas_pipelines | https://hifld.publicenvirodata.org | Bronze |
| `us_usgs_3dhp` | us_usgs_nhd | https://www.usgs.gov/3d-hydrography-program | Bronze |

HIFLD Open had no single trimmed row: the kept HIFLD rows already point at Data Rescue Project / DataLumos copies, so HIFLD Next was added as a catalog-level mirror. None of the four mirror pages states a licence, which keeps them below Gold.

## Browser queue

130 rows on 72 domains (`browser-queue-2026-10-23.csv`, grouped by domain). Largest: humdata.org (23), umich.edu (8), huduser.gov (7), gob.pe (6), arcgis.com (3), cms.gov (3).

## Choices made (decided without asking)

- TLS failures are classed `blocked` (browser queue, tier Browser needed), not `dead`, because six of nine are incomplete chains that browsers accept; two ISTAT hosts verify fine in openssl but refuse Python's handshake (recorded as `tls_handshake_failure`, a third label beyond the two asked for).
- The EJScreen mirror page quotes EPA's discontinuation notice; its `chk_withdrawn` was set to pass by hand (the mirror is live). No other hand overrides.
- A withdrawal notice found by part B (`withdrawn_notice_B`) is recorded but does not change `chk_withdrawn`; the agents applied it to `chk_recency` (fail = discontinued) as the brief asked.
- Silver requires that part B was actually run (at least one content check with a result); otherwise an unread row would be Silver by default. Unread rows are Bronze.
- `health_score` normalises over the applicable checks among the ten weighted ones; rows without part B score on link checks alone.
- Reference layers (ticket file 3) are kept rows with health relevance below 2 (or unknown), whatever their tier, as on 2026-10-22; Gold/Silver with relevance 2–3 go to file 1, Bronze/Browser needed to file 2, Failed to file 4.
- `public_access` comes from the confirmed access route when read, else from the listing: open_download/api = open; registration/api_key = registration; request/restricted = restricted.
- Recipe health (part C) is a hand map of twelve catalog folders to the deployment logs and readiness notes (in `scripts/refine_2026_10_23.py`, `RECIPE`); folders never exercised are `not_checked`.
- HIFLD Next's About page host did not resolve, so its licence, dates and coverage are unconfirmed; it is a catalog, not a dataset, and sits in Bronze/Browser depending on reachability.
- data.gov.ie leads were all trimmed on 2026-10-22, so the 47 data.gov.ie rows that were 500 on 2026-10-21 were not re-checked here.
- Workbook recalculation: LibreOffice is not installed; every Summary formula was evaluated by a small Python evaluator against the sheet values and compared with the Python counts (206 Summary formulas evaluated; 0 mismatches or errors). Excel will recalculate on open (fullCalcOnLoad).

## Usage and time

- Part B: 52 agent runs (5 rows each, 5 agents per batch of 25, batches run one after another), 256 rows read; agents reported about 75–90k tokens each, so roughly 4.3M tokens of subagent usage plus the coordinating session. No LLM was used in parts A and C.
- Wall time: first batch file written 2026-10-22 05:15, last result file written 2026-10-22 10:27 UTC (311 min), including step 1 (6 min scripted re-check), the mirror checks and the merges.
- Step 1 re-check and the mirror part-A run: scripted, about 6 minutes, no cost.

## What's left

- Part B on the remaining 318 kept rows: 89 blocked (browser queue), 28 dead, 200 live but outside the step-3 groups (health relevance 2 with an extra step, relevance 1 reference layers, unknown unit). Same method: 25 rows per batch, 5 agents.
- Browser queue: 130 rows for a person, grouped by domain.
- Licence for the four mirrors (ask PEDP / USGS, or read the Dataverse record in a browser).
- Promote the Gold/Silver rows into the catalog pipeline (metadata template → gaiaCatalog) and answer the notes for Tim.
- Monthly re-run of `verify_links.py`; it diffs against the previous run.
